import SwiftUI

struct MomentumMeterView: View {
    let percentage: Double
    @Environment(\.colorScheme) private var colorScheme

    private var trimEnd: Double {
        min(max(percentage, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appSurfaceSecondary(colorScheme), lineWidth: 12)

            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.appAccent(colorScheme).opacity(0.6), Color.appAccent(colorScheme)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: trimEnd)

            VStack(spacing: 4) {
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))

                Text("Momentum")
                    .font(.caption)
                    .foregroundStyle(Color.appMutedText(colorScheme))
            }
        }
    }
}

#Preview {
    MomentumMeterView(percentage: 0.65)
        .frame(width: 150, height: 150)
        .padding()
}
