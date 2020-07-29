//
//  DurationView.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 20.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import SwiftUI

struct DurationView: View {
    @ObservedObject var listViewModel: DurationsViewModel
    @State var showingList = false
    
    init(_ listViewModel: DurationsViewModel) {
        self.listViewModel = listViewModel
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(self.listViewModel.title)
            Spacer()
            Text(self.listViewModel.selectedValueTitle)
                .foregroundColor(.blue)
                .bold()
        }
        .padding(10)
        .actionSheet(isPresented: $showingList) {
            self.generateActionSheet(options: self.listViewModel.dataSource.compactMap{$0.duration})
        }
        .onTapGesture {
            self.showingList.toggle()
        }
    }
    
    private func generateActionSheet(options: [String]) -> ActionSheet {
        let buttons: [Alert.Button] = options.enumerated().map { index, option in
            Alert.Button.default(Text(option)) {
                self.listViewModel.selectedDuration = index
            }
        }
        return ActionSheet(title: Text(self.listViewModel.title),
                           buttons: buttons + [Alert.Button.cancel()])
    }
}

struct DurationView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
