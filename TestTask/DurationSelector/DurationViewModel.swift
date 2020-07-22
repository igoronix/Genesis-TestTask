//
//  DurationViewModel.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 20.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import Foundation

final class DurationViewModel: ObservableObject {
    @Published var duration: String
    @Published var interval: TimeInterval
    
    init(duration: Duration) {
        self.duration = duration.interval >= 0 ? duration.interval.stringFromTimeInterval() : "off"
        self.interval = duration.interval
    }
}
