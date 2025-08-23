//
//  AsyncTextAttachment.swift
//  Attachments
//
//  Created by Oliver Drobnik on 01/09/2016.
//  Copyright © 2016 Cocoanetics. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
import Nuke

public protocol AsyncTextAttachmentDelegate: AnyObject {
	/// Called when the image has been loaded
	func textAttachmentDidLoadImage(textAttachment: AsyncTextAttachment, displaySizeChanged: Bool)
}

/// An image text attachment that gets loaded from a remote URL
public class AsyncTextAttachment: NSTextAttachment, @unchecked Sendable {
        
	/// Remote URL for the image
//	public var imageURL: URL?
    public var attachmentUrl: URL?

	/// To specify an absolute display size.
	public var displaySize: CGSize?
	
	/// if determining the display size automatically this can be used to specify a maximum width. If it is not set then the text container's width will be used
	public var maximumDisplayWidth: CGFloat?

	/// A delegate to be informed of the finished download
	public weak var delegate: AsyncTextAttachmentDelegate?
	
	/// Remember the text container from delegate message, the current one gets updated after the download
	weak var textContainer: NSTextContainer?
	
	/// The download task to keep track of whether we are already downloading the image
	private var downloadTask: URLSessionDataTask!
	
	/// The size of the downloaded image. Used if we need to determine display size
	private var originalImageSize: CGSize?
    
    private var screenWidth: CGFloat?
    private var showPlaceholder: Bool
    
    public var postId: String?
	
	/// Designated initializer
//    public init(imageURL: URL, showPlaceholder: Bool = true, delegate: AsyncTextAttachmentDelegate? = nil) {
//        self.attachmentUrl = imageURL
//		self.delegate = delegate
//        self.showPlaceholder = showPlaceholder
//		
//		super.init(data: nil, ofType: nil)
//        
//        Task {
//            await MainActor.run {
//                screenWidth = UIScreen.main.bounds.width
//            }
//        }
//	}
    
    public init(image: UIImage, displaySize: CGSize? = nil) {
        self.showPlaceholder = false
        self.displaySize = displaySize
        
        super.init(data: nil, ofType: nil)
        
        self.image = image
        
        setScreenWidth()
    }
    
    public init(attachmentUrl: URL, showPlaceholder: Bool = true, delegate: AsyncTextAttachmentDelegate? = nil) {
        self.attachmentUrl = attachmentUrl
        self.showPlaceholder = showPlaceholder
        self.delegate = delegate
        
        super.init(data: nil, ofType: nil)
        
        setScreenWidth()
    }
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override public var image: UIImage? {
		didSet {
			originalImageSize = image?.size
		}
	}
	
	// MARK: - Helpers
    
    private func setScreenWidth() {
        sendableClosure {
            self.screenWidth = await UIScreen.main.bounds.width
        }
    }
    
    private func sendableClosure(_ closure: @Sendable @escaping () async -> Void) {
        Task { await closure() }
    }
    
//    private func loadImage(from url: URL) async -> Data? {
//        await withCheckedContinuation { continuation in
//            ImagePipeline.shared.loadImage(with: url) { result in
//                if case let .success(image) = result {
//                    continuation.resume(returning: image.image.imageData)
//                } else {
//                    continuation.resume(returning: nil)
//                }
//            }
//        }
//    }
    
    var isDownloading = false
    
