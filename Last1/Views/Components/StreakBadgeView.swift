import SwiftUI

struct StreakBadgeView: View {
    let currentStreak: Int
    let longestStreak: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, isActive: currentStreak > 0)

                Text("\(currentStreak)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))

                Text("Current")
                    .font(.caption)
                    .foregroundStyle(Color.appMutedText(colorScheme))
            }

            Divider()
                .frame(height: 50)
                .overlay(Color.appBorderDynamic(colorScheme))

            VStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)

                Text("\(longestStreak)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))

                Text("Best")
                    .font(.caption)
                    .foregroundStyle(Color.appMutedText(colorScheme))
            }
        }
        .padding()
        .background(Color.appSurface(colorScheme), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.appBorderDynamic(colorScheme).opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    StreakBadgeView(currentStreak: 7, longestStreak: 21)
        .padding()
}
