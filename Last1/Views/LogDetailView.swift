import SwiftUI

struct LogDetailView: View {
    let log: DailyLog

    @Environment(AuthViewModel.self) var authVM
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var showDeleteError = false

    private let logRepo = DailyLogRepository()
    private let effortLabels = ["Light", "Medium", "Strong", "Intense", "Maximum"]

    var body: some View {
        ZStack {
            Color.appBackground(colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    header
                        .slideIn(delay: 0)

                    dateCard
                        .slideIn(delay: 0.05)

                    categoryCard
                        .slideIn(delay: 0.1)

                    if let note = log.note, !note.isEmpty {
                        noteCard(note: note)
                            .slideIn(delay: 0.15)
                    }

                    effortCard
                        .slideIn(delay: 0.2)

                    actionButtons
                        .slideIn(delay: 0.25)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showEditSheet) {
            AddLogView(logToEdit: log)
                .environment(authVM)
                .onDisappear { dismiss() }
        }
        .confirmationDialog(
            "Delete this log?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await performDelete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Couldn't Delete", isPresented: $showDeleteError) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "Something went wrong. Please try again.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Log Details")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
            }

            Spacer()

            Button { dismiss() } label: {
                ZStack {
                    Circle()
                        .fill(Color.appSurfaceSecondary(colorScheme))
                        .frame(width: 32, height: 32)

                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.appMutedText(colorScheme))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - Date Card

    private var dateCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appAccent(colorScheme).opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "calendar")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.appAccent(colorScheme))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Date")
                    .sectionLabel()

                Text(formattedDate)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
            }

            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Category Card

    private var categoryCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(log.category.chartColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: log.category.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(log.category.chartColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Category")
                    .sectionLabel()

                Text(log.category.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
            }

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .fill(log.category.chartColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(log.category.chartColor.opacity(0.4), lineWidth: 1)
                )
                .frame(width: 80, height: 28)
                .overlay(
                    Text(log.category.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(log.category.chartColor)
                )
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Note Card

    private func noteCard(note: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMutedText(colorScheme))

                Text("Note")
                    .sectionLabel()
            }

            Text(note)
                .font(.system(size: 15))
                .foregroundStyle(Color.appPrimaryText(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }

    // MARK: - Effort Card

    private var effortCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Effort Level")
                .sectionLabel()

            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { level in
                    VStack(spacing: 5) {
                        Text("\(level)")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(log.effortLevel == level
                                          ? Color.appAccent(colorScheme)
                                          : Color.appSurfaceSecondary(colorScheme))
                            )
                            .foregroundStyle(log.effortLevel == level
                                             ? Color.appButtonLabel(colorScheme)
                                             : Color.appPrimaryText(colorScheme))
                            .shadow(
                                color: log.effortLevel == level
                                    ? Color.appAccent(colorScheme).opacity(0.3) : .clear,
                                radius: 8
                            )

                        Text(effortLabels[level - 1])
                            .font(.system(size: 9))
                            .foregroundStyle(Color.appMutedText(colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                showEditSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Edit Log")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.appButtonLabel(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appAccent(colorScheme))
                        .shadow(color: Color.appAccent(colorScheme).opacity(0.3), radius: 12, y: 4)
                )
            }
            .buttonStyle(.plain)

            Button {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    if isDeleting {
                        ProgressView()
                            .tint(Color.red)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Delete Log")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.red.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let today = DateFormatting.todayString()
        let yesterday = DateFormatting.daysAgo(1)

        if log.date == today { return "Today" }
        if log.date == yesterday { return "Yesterday" }
        return DateFormatting.displayString(from: log.date)
    }

    private func performDelete() async {
        isDeleting = true
        do {
            try await logRepo.deleteLog(id: log.id)
            NotificationCenter.default.post(name: .didSaveLog, object: nil)
            dismiss()
        } catch {
            deleteError = error.localizedDescription
            showDeleteError = true
        }
        isDeleting = false
    }
}

#Preview {
    LogDetailView(log: DailyLog(
        id: UUID(),
        userId: UUID(),
        date: DateFormatting.todayString(),
        category: .fitness,
        effortLevel: 4,
        note: "Ran 5 miles in the morning and did a 30-minute strength session.",
        photoUrl: nil,
        createdAt: nil
    ))
    .environment(AuthViewModel())
}
