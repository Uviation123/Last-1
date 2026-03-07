import SwiftUI

struct CategoryChipView: View {
    let category: LogCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.subheadline)

                Text(category.displayName)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                category.chartColor.opacity(isSelected ? 0.2 : 0.08),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        category.chartColor.opacity(isSelected ? 1.0 : 0.35),
                        lineWidth: 1.5
                    )
            )
            .foregroundStyle(category.chartColor.opacity(isSelected ? 1.0 : 0.7))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        CategoryChipView(category: .fitness, isSelected: true) {}
        CategoryChipView(category: .learning, isSelected: false) {}
    }
    .padding()
}
