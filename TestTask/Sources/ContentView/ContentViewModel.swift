//
//  ContentViewModel.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 20.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import Foundation
import Combine

final class ContentViewModel: ObservableObject {
    @Published private(set) var playDurationVM: DurationsViewModel
    @Published private(set) var recDurationVM: DurationsViewModel
    @Published private(set) var changeStateButtonTitle = ""
    @Published private(set) var audioManager = AudioStateManager(audioFileUrl: ContentViewModel.audioFileURL, recFileUrl: ContentViewModel.recFileURL)
    
    private var cancellables = Set<AnyCancellable>()
    private var lastState: AudioManagerState = .idle
    
    init() {
        let playVM = DurationsViewModel()
        
        playVM.title = "Sound Timer"
        playVM.dataSource = [
            DurationViewModel(duration: -1),
            DurationViewModel(duration: 60),
            DurationViewModel(duration: 300),
            DurationViewModel(duration: 600),
            DurationViewModel(duration: 900),
            DurationViewModel(duration: 1200)
        ]
        playVM.selectedDuration = 2
        playDurationVM = playVM
        
        let recVM = DurationsViewModel()
        recVM.title = "Recording Duration"
        recVM.dataSource = [
            DurationViewModel(duration: -1),
            DurationViewModel(duration: 300),
            DurationViewModel(duration: 3600),
            DurationViewModel(duration: 2*3600),
            DurationViewModel(duration: 3*3600),
            DurationViewModel(duration: 4*3600),
            DurationViewModel(duration: 5*3600),
        ]
        recVM.selectedDuration = 1
        recDurationVM = recVM
        
        audioManager.objectWillChange
            .sink { _ in
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                    self.changeStateButtonTitle = self.nextStateButtonTitle()
                    self.lastState = self.audioManager.state
                }
        }
        .store(in: &cancellables)
        
        changeStateButtonTitle = nextStateButtonTitle()
    }
    
    func toggleState() {        
        audioManager.playInterval = playDurationVM.dataSource[playDurationVM.selectedDuration!].interval
        audioManager.recInterval = recDurationVM.dataSource[recDurationVM.selectedDuration!].interval
        audioManager.toggleState()
    }
    
    // MARK: - Private
    
    //TODO: Should be refactored
    
    private class var audioFileURL: URL {
        URL(fileURLWithPath: Bundle.main.path(forResource: "nature", ofType: "m4a")!)
    }
    
    private class var recFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first!.appendingPathComponent("record_\(Date().description).m4a")
    }
    
    
    private func nextStateButtonTitle() -> String {
        let newState: AudioManagerState
        switch audioManager.state {
        case .idle:
            newState = .play
        case .play, .rec:
            newState = .pause
        case .pause:
            switch lastState {
            case .play:
                newState = .play
            case .rec:
                newState = .rec
            default:
                newState = .idle
            }
        }
        return newState.rawValue
    }
}
