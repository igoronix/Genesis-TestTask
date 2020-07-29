//
//  AudioManager.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 21.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import AVFoundation
import Combine

enum AudioManagerState: String {
    case idle, play, rec, pause
}

protocol AudioManagerProtocol: AnyObject {
    var publisher: AnyPublisher<AudioManagerState, Error> { get }
    
    init(audioFileUrl: URL, recFileUrl: URL)
    func play()
    func rec()
    func pause()
    func stop()
}

final class AudioManager {
    private lazy var recSettings: [String : Any] = {
        [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
         AVSampleRateKey: 44100,
         AVNumberOfChannelsKey: 2,
         AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    }()
    
    private enum AudioManagerError: Error {
        case notRetrieveAudioFile
        case notEnoughPermissions
    }
    
    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    
    private let audioFileUrl: URL
    private let recFileUrl: URL
    
    var publisher: AnyPublisher<AudioManagerState, Error>
    private var statePublisher: PassthroughSubject<AudioManagerState, Error>
    
    init(audioFileUrl: URL, recFileUrl: URL) {
        self.audioFileUrl = audioFileUrl
        self.recFileUrl = recFileUrl
        
        statePublisher = PassthroughSubject<AudioManagerState, Error>()
        publisher = statePublisher.eraseToAnyPublisher()
    }
    
    private func initPlayer(_ completion: @escaping (Result<Void, Error>) -> Void) {
        guard let data = try? Data(contentsOf: audioFileUrl) else {
            completion(.failure(AudioManagerError.notRetrieveAudioFile))
            return
        }
        
        initAudioSession(.playback) { [weak self] result in
            if case .failure(let error) = result {
                completion(.failure(error))
                return
            }
            
            do {
                let audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer.prepareToPlay()
                audioPlayer.numberOfLoops = -1
                self?.audioPlayer = audioPlayer
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func initRecording(_ completion: @escaping (Result<Void, Error>) -> Void) {
        initAudioSession(.record) { [weak self] result in
            if case .failure(let error) = result {
                completion(.failure(error))
                return
            }
            
            guard let self = self else {
                return
            }
            
            do {
                let recorder = try AVAudioRecorder(url: self.recFileUrl, settings: self.recSettings)
                recorder.prepareToRecord()
                self.audioRecorder = recorder
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func initAudioSession(_ category: AVAudioSession.Category, completion: @escaping (Result<AVAudioSession, Error>) -> Void) {
        let dispatchQueue = DispatchQueue.global(qos: .default)
        dispatchQueue.async {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(category)
                session.requestRecordPermission() { allowed in
                    guard allowed else {
                        completion(.failure(AudioManagerError.notEnoughPermissions))
                        return
                    }
                    completion(.success(session))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - AudioManagerProtocol

extension AudioManager: AudioManagerProtocol {
    func play() {
        func turnOnPlaying() {
            NSLog("+- AudioManager PLAY")
            try? AVAudioSession.sharedInstance().setActive(true)
            audioPlayer?.play()
            statePublisher.send(.play)
        }
        
        guard audioPlayer == nil else {
            turnOnPlaying()
            return
        }
        
        initPlayer() { [weak self] result in
            if case .failure(let error) = result {
                NSLog("+- AudioManager turn On playing failed: \(error)")
                self?.statePublisher.send(completion: Subscribers.Completion.failure(error))
            } else {
                turnOnPlaying()
            }
        }
    }
    
    func rec() {
        func turnOnRecording() {
            NSLog("+- AudioManager REC")
            try? AVAudioSession.sharedInstance().setActive(true)
            audioRecorder?.record()
            statePublisher.send(.rec)
        }
        
        guard audioRecorder == nil else {
            turnOnRecording()
            return
        }
        
        initRecording { [weak self] result in
            if case .failure(let error) = result {
                NSLog("+- AudioManager turn On recoding failed: \(error)")
                self?.statePublisher.send(completion: Subscribers.Completion.failure(error))
            } else {
                turnOnRecording()
            }
        }
    }
    
    func pause() {
        NSLog("+- AudioManager Pause")
        
        audioPlayer?.pause()
        audioRecorder?.pause()
        statePublisher.send(.pause)
    }
    
    func stop() {
        NSLog("+- AudioManager Stop")
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        audioRecorder?.stop()
        audioRecorder = nil
        
        statePublisher.send(.idle)
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
