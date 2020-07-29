//
//  ContentView.swift
//  TestTask
//
//  Created by Igor Dorogokuplia on 20.07.2020.
//  Copyright © 2020 Igor D. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer(minLength: 200)
            Text(self.viewModel.audioManager.state.rawValue)
                .bold()
                .font(Font.system(size: 24))
            Spacer()
        
            Divider()
            DurationView(self.viewModel.playDurationVM)
            Divider()
            DurationView(self.viewModel.recDurationVM)
            Divider()
            
            Button(action: {
                self.viewModel.toggleState()
            }){
                Text(viewModel.changeStateButtonTitle)
                    .foregroundColor(.white)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
            }
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

