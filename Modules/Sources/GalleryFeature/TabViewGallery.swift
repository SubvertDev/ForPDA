//
//  TabViewGallery.swift
//  ArticleFeature
//
//  Created by Виталий Канин on 19.02.2025.
//

import APIClient
import ComposableArchitecture
import Models
import Nuke
import NukeUI
import SFSafeSymbols
import SharedUI
import SwiftUI

// MARK: - TabViewGallery

public struct TabViewGallery: View {
    
    // MARK: - Properties
    
    @State var gallery: [URL]
    let ids: [Int]?
    @Environment(\.dismiss) private var dismiss
    @State var selectedImageID: Int
    @State private var backgroundOpacity = 1.0
    @State private var isZooming = false
    @State private var isTouched = true
    @State private var showShareSheet = false
    @State private var activityItems: [Any] = []
    @State private var tempFileUrls: [Int: URL] = [:]
    
    // MARK: - Init
    
    public init(
        gallery: [URL],
        ids: [Int]? = nil,
        selectedImageID: Int
    ) {
        self.gallery = gallery
        self.ids = ids
        self.selectedImageID = selectedImageID
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            if isTouched {
                withAnimation(.easeInOut) {
                    VStack {
                        ToolBarView()
                            .background(.clear)
                        
                        Spacer()
                    }
                    .frame(alignment: .top)
                    .opacity(backgroundOpacity)
                    .zIndex(1)
                }
            }
            
            VStack {
                CustomScrollView(
                    imageElement: gallery,
                    selectedIndex: $selectedImageID,
                    isZooming: $isZooming,
                    isTouched: $isTouched,
                    backgroundOpacity: $backgroundOpacity,
                    onClose: { dismiss() }
                )
                .clipShape(.rect)
            }
            .ignoresSafeArea()
        }
        .statusBarHidden(!isTouched)
        .animation(.easeInOut, value: !isTouched)
        .onAppear {
            deleteTempFiles()
            preloadImage()
            loadFullImages()
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
                dismiss()
            }

            Spacer()
            
            Text(gallery.count == 1 ? String("") : String(String(selectedImageID + 1) + "/" + String(gallery.count)))
                .foregroundStyle(.white.opacity(backgroundOpacity))
                .font(.headline.weight(.semibold))
            
            Spacer()
            
            Menu {
                ContextButton(text: LocalizedStringResource("Save", bundle: .module), symbol: .arrowDownToLine) {
                    saveImage()
                }
                
                ContextButton(text: LocalizedStringResource("Share", bundle: .module), symbol: .squareAndArrowUp) {
                    configureShareSheet()
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
        let request = ImageRequest(url: gallery[selectedImageID])
        
        ImagePipeline.shared.loadImage(with: request) { result in
            switch result {
            case .success(let response):
                let image = response.image
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func configureShareSheet() {
        if let fileURL = tempFileUrls[selectedImageID] {
            activityItems = [fileURL]
            showShareSheet = true
        } else {
            print("File Not Found for ID: \(selectedImageID)")
        }
    }
    
    private func preloadImage() {
        for element in gallery.enumerated() {
            let imageUrl = gallery[element.offset]
            let request = ImageRequest(url: imageUrl)
            ImagePipeline.shared.loadImage(with: request) { result in
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
    
    
    private func loadFullImages() {
        guard let ids else { return }
        let mainId = ids[selectedImageID]
        Task {
            @Dependency(\.apiClient) var api
            let url = try await api.getAttachment(id: mainId)
            gallery[selectedImageID] = url
            
            for (index, id) in ids.enumerated() where id != mainId {
                let url = try await api.getAttachment(id: id)
                gallery[index] = url
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
                .foregroundStyle(foregroundStyle())
                .scaleEffect(isLiquidGlass ? 1 : 0.8)
                .background {
                    if !isLiquidGlass {
                        Circle()
                            .fill(.ultraThinMaterial.opacity(backgroundOpacity))
                            .frame(width: 32, height: 32)
                    }
                }
                .highPriorityGesture(
                    TapGesture().onEnded {
                        dismiss()
                    }
                )
        }
        .frame(
            width: isLiquidGlass ? 44 : 32,
            height: isLiquidGlass ? 44 : 32
        )
        .contentShape(Rectangle())
        .liquidIfAvailable(isInteractive: true)
    }
    
    @available(iOS, deprecated: 26.0)
    func foregroundStyle() -> AnyShapeStyle {
        if isLiquidGlass {
            return AnyShapeStyle(.foreground)
        } else {
            return AnyShapeStyle(.white)
        }
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    @Binding var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
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
        URL(string: "https://i.4pda.ws/static/img/news/63/633610t.jpg")!,
        URL(string: "https://i.4pda.ws/static/img/news/63/633618t.jpg")!,
        URL(string: "https://i.4pda.ws/static/img/news/63/633610t.jpg")!
    ],
    selectedImageID: Int(0))
}
