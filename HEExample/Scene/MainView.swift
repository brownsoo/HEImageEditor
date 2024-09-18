//
//  MainView.swift
//  HEExample
//
//  Created by hyonsoo on 9/18/24.
//

import Foundation
import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    private var data = Array(0...20)
    private var columns = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    @Query(sort: \MyItem.createDate, order: .reverse)
    private var allAlbums: [MyItem]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10, content: {
                    ForEach(data, id: \.self) { item in
                        Text(String(item))
                            .frame(height: 150, alignment: .center)
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .font(.title)
                    }
                })
                .padding(.horizontal)
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
