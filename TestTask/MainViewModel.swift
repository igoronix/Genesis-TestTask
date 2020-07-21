//
//  MainViewModel.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 20.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import Foundation

extension MainViewModel {
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
}

final class MainViewModel: ObservableObject {
    @Published private(set) var playDurationVM: DurationsViewModel
    @Published private(set) var recDurationVM: DurationsViewModel
    @Published private(set) var state = State.idle
    @Published private(set) var changeStateButtonTitle = ""
    
    private var previous_state = State.idle
    
    init() {
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
        
        let nextState = nextStateButtonTitle()
        changeStateButtonTitle = nextState.verbTitle
    }
    
    func nextStateButtonTitle() -> State {
        let newState: State
        switch state {
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
                newState = state
            }
        }
        return newState
    }
    
    func toggleState() {
        let newState = nextStateButtonTitle()
        previous_state = state
        state = newState
        
        let nextState = nextStateButtonTitle()
        changeStateButtonTitle = nextState.verbTitle
    }
}
