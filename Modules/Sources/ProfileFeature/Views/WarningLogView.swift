//
//  WarningLogView.swift
//  ForPDA
//
//  Created by Xialtal on 24.03.26.
//

import SwiftUI
import Models
import BBBuilder
import SharedUI

struct WarningLogView: View {
    
    // MARK: - Properties
    
    @Environment(\.tintColor) private var tintColor
    
    private let warningLog: User.WarningLog
    private let deeplinkTapped: (URL) -> Void
    
    // MARK: - Init
    
    init(warningLog: User.WarningLog, deeplinkTapped: @escaping (URL) -> Void) {
        self.warningLog = warningLog
        self.deeplinkTapped = deeplinkTapped
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemSymbol: warningLog.levelSymbol)
                    .font(.body)
                    .foregroundStyle(warningLog.levelColor)
                
                Text(warningLog.levelTitle, bundle: .module)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(warningLog.levelColor)
            }
            
            if warningLog.canBeCanceled {
                Text("Undo available", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.teritary))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(
                        Color(.Background.teritary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    )
            }

            if let reason = warningLog.reasonAttributed {
                RichText(text: reason, onUrlTap: { url in
                    deeplinkTapped(url)
                })
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if warningLog.postId != 0 {
                let link = "https://4pda.to/forum/index.php?act=findpost&pid=\(warningLog.postId)"
                Text(LocalizedStringResource("[Go to Post](\(link))", bundle: .module))
                    .tint(tintColor)
                    .font(.subheadline)
                    .environment(\.openURL, OpenURLAction(handler: { url in
                        deeplinkTapped(url)
                        return .handled
                    }))
            }
            
            HStack {
                Text(formatDate(warningLog.createdAt))
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.caption)
                
                Spacer()
                
                if warningLog.authorId != 0 {
                    HStack(spacing: 4) {
                        let link = "https://4pda.to/forum/index.php?showuser=\(warningLog.authorId)"
                        Text(.init("[\(warningLog.authorName)](\(link))"))
                            .environment(\.openURL, OpenURLAction(handler: { url in
                                deeplinkTapped(url)
                                return .handled
                            }))
                        
                        Image(systemSymbol: .chevronRight)
                    }
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.quaternary))
                    .tint(Color(.Labels.quaternary))
                }
            }
            
            
        }
    }
    
    // MARK: - Format Date

    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy · HH:mm"
        return dateFormatter.string(from: date)
    }
}

// MARK: - Extensions

private extension User.WarningLog {
    var reasonAttributed: NSAttributedString? {
        guard !reason.isEmpty else { return nil }
        return BBRenderer(baseAttributes: [.font: UIFont.preferredFont(forTextStyle: .subheadline)])
            .render(text: reason)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        WarningLogView(
            warningLog: .mockAsModerator(level: .decreased),
            deeplinkTapped: { url in
                
            }
        )
    }
    .padding(16)
}
