//
//  CheckBoxToggleStyle.swift
//  ForPDA
//
//  Created by Xialtal on 7.04.26.
//

import SwiftUI

public struct CheckBoxToggleStyle: ToggleStyle {
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button(action: {
                configuration.isOn.toggle()
            }, label: {
                if !configuration.isOn {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.Separator.secondary), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .frame(width: 22, height: 22)
                        .overlay {
                            Image(systemSymbol: .checkmark)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(.white))
                        }
                }
            })
            
            configuration.label
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isEnabled = false
    VStack {
        Toggle(isOn: $isEnabled) {
            Text(verbatim: "Show mark")
                .font(.subheadline)
                .foregroundStyle(Color(.Labels.secondary))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(CheckBoxToggleStyle())
        .padding(6)
    }
    .padding(15)
    .environment(\.tintColor, Color(.Theme.primary))
}
