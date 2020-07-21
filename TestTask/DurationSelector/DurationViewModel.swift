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
    
    init(duration: Duration) {
        self.duration = duration.interval >= 0 ? duration.interval.stringFromTimeInterval() : "off"
    }
}
