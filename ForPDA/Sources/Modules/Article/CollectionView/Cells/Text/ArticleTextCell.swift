//
//  ArticleHeaderCell.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import UIKit
import Factory
import SwiftRichString

final class ArticleTextCell: UICollectionViewCell {
    
    // MARK: - Views
    
    private let quoteLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        return view
    }()
    
    private var textView = PDAResizingTextView()
    
    // MARK: - Properties
    
    @LazyInjected(\.analyticsService) private var analytics
    private var text = ""
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Functions
    
    func configure(model: ArticleTextCellModel) {        
        text = model.text
        filterFromTags()
        
        // (todo) remove fatalerror after some testing?
        guard !text.isEmpty else { fatalError("text can't be empty inside text cell") }
        
        if model.inList {
            checkForList(index: model.countedListIndex)
        }
        
        repairHrefs()
        
        configureTextView()
        
        configureQuote(model.isQuote)

        if model.isHeader {
            configureHeader()
        }
        
        textView.snp.updateConstraints { make in
            make.top.equalToSuperview().inset(model.isHeader ? 16 : 0)
        }
    }
    
    // MARK: - Private Functions
    
    private func filterFromTags() {
        let tags = [
            ("<!--more-->", ""),
            ("<br>", ""),
            ("&nbsp;", " "),
            ("<span></span>", "")
        ]
        
        for tag in tags where text.contains(tag.0) {
            text = text.replacingOccurrences(of: tag.0, with: tag.1)
        }
        
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func checkForList(index: Int) {
        text = "• \(text)"
        if index > 0 { text = "\(index). \(text)" }
    }
    
    private func repairHrefs() {
        let ranges = text.indicesOf(string: "href=\"//") // this text was pointing to original text (test)
        for range in ranges.reversed() {
            text.insert(contentsOf: "https:", at: text.index(text.startIndex, offsetBy: range + 6))
        }
    }
    
    private func configureTextView() {
        let baseStyle = Style {
            $0.font = SystemFonts.HelveticaNeue.font(size: 17)
            $0.hyphenationFactor = 1
            $0.alignment = .justified
        }
        
        // Temporary workaround for failed parsing
        if text.contains("<") && !text.contains(">") {
            text = text.replacingOccurrences(of: "<", with: "&#60;")
        } else if !text.contains("<") && text.contains(">") {
            text = text.replacingOccurrences(of: ".", with: "&#62;")
        }
        
        let style = StyleXML(base: baseStyle, [:])
        let attrText = text.set(style: style)
        textView.myDelegate = self
        let insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        textView.textContainerInset = insets
        textView.attributedText = attrText
        textView.textColor = .label
    }
    
    private func configureQuote(_ isQuote: Bool) {
        textView.snp.updateConstraints { make in
            make.left.equalTo(quoteLine.snp.right).offset(isQuote ? 8 : 0)
        }
        
        quoteLine.snp.updateConstraints { make in
            make.width.equalTo(isQuote ? 5 : 0)
        }
    }
    
    private func configureHeader() {
        let baseStyle = Style {
            $0.font = SystemFonts.HelveticaNeue_Medium.font(size: 20)
            $0.hyphenationFactor = 1
        }
        let style = StyleXML(base: baseStyle, [:])
        let attrText = text.set(style: style)
        textView.attributedText = attrText
        textView.textColor = .label
    }
    
}

// MARK: - UITextViewDelegate

extension ArticleTextCell: PDAResizingTextViewDelegate {
    
    func willOpenURL(_ url: URL) {
        analytics.event(Event.Article.articleLinkClicked.rawValue)
    }
    
}

// MARK: - Layout

extension ArticleTextCell {
    
    private func addSubviews() {
        contentView.addSubview(quoteLine)
        contentView.addSubview(textView)
    }
    
    private func makeConstraints() {
        quoteLine.snp.makeConstraints { make in
            make.verticalEdges.left.equalToSuperview()
            make.width.equalTo(0)
        }
        
        textView.snp.makeConstraints { make in
            make.verticalEdges.right.equalToSuperview()
            make.left.equalTo(quoteLine.snp.right)
        }
    }
    
}
