import SwiftUI

// MARK: - Global Presentation Layer
struct GlobalPresentationLayer: View {
    @EnvironmentObject var noticeCenter: NoticeCenter

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            if noticeCenter.showCellularNotice {
                CellularBanner(dismiss: { noticeCenter.dismissCellularNotice() })
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
                    .padding(.top, 8)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: noticeCenter.showCellularNotice)
    }
}

// MARK: - Cellular Banner (non-modal, non-blocking)
private struct CellularBanner: View {
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundColor(.yellow)
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("Cellular Connection Detected")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("AI video analysis may be slow and use mobile data. For faster results, connect to Wi‑Fi.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(action: dismiss) {
                Text("Got it")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.65))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
        .padding(.horizontal, 12)
        .allowsHitTesting(true) // Only the banner intercepts taps; rest of UI stays interactive
    }
}
