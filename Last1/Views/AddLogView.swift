import SwiftUI
import PhotosUI

struct AddLogView: View {
    @Environment(AuthViewModel.self) var authVM
    @State private var viewModel = AddLogViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var noteFocused = false
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    // Sheet drag handle area + header
                    pageHeader
                        .slideIn(delay: 0)

                    noteCard
                        .slideIn(delay: 0.1)

                    categoryCard
                        .slideIn(delay: 0.2)

                    effortCard
                        .slideIn(delay: 0.3)

                    photoCard
                        .slideIn(delay: 0.4)

                    saveButton
                        .slideIn(delay: 0.45)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .onChange(of: viewModel.selectedPhotoItem) {
            Task { await viewModel.loadPhoto() }
        }
        .onChange(of: viewModel.isSaved) {
            if viewModel.isSaved { dismiss() }
        }
        .onChange(of: viewModel.errorMessage) {
            if viewModel.errorMessage != nil { showErrorAlert = true }
        }
        .alert("Couldn't Save", isPresented: $showErrorAlert) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong. Please try again.")
        }
        .overlay {
            if viewModel.alreadyLoggedToday {
                alreadyLoggedOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.alreadyLoggedToday)
    }

    // MARK: - Already Logged Overlay

    private var alreadyLoggedOverlay: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.15))
                            .frame(width: 88, height: 88)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.appPrimary)
                    }

                    VStack(spacing: 12) {
                        Text("You showed up today.")
                            .font(.system(size: 26, weight: .bold))
                            .tracking(-0.5)
                            .foregroundStyle(Color.appForeground)
                            .multilineTextAlignment(.center)

                        Text("That's all it takes.")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.appPrimary)
                            .multilineTextAlignment(.center)

                        Text("See you tomorrow.")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.appMuted)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.05, green: 0.2, blue: 0.12))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.appPrimary)
                                .shadow(color: Color.appPrimary.opacity(0.3), radius: 12, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Header

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Log Your 1%")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(Color.appForeground)

                Text("What did you improve today?")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appMuted)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.appSecondary)
                        .frame(width: 32, height: 32)

                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.appMuted)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - Note Card

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Note")
                .sectionLabel()

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                noteFocused ? Color.appPrimary.opacity(0.5) : .clear,
                                lineWidth: 2
                            )
                    )

                if viewModel.note.isEmpty && !noteFocused {
                    Text("I worked on...")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appMuted)
                        .padding(12)
                }

                TextEditor(text: $viewModel.note)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appForeground)
                    .frame(minHeight: 80)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .onTapGesture { noteFocused = true }
            }
            .frame(minHeight: 90)
            .animation(.easeInOut(duration: 0.2), value: noteFocused)
        }
        .padding(16)
        .glassCard()
        .onTapGesture {
            noteFocused = true
        }
    }

    // MARK: - Category Card

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .sectionLabel()

            let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(LogCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            viewModel.selectedCategory = category
                        }
                    } label: {
                        let isSelected = viewModel.selectedCategory == category
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(category.chartColor.opacity(isSelected ? 0.25 : 0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    category.chartColor.opacity(isSelected ? 1.0 : 0.3),
                                    lineWidth: 1.5
                                )
                        )
                        .foregroundStyle(category.chartColor.opacity(isSelected ? 1.0 : 0.7))
                        .shadow(
                            color: isSelected ? category.chartColor.opacity(0.3) : .clear,
                            radius: 6
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Effort Level Card

    private let effortLabels = ["Light", "Medium", "Strong", "Intense", "Maximum"]

    private var effortCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Effort Level")
                .sectionLabel()

            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            viewModel.effortLevel = Double(level)
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Text("\(level)")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(viewModel.effortInt == level
                                              ? Color.appPrimary
                                              : Color.appSecondary)
                                )
                                .foregroundStyle(viewModel.effortInt == level
                                                 ? Color(red: 0.05, green: 0.2, blue: 0.12)
                                                 : Color.appForeground)
                                .shadow(
                                    color: viewModel.effortInt == level
                                        ? Color.appPrimary.opacity(0.3) : .clear,
                                    radius: 8
                                )
                                .scaleEffect(viewModel.effortInt == level ? 1.08 : 1.0)

                            Text(effortLabels[level - 1])
                                .font(.system(size: 9))
                                .foregroundStyle(Color.appMuted)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Photo Card

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo (Optional)")
                .sectionLabel()

            if let data = viewModel.selectedImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            PhotosPicker(
                selection: $viewModel.selectedPhotoItem,
                matching: .images
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16))
                    Text(viewModel.selectedImageData == nil ? "Add a photo" : "Change photo")
                        .font(.system(size: 14))
                }
                .foregroundStyle(Color.appMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.appBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .background(Color.appSecondary.opacity(0.5).clipShape(RoundedRectangle(cornerRadius: 12)))
                )
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            noteFocused = false
            Task {
                if let userId = authVM.currentUserId {
                    await viewModel.saveLog(userId: userId)
                } else {
                    viewModel.errorMessage = "You must be signed in to save a log."
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(red: 0.05, green: 0.2, blue: 0.12))
                } else {
                    Text("Save My 1%")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.05, green: 0.2, blue: 0.12))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appPrimary)
                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 12, y: 4)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }
}

#Preview {
    AddLogView()
        .environment(AuthViewModel())
}
