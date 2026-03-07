//
//  RefreshStateLine.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 05.03.2026.
//

import SwiftUI

@available(iOS 17, *)
struct RefreshStateLine: View {
    let state: SlackListRefreshState
    
    @State private var outcomeOpacity = 1.0
    @State private var morphProgress = 0.0
    @State private var frozenPhase = 0.0
    
    private let cycleDuration = 0.9
    
    var body: some View {
        if state != .idle {
            TimelineView(.animation) { timeline in
                GeometryReader { geometry in
                    let phase = state == .loading
                        ? phase(at: timeline.date.timeIntervalSinceReferenceDate)
                        : frozenPhase
                    let loadingMetrics = loadingMetrics(
                        phase: phase,
                        containerWidth: geometry.size.width
                    )
                    let lineWidth = loadingMetrics.width + ((geometry.size.width - loadingMetrics.width) * morphProgress)
                    let lineX = loadingMetrics.x * (1 - morphProgress)
                    
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: lineWidth, height: 2)
                        .offset(x: lineX)
                        .opacity(outcomeOpacity)
                }
            }
            .frame(height: 2)
            .clipped()
            .onAppear {
                handleStateChange(state)
            }
            .onChange(of: state) { _, newValue in
                handleStateChange(newValue)
            }
        }
    }
    
    private var lineColor: Color {
        switch state {
        case .idle, .loading:
            .blue
        case .loaded:
            .green
        case .error:
            .red
        }
    }
    
    private func handleStateChange(_ newState: SlackListRefreshState) {
        switch newState {
        case .idle:
            morphProgress = 0
            outcomeOpacity = 1
        case .loading:
            morphProgress = 0
            outcomeOpacity = 1
        case .loaded, .error:
            frozenPhase = phase(at: Date().timeIntervalSinceReferenceDate)
            morphProgress = 0
            outcomeOpacity = 1
            withAnimation(.easeInOut(duration: 0.35)) {
                morphProgress = 1
            }
            withAnimation(.easeOut(duration: 2).delay(0.25)) {
                outcomeOpacity = 0
            }
        }
    }
    
    private func phase(at time: TimeInterval) -> Double {
        (time.truncatingRemainder(dividingBy: cycleDuration)) / cycleDuration
    }
    
    private func loadingMetrics(phase: Double, containerWidth: CGFloat) -> (width: CGFloat, x: CGFloat) {
        let easedPhase = 0.5 - (cos(.pi * phase) * 0.5)
        let minWidth = max(containerWidth * 0.08, 18)
        let maxWidth = max(containerWidth * 0.3, 44)
        let widthFactor = sin(.pi * phase)
        let segmentWidth = minWidth + ((maxWidth - minWidth) * widthFactor)
        let travelDistance = containerWidth + segmentWidth
        let x = (travelDistance * easedPhase) - segmentWidth
        
        return (segmentWidth, x)
    }
}
