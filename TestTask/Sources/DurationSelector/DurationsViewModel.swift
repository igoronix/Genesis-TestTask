//
//  RecordingDurationViewModel.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 20.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import Foundation

final class DurationsViewModel: ObservableObject, Identifiable  {
    @Published var dataSource: [DurationViewModel] = []
    @Published var title: String = ""
    @Published var selectedDuration: Int?
    
    var selectedValueTitle: String {
        guard let index = selectedDuration else {
            return ""
        }
        return dataSource[index].duration
    }
}
