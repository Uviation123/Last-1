import SwiftUI

struct StreakBadgeView: View {
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, isActive: currentStreak > 0)

                Text("\(currentStreak)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text("Current")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 50)

            VStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)

                Text("\(longestStreak)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text("Best")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    StreakBadgeView(currentStreak: 7, longestStreak: 21)
        .padding()
}
