//
//  ColorPickerView.swift
//  ForPDA
//
//  Created by Xialtal on 1.01.26.
//

import SwiftUI

struct ColorPickerView: UIViewControllerRepresentable {
    private let delegate: ColorPickerDelegate
    
    init(onColorSelected: @escaping (Color) -> Void) {
        self.delegate = ColorPickerDelegate(onColorSelected: { color in
            onColorSelected(color)
        })
    }
    
    func makeUIViewController(context: Context ) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.title = String(localized: "Colors", bundle: .module)
        picker.selectedColor = .clear
        picker.supportsAlpha = false
        picker.delegate = delegate
        
        if #available(iOS 26.0, *) {
            picker.supportsEyedropper = false
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIColorPickerViewController, context: Context) {
    }
    
    private class ColorPickerDelegate: NSObject, UIColorPickerViewControllerDelegate {
        let onColorSelected: (Color) -> Void
        
        public init(onColorSelected: @escaping (Color) -> Void) {
            self.onColorSelected = onColorSelected
        }
        
        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            if !continuously {
                onColorSelected(Color(uiColor: viewController.selectedColor))
            }
        }
    }
}
