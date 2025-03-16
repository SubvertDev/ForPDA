//
//  BBBuilderTests.swift
//  ForPDATests
//
//  Created by Ilia Lubianoi on 12.03.2025.
//

import Testing
import UIKit
import Models
import SharedUI
import BBBuilder

struct BBBuilderTests {
    
    // MARK: - Texts

    @Test func singleText() async throws {
        let text = "test"
        let nodes = BBBuilder.build(text: text)
        #expect(nodes == [.text(text.withAttributes(BBRenderer.defaultAttributes))])
    }
    
    @Test func singleTextWithNewlinesTrimmedFromBothSides() async throws {
        let text = "\ntest\n"
        let nodes = BBBuilder.build(text: text)
        let expectedText = text.trimmingCharacters(in: .newlines)
        #expect(nodes == [.text(expectedText.withAttributes(BBRenderer.defaultAttributes))])
    }
    
    @Test func singleTextBeforeNonTextIsTrimmedLeadingOnly() async throws {
        let text = "\ntest[spoiler][/spoiler]"
        let nodes = BBBuilder.build(text: text)
        let expectedText = "test"
        #expect(nodes == [
            .text(expectedText.withAttributes(BBRenderer.defaultAttributes)),
            .spoiler(nil, [])
        ])
    }
    
    @Test func singleTextAfterNonTextIsTrimmedBothSides() async throws {
        let text = "[spoiler][/spoiler]\ntest\n"
        let nodes = BBBuilder.build(text: text)
        let expectedText = "test"
        #expect(nodes == [
            .spoiler(nil, []),
            .text(expectedText.withAttributes(BBRenderer.defaultAttributes))
        ])
    }
    
    @Test func singleTextBeforeFileAttachmentIsNotTrimmedTrailing() async throws {
        let id = 0
        let prefixTextWithTrailingNewline = "text\n"
        let text = prefixTextWithTrailingNewline + String.fileAttachment(id: id)
        let nodes = BBBuilder.build(text: text, attachments: [.file(id: id)])
        if case let .text(text) = nodes.first, nodes.count == 1 {
            #expect(text.string.prefix(prefixTextWithTrailingNewline.count) == prefixTextWithTrailingNewline)
        } else {
            Issue.record("First node is not text or there's more nodes")
        }
    }
    
    @Test func singleTextBeforeImageAttachmentIsNotTrimmedTrailing() async throws {
        let id = 0
        let prefixTextWithTrailingNewline = "text\n\n"
        let text = prefixTextWithTrailingNewline + String.imageAttachment(id: id)
        let nodes = BBBuilder.build(text: text, attachments: [.image(id: id)])
        if case let .text(text) = nodes.first, nodes.count == 1 {
            #expect(text.string.prefix(prefixTextWithTrailingNewline.count) == prefixTextWithTrailingNewline)
        } else {
            Issue.record("First node is not text or there's more nodes")
        }
    }
    
    // MARK: - Lists
    
    @Test func missedNewlinesAreHandledInList() async throws {
        let text = "[list][*]test1[*]test2[/list]"
        let nodes = BBBuilder.build(text: text, attachments: [])
        #expect(nodes == [
            .list(.bullet, [
                .text("• test1\n• test2".withAttributes(BBRenderer.defaultAttributes))
            ])
        ])
    }
    
    // MARK: - Image Attachments
    
    @Test func singleImageAttachment() async throws {
        let id = 0
        let text = String.imageAttachment(id: id)
        let nodes = BBBuilder.build(text: text, attachments: [.image(id: id)])
        let imageAttachmentAttribute = "\"\(Post.Attachment.image(id: id).id):\(Post.Attachment.image(id: 0).name)\""
        #expect(nodes == [.attachment(imageAttachmentAttribute.asAttributed())])
    }
    
    @Test func doubleImageAttachments() async throws {
        let firstId = 0
        let secondId = 1
        let text = String.imageAttachment(id: firstId) + String.imageAttachment(id: secondId)
        let nodes = BBBuilder.build(text: text, attachments: [.image(id: firstId), .image(id: secondId)])
        let firstImageAttachmentAttribute = "\"\(Post.Attachment.image(id: firstId).id):\(Post.Attachment.image(id: firstId).name)\""
        let secondImageAttachmentAttribute = "\"\(Post.Attachment.image(id: secondId).id):\(Post.Attachment.image(id: secondId).name)\""
        #expect(nodes == [
            .attachment(firstImageAttachmentAttribute.asAttributed()),
            .attachment(secondImageAttachmentAttribute.asAttributed())
        ])
    }
    
    @Test func doubleImageAttachmentsSeparatedBySpace() async throws {
        let firstId = 0
        let secondId = 1
        let text = String.imageAttachment(id: firstId) + " " + String.imageAttachment(id: secondId)
        let nodes = BBBuilder.build(text: text, attachments: [.image(id: firstId), .image(id: secondId)])
        let firstImageAttachmentAttribute = "\"\(Post.Attachment.image(id: firstId).id):\(Post.Attachment.image(id: firstId).name)\""
        let secondImageAttachmentAttribute = "\"\(Post.Attachment.image(id: secondId).id):\(Post.Attachment.image(id: secondId).name)\""
        #expect(nodes == [
            .attachment(firstImageAttachmentAttribute.asAttributed()),
            .attachment(secondImageAttachmentAttribute.asAttributed())
        ])
    }
    
    @Test func inlineImageAttachment() async throws {
        let id = 0
        let text = "inline" + String.imageAttachment(id: id) + "attachment"
        let nodes = BBBuilder.build(text: text, attachments: [.image(id: id)])
        if case let .text(text) = nodes.first {
            #expect(nodes == [.text(text)])
        } else {
            Issue.record("Node is not text")
        }
    }
    
    @Test func imageAttachmentBeforeNewlineTextIsNotInlineAndTextIsTrimmedLeading() async throws {
        let id = 0
        let text = String.imageAttachment(id: id) + "\nText"
        let nodes = BBBuilder.build(text: text, attachments: [.image(id: id)])
        #expect(nodes == [
            .attachment(.imageAttachmentAttribute(id: id)),
            .text("Text".withAttributes(BBRenderer.defaultAttributes))
        ])
    }
    
    @Test func imageAttachmentAfterNewlineInsideSpoiler() async throws {
        let id = 0
        let text = "[spoiler]\n\n" + String.imageAttachment(id: id) + "[/spoiler]"
        let nodes = BBBuilder.build(text: text, attachments: [.image(id: id)])
        if case let .spoiler(spoilerAttributes, spoilerNodes) = nodes.first {
            if case .attachment = spoilerNodes.first {
                #expect(nodes == [
                    .spoiler(spoilerAttributes, [
                        .attachment(.imageAttachmentAttribute(id: 0))
                    ])
                ])
            } else {
                Issue.record("First inner node is not attachment")
            }
        } else {
            Issue.record("First outer node is not spoiler")
        }
    }
    
    @Test func imageAttachmentAfterNewline() async throws {
        let id = 0
        let text = "Test\n" + String.imageAttachment(id: id) + "\n\n"
        let nodes = BBBuilder.build(text: text, attachments: [.image(id: id)])
        if case let .text(text) = nodes.first, nodes.count == 1 {
            #expect(nodes == [.text(text)])
        } else {
            Issue.record("First node is not text or there's more nodes")
        }
    }
    
    @Test func imageAttachmentAfterWhitespaceWithInlineImageAttachmentBefore() async throws {
        let firstId = 0
        let secondId = 1
        let text = "Test\n\n" + String.imageAttachment(id: firstId) + " " + String.imageAttachment(id: secondId)
        let nodes = BBBuilder.build(text: text, attachments: [.image(id: firstId), .image(id: secondId)])
        if case let .text(text) = nodes.first, nodes.count == 1 {
            #expect(nodes == [.text(text)])
        } else {
            Issue.record("First node is not text or there's more nodes")
        }
    }
    
    @Test func noAttachmentIsConvertedToText() async throws {
        let id = 0
        let text = String.imageAttachment(id: id)
        let nodes = BBBuilder.build(text: text)
        if case let .text(text) = nodes.first, nodes.count == 1 {
            #expect(nodes == [.text(text)])
        } else {
            Issue.record("First node is not text or there's more nodes")
        }
    }
    
    // MARK: - File Attachments
    
    @Test func fileAttachmentAfterText() async throws {
        let id = 0
        let text = "Test" + String.fileAttachment(id: id)
        let nodes = BBBuilder.build(text: text, attachments: [.file(id: id)])
        if case let .text(text) = nodes.first, nodes.count == 1 {
            #expect(nodes == [.text(text)])
        } else {
            Issue.record("First node is not text or there's more nodes")
        }
    }
    
    @Test func fileAttachmentAfterTextWithNewlineNotTrimmed() async throws {
        let id = 0
        let prefixTextWithNewline = "Test\n"
        let text = prefixTextWithNewline + String.fileAttachment(id: id)
        let nodes = BBBuilder.build(text: text, attachments: [.file(id: id)])
        if case let .text(text) = nodes.first, nodes.count == 1 {
            // #expect(nodes == [.text(text)]) // Too cumbersome to do right
            #expect(text.string.prefix(prefixTextWithNewline.count) == prefixTextWithNewline)
        } else {
            Issue.record("First node is not text or there's more nodes")
        }
    }
}

