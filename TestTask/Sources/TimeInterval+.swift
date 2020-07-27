//
//  TimeInterval+.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 20.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import Foundation

extension TimeInterval {
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        
        var formatString = ""
        if hours == 0 {
            if (minutes < 10) {
                formatString = "%2d:%0.2d"
            } else {
                formatString = "%0.2d:%0.2d"
            }
            return String(format: formatString, minutes, seconds)
        } else {
            formatString = "%2d:%0.2d:%0.2d"
            return String(format: formatString, hours, minutes, seconds)
        }
    }
}
