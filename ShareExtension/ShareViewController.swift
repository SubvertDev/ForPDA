//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Subvert on 31.08.2023.
//

import UIKit
import Social
import CoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    private let typeText = String(UTType.text.identifier)
    private let typeURL = String(UTType.url.identifier)
    private var appURL = "forpda://article/"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        if itemProvider.hasItemConformingToTypeIdentifier(typeText) {
            handleIncomingText(itemProvider: itemProvider)
        } else if itemProvider.hasItemConformingToTypeIdentifier(typeURL) {
            handleIncomingURL(itemProvider: itemProvider)
        } else {
            print("Error: No url or text found")
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
    
    private func handleIncomingText(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: typeText, options: nil) { (item, error) in
            if let error = error { print("Text-Error: \(error.localizedDescription)") }
            
            if let text = item as? String {
                do {
                    let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                    let matches = detector.matches(
                        in: text,
                        options: [],
                        range: NSRange(location: 0, length: text.utf16.count)
                    )
                    
                    if let firstMatch = matches.first, let range = Range(firstMatch.range, in: text) {
                        self.appURL += text[range]
                    }
                } catch let error {
                    print("Do-Try Error: \(error.localizedDescription)")
                }
            }
            
            self.openMainApp()
        }
    }
    
    private func handleIncomingURL(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: typeURL, options: nil) { (item, error) in
            if let error = error { print("URL-Error: \(error.localizedDescription)") }
            
            if let url = item as? NSURL, let urlString = url.absoluteString {
                let stripped1 = urlString.replacingOccurrences(of: "https://4pda.to/", with: "")
                let components = stripped1.components(separatedBy: "/")
                var articleId = ""
                for (index, component) in components.enumerated() where index < 4 {
                    articleId += "\(component)/"
                }
                
                self.appURL += articleId
            }
            
            self.openMainApp()
        }
    }
    
    private func openMainApp() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: { _ in
            guard let url = URL(string: self.appURL) else { return }
            
            self.openURL(url)
        })
    }
    
    @discardableResult
    @objc private func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
}
