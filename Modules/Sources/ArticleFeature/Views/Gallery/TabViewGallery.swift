//
//  TabViewGallery.swift
//  ArticleFeature
//
//  Created by Виталий Канин on 19.02.2025.
//

import SwiftUI
import Models
import Nuke
import NukeUI
import SFSafeSymbols
import SharedUI

// MARK: - TabViewGallery

struct TabViewGallery: View {
    
    var gallery: [ImageElement]
    @Binding var showScreenGallery: Bool
    @Binding var selectedImageID: Int
    @State private var backgroundOpacity: Double = 1.0
    @State private var isZooming: Bool = false
    @State private var isTouched: Bool = true
    @State private var showShareSheet: Bool = false
    @State private var activityItems: [Any] = []
    @State private var tempFileUrls: [Int: URL] = [:]
    
    var body: some View {
        ZStack {
            if isTouched {
                withAnimation(.easeInOut) {
                    VStack {
                        ToolBarView()
                            .background(Color.clear)
                        Spacer()
                    }
                    .frame(alignment: .top)
                    .opacity(backgroundOpacity)
                    .zIndex(1)
                }
            }
            
            VStack {
                CustomScrollView(imageElement: gallery,
                                 selectedIndex: $selectedImageID,
                                 isZooming: $isZooming,
                                 isTouched: $isTouched,
                                 backgroundOpacity: $backgroundOpacity, onClose: {
                    showScreenGallery = false
                })
                .clipShape(.rect)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            preloadImage(for: gallery)
        }
        .onDisappear {
            deleteTempFiles()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: $activityItems)
                .presentationDetents([.medium])
        }
        .presentationBackgroundClear()
    }
    
    // MARK: - ToolBarView
    
    @ViewBuilder
    private func ToolBarView() -> some View {
        HStack {
            ToolbarButton(placement: .topBarLeading, symbol: .xmark) {
                showScreenGallery.toggle()
            }

            Spacer()
            
            Text(gallery.count == 1 ? "" : "\(selectedImageID + 1) / \(gallery.count)")
                .foregroundStyle(.white.opacity(backgroundOpacity))
                .font(.headline.weight(.semibold))
            
            Spacer()
            
            Menu {
                ContextButton(text: "Save", symbol: .arrowDownToLine, bundle: .module) {
                    saveImage()
                }
                
                ContextButton(text: "Share", symbol: .squareAndArrowUp, bundle: .module) {
                    shareSheet()
                }
                
            } label: {
                ToolbarButton(placement: .topBarTrailing, symbol: .ellipsis, action: {})
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private func saveImage() {
        let request = ImageRequest(url: gallery[selectedImageID].url)
        
        Nuke.ImagePipeline.shared.loadImage(with: request) { result in
            switch result {
            case .success(let response):
                let image = response.image
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func shareSheet() {
        if let fileURL = tempFileUrls[selectedImageID] {
            activityItems = [fileURL]  // Передаем файл в ShareSheet
            showShareSheet = true  // Открываем окно
        } else {
            print("File Not Found for ID: \(selectedImageID)")
        }
    }
    
    private func preloadImage(for: [ImageElement]) {
        DispatchQueue.main.async {
            for element in gallery.enumerated() {
                let imageUrl = gallery[element.offset].url
                let request = ImageRequest(url: imageUrl)
                Nuke.ImagePipeline.shared.loadImage(with: request) { result in
                    switch result {
                    case .success(let response):
                        let tempFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("image\(element.offset + 1).jpg")
                        do {
                            if let imageData = response.image.jpegData(compressionQuality: 1.0) {
                                try imageData.write(to: tempFileUrl)
                                tempFileUrls[element.offset] = tempFileUrl
                            }
                        } catch {
                            print("Image not loaded: \(error)")
                        }
                    case .failure(let error):
                        print("Image not loaded: \(error)")
                    }
                }
            }
        }
    }
    
    private func deleteTempFiles() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error deleting temp files: \(error)")
        }
    }
    
    // MARK: - ToolbarButton
    
    private func ToolbarButton(
        placement: ToolbarItemPlacement,
        symbol: SFSymbol,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            Image(systemSymbol: symbol)
                .font(.body)
                .foregroundStyle(.white)
                .scaleEffect(0.8) // TODO: ?
                .background(
                    Circle()
                        .fill(.ultraThinMaterial.opacity(backgroundOpacity))  // Материал
                        .frame(width: 32, height: 32)
                )
                .highPriorityGesture(
                    TapGesture().onEnded {
                        showScreenGallery.toggle()
                    }
                )
        }
        .frame(width: 32, height: 32)
        .contentShape(Rectangle())
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    @Binding var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

        print(activityItems)

        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension View {
    func presentationBackgroundClear() -> some View {
        self.modifier(BackgroundView())
    }
}

struct BackgroundView: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationBackground(.clear)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    TabViewGallery(gallery: [
        .init(url: URL(string: "https://i.4pda.ws/static/img/news/63/633610t.jpg")!, width: 480, height: 269),
        .init(url: URL(string: "https://i.4pda.ws/static/img/news/63/633618t.jpg")!, width: 480, height: 269),
        .init(url: URL(string: "https://i.4pda.ws/static/img/news/63/633610t.jpg")!, width: 480, height: 269)
    ],
    showScreenGallery: .constant(false), selectedImageID: .constant(0))
}
