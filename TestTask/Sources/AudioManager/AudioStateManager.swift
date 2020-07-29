//
//  AudioStateManager.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 27.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import AVFoundation
import Combine

final class AudioStateManager: ObservableObject {
    private let audioManager: AudioManagerProtocol
    
    var playInterval: TimeInterval!
    var recInterval: TimeInterval!
    
    private var timer: DispatchSourceTimer?
    private var interruptionSubscription: AnyCancellable?
    
    @Published private(set) var state = AudioManagerState.idle {
        didSet {
            stateDidSet()
        }
    }
    
    private var bag = Set<AnyCancellable>()
    private var previousState: AudioManagerState = .idle
    
    init(audioFileUrl: URL, recFileUrl: URL) {
        audioManager = AudioManager(audioFileUrl: audioFileUrl, recFileUrl: recFileUrl)
        audioManager.publisher.receive(on: RunLoop.main)
            .sink(receiveCompletion: { error in
                NSLog("AudioStateManager publisher receiveCompletion: \(error)")
            }) { state in
                NSLog("AudioStateManager publisher state:\(state)")
                self.previousState = self.state
                self.state = state
        }
        .store(in: &bag)
    }
    
    deinit {
        bag.removeAll()
    }
    
    // MARK: - Public

    func toggleState() {
        switch state {
        case .idle:
            guard playInterval > 0 else {
                launchRec()
                return
            }
            launchPlay()
        case .play,
             .rec:
            audioManager.pause()
        case .pause:
            switch previousState {
            case .play:
                audioManager.play()
            case .rec:
                audioManager.rec()
            default:
                break
            }
        }
    }
    
    // MARK: - Private
    
    private func stateDidSet() {
        switch state {
        case .idle:
            timer?.cancel()
            timer = nil
            unsubscribe()
        case .play:
            subscribeForInteruption()
            timer?.resume()
        case .rec:
            subscribeForInteruption()
            timer?.resume()
        case .pause:
            unsubscribe()
            timer?.suspend()
        }
    }
    
    private func audioTimer(with interval: TimeInterval, completion: @escaping () -> Void) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + interval, repeating: .never)
        timer.setEventHandler {
            timer.setEventHandler(handler: nil)
            timer.cancel()
            self.timer = nil
            self.audioManager.stop()
            
            completion()
        }
        return timer
    }
    
    private func launchPlay() {
        timer = audioTimer(with: playInterval) {
            NSLog("AudioStateManager play timer is over")
            self.launchRec()
        }
        audioManager.play()
    }
    
    private func launchRec() {
        guard recInterval > 0 else {
            return
        }
        
        timer = audioTimer(with: recInterval) {
            NSLog("AudioStateManager rec timer is over")
        }
        audioManager.rec()
    }
    
    // MARK: - Interuption subscription
    
    private func unsubscribe() {
        NSLog("AudioStateManager Interuption unsubscribe")
        
        interruptionSubscription?.cancel()
        interruptionSubscription = nil
    }
    
    private func subscribeForInteruption() {
        NSLog("AudioStateManager subscribeForInteruption")
        interruptionSubscription = NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .sink() { notification in
                guard let info = notification.userInfo,
                    let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                    let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                        return
                }
                
                let options: AVAudioSession.InterruptionOptions?
                if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                    options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                } else {
                    options = nil
                }
                
                self.processInteruption(type, options: options)
        }
    }
    
    private func processInteruption(_ type: AVAudioSession.InterruptionType, options: AVAudioSession.InterruptionOptions?) {
        NSLog("AudioStateManager processInteruption type:\(type)")
        
        let session = AVAudioSession.sharedInstance()
        switch type {
        case .began:
            try? session.setActive(false)
            pause()
        case .ended:
            guard !(options?.contains(.shouldResume) ?? false) else {
                print("AudioStateManager AudioSession shoudln't resume")
                break
            }
            if previousState == .play {
                try? session.setCategory(.playback)
                try? session.setActive(true)
                audioManager.play()
            } else if previousState == .rec {
                try? session.setActive(true)
                try? session.setCategory(.record)
                audioManager.rec()
            }
        default:
            break
        }
    }
}

