//
//  MainViewModel.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 20.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import Foundation
import Combine

final class MainViewModel: NSObject, ObservableObject {
    @Published private(set) var playDurationVM: DurationsViewModel
    @Published private(set) var recDurationVM: DurationsViewModel
    @Published private(set) var changeStateButtonTitle = ""
    @Published private(set) var audioManager = AudioManager()
    
    private var cancellables = Set<AnyCancellable>()
    private var previous_state = AudioManager.State.idle
    
    override init() {
        let playVM = DurationsViewModel()
        
        playVM.title = "Sound Timer"
        playVM.dataSource = [
            DurationViewModel(duration: Duration(interval: -1)),
            DurationViewModel(duration: Duration(interval: 60)),
            DurationViewModel(duration: Duration(interval: 300)),
            DurationViewModel(duration: Duration(interval: 600)),
            DurationViewModel(duration: Duration(interval: 900)),
            DurationViewModel(duration: Duration(interval: 1200))
        ]
        playVM.selectedDuration = 2
        self.playDurationVM = playVM
        
        let recVM = DurationsViewModel()
        recVM.title = "Recording Duration"
        recVM.dataSource = [
            DurationViewModel(duration: Duration(interval: -1)),
            DurationViewModel(duration: Duration(interval: 300)),
            DurationViewModel(duration: Duration(interval: 3600)),
            DurationViewModel(duration: Duration(interval: 2*3600)),
            DurationViewModel(duration: Duration(interval: 3*3600)),
            DurationViewModel(duration: Duration(interval: 4*3600)),
            DurationViewModel(duration: Duration(interval: 5*3600)),
        ]
        recVM.selectedDuration = 1
        self.recDurationVM = recVM
        
        super.init()
        
        audioManager.objectWillChange
            .sink { _ in
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                    let nextState = self.nextStateButtonTitle()
                    self.changeStateButtonTitle = nextState.verbTitle
                }
        }
        .store(in: &cancellables)
        
        let nextState = nextStateButtonTitle()
        changeStateButtonTitle = nextState.verbTitle
    }
    
    private func nextStateButtonTitle() -> AudioManager.State {
        let newState: AudioManager.State
        switch audioManager.state {
        case .idle:
            newState = .playing
        case .playing:
            newState = .paused
        case .recording:
            newState = .paused
        case .paused:
            switch previous_state {
            case .playing:
                newState = .playing
            case .recording:
                newState = .recording
            default:
                newState = audioManager.state
            }
        }
        return newState
    }
    
    func toggleState() {
        previous_state = audioManager.state
        
        audioManager.playInterval = playDurationVM.dataSource[playDurationVM.selectedDuration!].interval
        audioManager.recInterval = recDurationVM.dataSource[recDurationVM.selectedDuration!].interval
        audioManager.toggleState()
    }
}
