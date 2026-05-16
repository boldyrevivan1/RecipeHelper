//
//  CookingBannerView.swift
//  RecipeHelper
//
//  Mini pill at the bottom of the screen (above tab bar).
//  Swipe down to dismiss. Tap to open session.
//

import SwiftUI

struct CookingBannerView: View {
    @ObservedObject var manager = CookingSessionManager.shared
    var body: some View {
        if !manager.sessions.isEmpty {
            VStack(spacing: 4) {
                ForEach(manager.sessions) { session in
                    SessionPill(session: session)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: manager.sessions.count)
        }
    }
}

// MARK: - Single Pill

private struct SessionPill: View {
    let session: ActiveCookingSession
    @ObservedObject var manager = CookingSessionManager.shared

    var body: some View {
        HStack(spacing: 10) {
            // Mini timer ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: session.progress)
                    .stroke(Color.white,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: session.progress)
            }
            .frame(width: 24, height: 24)

            // Title + time
            VStack(alignment: .leading, spacing: 1) {
                Text(session.recipeTitle)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(session.isFinished ? "⏰ Ready!" : session.timeString)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .monospacedDigit()
            }

            Spacer()

            // Play / Pause
            Button {
                session.isRunning
                    ? manager.pauseTimer(for: session.id)
                    : manager.startTimer(for: session.id)
            } label: {
                Image(systemName: session.isRunning ? "pause.fill" : "play.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }

            // Open session
            Button {
                manager.selectedSessionId = session.id
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
            }

            // Stop
            Button {
                withAnimation { manager.removeSession(session.id) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(session.isFinished ? Color.green : Color.orange)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        )
    }
}
