//
//  SettingRowView.swift
//
//
//  Created by Ilia Lubianoi on 17.05.2024.
//

import SwiftUI
import SharedUI
import NukeUI
import SFSafeSymbols
import SkeletonUI

enum SettingType {
    case auth(URL?, String)
    case guest(Image)
    case image(Image)
    case symbol(SFSymbol)
}

struct SettingRowView: View {
    
    let title: LocalizedStringKey
    let type: SettingType
    let action: (() -> Void)
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Group {
                    switch type {
                    case .auth(let url, let name):
                        HStack {
                            LazyImage(url: url) { state in
                                Group {
                                    if let image = state.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color(.systemBackground)
                                    }
                                }
                                .skeleton(with: state.isLoading, shape: .circle)
                            }
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .clipShape(.circle)
                            .padding(8)
                            
                            VStack(alignment: .leading) {
                                Text(name)
                                Text("Open profile", bundle: .module)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Color(.label))
                            
                            Spacer()
                        }
                        
                    case .guest(let image):
                        HStack {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .clipShape(.circle)
                                .padding(8)
                            
                            VStack(alignment: .leading) {
                                Text("Guest", bundle: .module)
                                Text("Log in", bundle: .module)
                            }
                            .foregroundStyle(Color(.label))
                            
                            Spacer()
                        }
                        
                    case .image(let image):
                        HStack {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding(.leading, 16)
                            
                            Text(title, bundle: .module)
                                .foregroundStyle(Color(.label))
                            
                            Spacer()
                        }
                        
                    case .symbol(let symbol):
                        HStack {
                            Image(systemSymbol: symbol)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.gray)
                                .padding(.leading, 16)
                            
                            Text(title, bundle: .module)
                                .foregroundStyle(Color(.label))
                            
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
            .contentShape(.rect)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .buttonStyle(ListButtonStyle())
        .listRowInsets(EdgeInsets())
    }
}
