//
//  MainView.swift
//  HEExample
//
//  Created by hyonsoo on 9/18/24.
//

import Foundation
import SwiftUI


struct RootView: View {
    var body: some View {
        NavigationStack {
            MainView()
        }
    }
}


struct MainView: View {
    var body: some View {
        VStack {
            ScrollView {
                Text("renew")
            }
            
            HStack {
                Button(action: {}) {
                    Image(systemName: "plus")
                        .padding()
                        .background {
                            Circle().foregroundColor(Color(uiColor: .systemGray5))
                        }
                }
            }
            .frame(maxWidth: .infinity)
//            .frame(height: 54)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}


struct MainView_Preview: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
