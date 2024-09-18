//
//  MainView.swift
//  HEExample
//
//  Created by hyonsoo on 9/18/24.
//

import Foundation
import SwiftUI

struct MainView: View {
    var body: some View {
        VStack {
            ScrollView {
                Text("renew")
            }
            
            HStack {
                Button(action: {}) {
                    Image(systemName: "gear")
                        .padding()
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "plus")
                        .padding()
                        .background {
                            Rectangle().foregroundColor(Color(uiColor: .systemGray5))
                        }
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .padding()
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
