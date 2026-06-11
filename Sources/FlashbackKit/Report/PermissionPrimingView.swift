#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Screen-recording permission priming (pre-permission) sheet.
///
/// ReplayKit's permission system alert **can't be customized** (only the app display name can be
/// injected). So before the OS prompt appears, this sheet bridges the meaning to improve understanding
/// and the grant rate.
///
/// Presented as a `.sheet` with `.presentationDetents([.medium])` (over the dormant ReportView).
/// Color rule: the hero mark uses the **brand-logo palette** (ring/hand = label color, wedge = orange);
/// the filled CTA is the same orange, visually tying together the primary action.
/// Copy is variant A (neutral, explanatory). Avoids "bug/defect" wording.
struct PermissionPrimingView: View {
    /// "Proceed to allow": the caller sets `hasPrimed`, closes the sheet, and retries recording (OS prompt).
    let onProceed: () -> Void
    /// "Later": close the sheet and return to dormant (no toast).
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            // Hero: Time Slice mark in the brand-logo palette. The ring/hand use the label color
            // (black in light, white in dark), encircling the orange wedge so the outline stands out on any
            // background. The orange wedge conveys "slicing out a moment in time".
            TimeSliceMark.logo()
                .frame(width: 46, height: 46)
                .padding(.bottom, 16)

            Text("Turn screen recording on", bundle: .module)
                .font(.title3.weight(.bold))
                .foregroundStyle(FlashbackColor.label)
                .multilineTextAlignment(.center)

            Text("When you choose \"Allow\" on the next iOS prompt, your latest in-app activity is kept automatically.", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(FlashbackColor.secondaryLabel)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 9)
                .padding(.horizontal, 8)
                .frame(maxWidth: 280)

            Spacer(minLength: 16)

            // CTA: filled orange (the action that enables recording).
            Button(action: onProceed) {
                Text("Proceed to allow", bundle: .module)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FlashbackColor.onAction)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(FlashbackColor.action, in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel(Text("Proceed to allow", bundle: .module))
            .accessibilityHint(Text("iOS asks to confirm screen recording", bundle: .module))

            // "Later": muted text button.
            Button(action: onLater) {
                Text("Later", bundle: .module)
                    .font(.callout)
                    .foregroundStyle(FlashbackColor.secondaryLabel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
            }
            .padding(.top, 10)
            .accessibilityLabel(Text("Later", bundle: .module))

            // Hint that the next tap surfaces the OS prompt (mono, muted).
            HStack(spacing: 5) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                Text("Tap to launch the OS prompt", bundle: .module)
                    .font(FlashbackFont.mono)
            }
            .foregroundStyle(FlashbackColor.tertiaryLabel)
            .padding(.top, 12)
            .accessibilityHidden(true)

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(FlashbackColor.background)
    }
}

#if DEBUG
#Preview("Priming") {
    Color.gray.opacity(0.3)
        .sheet(isPresented: .constant(true)) {
            PermissionPrimingView(onProceed: {}, onLater: {})
                .presentationDetents([.medium])
        }
}
#endif
#endif