// MARK: - Helpers

private extension Post.Attachment {
    static func image(id: Int) -> Post.Attachment {
        return Post.Attachment(
            id: id, type: .image, name: "name.jpg", size: 0,
            metadata: Post.Attachment.Metadata(
                width: 32, height: 32, url: URL(string: "https://4pda.to/s/Zy0hEHci0VoolKcVH289BigH8f5BA5xRz0kvtrjCPBWYZz2rtz1.png")!
            ),
            downloadCount: nil
        )
    }
    
    static func file(id: Int) -> Post.Attachment {
        return Post.Attachment(id: id, type: .file, name: "name.zip", size: 0, metadata: nil, downloadCount: 69)
    }
}

private extension String {
    static func imageAttachment(id: Int) -> String {
        return "[attachment=\"\(Post.Attachment.image(id: id).id):\(Post.Attachment.image(id: id).name)\"]"
    }

    static func fileAttachment(id: Int) -> String {
        return "[attachment=\"\(Post.Attachment.file(id: id).id):\(Post.Attachment.file(id: id).name)\"]"
    }
}

private extension NSAttributedString {
    static func imageAttachmentAttribute(id: Int) -> NSAttributedString {
        return NSAttributedString(string: "\"\(Post.Attachment.image(id: id).id):\(Post.Attachment.image(id: id).name)\"")
    }
    
    static func fileAttachmentAttribute(id: Int) -> NSAttributedString {
        return NSAttributedString(string: "\"\(Post.Attachment.file(id: id).id):\(Post.Attachment.file(id: id).name)\"")
    }
}

private extension String {
    func withAttributes(_ attributes: [NSAttributedString.Key : Any]) -> NSAttributedString {
        return NSAttributedString(string: self, attributes: attributes)
    }
}

private extension String {
    func asAttributed(attributes: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString {
        return NSAttributedString(string: self, attributes: attributes)
    }
}
