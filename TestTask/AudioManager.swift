//
//  AudioManager.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 21.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import AVFoundation
import Combine

class AudioManager: ObservableObject {
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
    
    private var audioFilePath: String {
        Bundle.main.path(forResource: "nature", ofType: "m4a")!
    }
        
    private var recFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first!.appendingPathComponent("record_\(Date().description).m4a")
    }
    
    enum State: String {
        case idle, playing, recording, paused
        
        var verbTitle: String {
            switch self {
            case .idle:
                return ""
            case .playing:
                return "Play"
            case .recording:
                return "Record"
            case .paused:
                return "Pause"
            }
        }
    }
    
    @Published private(set) var state = State.idle
    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    
    var playInterval: TimeInterval!
    var recInterval: TimeInterval!
    
    func toggleState() {
        switch state {
        case .idle:
            startPlay()
        case .playing:
            pause()
        case .recording:
            pause()
        case .paused:
            if audioPlayer != nil {
                startPlay()
            } else {
                startRec()
            }
        }
    }
    
    private func pause() {
        switch state {
        case .playing:
            self.audioPlayer?.pause()
            self.timer?.suspend()
            self.state = .paused
        case .recording:
            self.audioRecorder?.pause()
            self.timer?.suspend()
            self.state = .paused
        default:
            break
        }
    }
    
    // MARK: - PLAY
    
    private func startPlay() {
        guard playInterval > 0 else {
            self.startRec()
            return
        }
        
        func turnOnPlaying() {
            NSLog("PLAY")
            self.state = .playing
            self.timer?.resume()
            self.audioPlayer?.play()
        }
        
        if audioPlayer == nil {
            initPlayer() { error in
                if error == nil {
                    turnOnPlaying()
                } else {
                    NSLog("turn On playing failed: \(String(describing: error))")
                }
            }
        } else {
            turnOnPlaying()
        }
    }
    
    private func initPlayer(_ completion: @escaping (Error?) -> Void) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: self.audioFilePath)) else {
            completion(AudioManagerError.notRetrieveAudioFile)
            return
        }

        initAudioSession(.playback) { (session, error) in
            guard error == nil else {
                completion(error)
                return
            }
            do {
                try session.setActive(true)
                let audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer.prepareToPlay()
                audioPlayer.numberOfLoops = -1
                
                let timer = Timer(timeInterval: self.playInterval)
                timer.eventHandler = {
                    NSLog("Playing Timer Fired")
                    self.audioPlayer?.stop()
                    self.audioPlayer = nil
                    self.timer = nil
                    
                    self.startRec()
                }
                
                self.audioPlayer = audioPlayer
                self.timer = timer
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    // MARK: - REC
    
    private func startRec() {
        guard recInterval > 0 else {
            return
        }
        
        func turnOnRecording() {
            NSLog("REC")
            self.state = .recording
            self.timer?.resume()
            self.audioRecorder?.record()
        }
        
        if audioRecorder == nil {
            initRecording { error in
                if error == nil {
                    turnOnRecording()
                } else {
                    NSLog("turn On recoding failed: \(String(describing: error))")
                }
            }
        } else {
            turnOnRecording()
        }
    }
    
    private func initRecording(_ completion: @escaping (Error?) -> Void) {
        initAudioSession(.record) { (session, error) in
            guard error == nil else {
                completion(error)
                return
            }
            do {
                self.audioRecorder = try AVAudioRecorder(url: self.recFileURL, settings: self.recSettings)
                self.audioRecorder?.prepareToRecord()
                try session.setActive(true)
                
                let timer = Timer(timeInterval: self.recInterval)
                timer.eventHandler = {
                    NSLog("Rec Timer Fired")
                    self.audioRecorder?.stop()
                    self.audioRecorder = nil
                    self.timer = nil
                    self.state = .idle
                    try? session.setActive(false)
                }
                self.timer = timer
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    // MARK: - Initialize AVAudioSession
    
    private func initAudioSession(_ category: AVAudioSession.Category, completion: @escaping (AVAudioSession, Error?) -> Void) {
        let dispatchQueue = DispatchQueue.global(qos: .default)
        dispatchQueue.async {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(category)
                session.requestRecordPermission() { allowed in
                    guard allowed else {
                        completion(session, AudioManagerError.notEnoughPermissions)
                        return
                    }
                    completion(session, nil)
                }
            } catch {
                completion(session, error)
            }
        }
    }
}