    private func startAttachmentDownload(url: URL) async throws {
//        defer { isDownloading = false }
        guard !isDownloading else { return }
        isDownloading = true
//        let url = try! await apiClient.getAttachment(id: id)
//        let url = URL(string: "https://cs4a0d.4pda.ws/30526949/logo.png?s=00378e7459cfdd7967cc65ea00000000ae6372537e06c01c5b8747bf174cfa95")!
//        print("URL for \(id) is \(url)")
        let (data, _) = try await URLSession.shared.data(from: url)
        
        var displaySizeChanged = false
        
        contents = data
        fileType = UTType(filenameExtension: url.pathExtension)?.identifier
        
        if let image = UIImage(data: data) {
            if displaySize == nil {
                displaySizeChanged = true
            }
            originalImageSize = image.size
        } else {
            fatalError("Couldn't create attachment image")
        }
        
        sendableClosure { [weak self, displaySizeChanged] in
            guard let self else { return }
            showPlaceholder = false
            isDownloading = false
            // tell layout manager so that it should refresh
            if displaySizeChanged {
                textContainer?.layoutManager!.setNeedsLayout(forAttachment: self)
            } else {
                textContainer?.layoutManager!.setNeedsDisplay(forAttachment: self)
            }
            
            // notify the optional delegate
            await MainActor.run {
                delegate?.textAttachmentDidLoadImage(textAttachment: self, displaySizeChanged: displaySizeChanged)
            }
        }
        
//        imageURL = url
//        startAsyncImageDownload()
    }
	
//	private func startAsyncImageDownload() {
//        defer { downloadTask = nil }
//
//        guard let imageURL = attachmentUrl, contents == nil, downloadTask == nil else {
//			return
//		}
//		
//        downloadTask = URLSession.shared.dataTask(with: imageURL) { [unowned self] (data, response, error) in
//			
//			guard let data = data, error == nil else {
//				print(error?.localizedDescription as Any)
//				return
//			}
//			
//			var displaySizeChanged = false
//			
//			self.contents = data
//            self.fileType = UTType(filenameExtension: imageURL.pathExtension)?.identifier
//            
//            if let image = UIImage(data: data) {
//                let imageSize = image.size
//                
//                if displaySize == nil {
//                    displaySizeChanged = true
//                }
//                
//                self.originalImageSize = imageSize
//            }
//            
//            showPlaceholder = false
//            
//            Task { @MainActor in
//                // tell layout manager so that it should refresh
//                if displaySizeChanged {
//                    self.textContainer?.layoutManager?.setNeedsLayout(forAttachment: self)
//                } else {
//                    self.textContainer?.layoutManager?.setNeedsDisplay(forAttachment: self)
//                }
//                
//                // notify the optional delegate
//                self.delegate?.textAttachmentDidLoadImage(textAttachment: self, displaySizeChanged: displaySizeChanged)
//            }
//        }
//		
//		downloadTask.resume()
//	}

    public override func image(
        forBounds imageBounds: CGRect,
        textContainer: NSTextContainer?,
        characterIndex charIndex: Int
    ) -> UIImage? {
        if let image, !showPlaceholder {
            if let imageIdentifier = image.imageAsset?.value(forKey: "assetName") as? String {
                if image.isSymbolImage {
                    return image
                } else {
                    return UIImage(assetName: imageIdentifier)
                }
            } else {
                return image
            }
        }
		
		guard let contents, let image = UIImage(data: contents) else {
			// remember reference so that we can update it later
			self.textContainer = textContainer
			
            if let attachmentUrl {
                sendableClosure { [weak self] in
                    await self?.startDownload(url: attachmentUrl)
                }
            }
			
			return nil
		}
		
		return image
	}
    
    private func startDownload(url: URL) async {
        do {
            try await startAttachmentDownload(url: url)
        } catch {
             let font = UIFont.preferredFont(forTextStyle: .largeTitle)
             let config = UIImage.SymbolConfiguration(font: font)
             let image = UIImage(systemSymbol: .xCircleFill, withConfiguration: config)
                .withTintColor(UIColor(resource: .Main.red))
            
            contents = image.pngData()
            fileType = UTType.png.identifier
            
            var displaySizeChanged = false
            if displaySize == nil {
                displaySizeChanged = true
            }
            
            sendableClosure { [weak self, displaySizeChanged] in
                guard let self else { return }
                if displaySizeChanged {
                    textContainer?.layoutManager!.setNeedsLayout(forAttachment: self)
                } else {
                    textContainer?.layoutManager!.setNeedsDisplay(forAttachment: self)
                }
                
                delegate?.textAttachmentDidLoadImage(textAttachment: self, displaySizeChanged: displaySizeChanged)
            }
        }
    }

    public override func attachmentBounds(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFrag: CGRect,
        glyphPosition position: CGPoint,
        characterIndex charIndex: Int
    ) -> CGRect {
		if let displaySize {
			return CGRect(origin: .zero, size: displaySize)
		}
        
        guard let originalImageSize else {
            return .zero
        }
        
        // TODO: ScreenWidth is nil when opening post hat on non-first page
        if screenWidth == nil {
            screenWidth = 393 // Average
        }
        
        if originalImageSize.width > screenWidth! {
            let ratioWH = originalImageSize.width / (screenWidth! - 32) // TODO: 32 для боковых паддингов, в спойлерах нужно еще больше
            let width = originalImageSize.width / ratioWH
            let height = originalImageSize.height / ratioWH
            // print("Setting: \(width) \(height)")
            return CGRect(x: 0, y: 0, width: width, height: height)
        } else {
            let width = originalImageSize.width
            let height = originalImageSize.height
            return CGRect(x: 0, y: 0, width: width, height: height)
        }
	}
}
