import SwiftUI

struct MomentumMeterView: View {
    let percentage: Double

    private var trimEnd: Double {
        min(max(percentage, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)

            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.blue, .purple, .pink]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: trimEnd)

            VStack(spacing: 4) {
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Momentum")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    MomentumMeterView(percentage: 0.65)
        .frame(width: 150, height: 150)
        .padding()
}
