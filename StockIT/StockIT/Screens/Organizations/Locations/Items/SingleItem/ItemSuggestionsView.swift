import SwiftUI

struct ItemSuggestionsView: View {
    @ObservedObject var VM: SingleItemViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(VM.suggestions) { suggestion in
                    suggestionCard(suggestion)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("itemSuggestionsTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancelButton") {
                    VM.showSuggestions = false
                }
                .foregroundStyle(.fiitPrimary)
            }
        }
    }


    @ViewBuilder
    private func suggestionCard(_ suggestion: Suggestion) -> some View {
        VStack(spacing: 0) {
            suggestionImage(suggestion.imageURL)
            suggestionContent(suggestion)
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }


    @ViewBuilder
    private func suggestionImage(_ url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
            case .failure:
                ZStack {
                    Color(.systemGray5)
                    Image(systemName: "photo.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 200)
            case .empty:
                ZStack {
                    Color(.systemGray5)
                    ProgressView()
                }
                .frame(height: 200)
            @unknown default:
                EmptyView()
            }
        }
    }


    @ViewBuilder
    private func suggestionContent(_ suggestion: Suggestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow(suggestion)
            descriptionRow(suggestion.description)

            if !suggestion.suggestedCategoryNames.isEmpty {
                categoriesSection(suggestion.suggestedCategoryNames)
            }

            Divider()

            buttonsSection(suggestion)
        }
        .padding(16)
    }


    @ViewBuilder
    private func headerRow(_ suggestion: Suggestion) -> some View {
        HStack {
            Text(suggestion.name)
                .font(.headline)
                .foregroundStyle(.forText)

            Spacer()

            matchBadge(suggestion.percentage)
        }
    }

    @ViewBuilder
    private func matchBadge(_ percentage: Double) -> some View {
        (Text(String(format: "%.0f%% ", percentage)) + Text("matchLabel"))
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(colorForPercentage(percentage), in: Capsule())
    }


    @ViewBuilder
    private func descriptionRow(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }


    @ViewBuilder
    private func categoriesSection(_ names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("categoriesTitle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 6) {
                ForEach(names, id: \.self) { name in
                    Text(name)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.fiitPrimary.opacity(0.1), in: Capsule())
                        .foregroundStyle(.fiitPrimary)
                }
            }
        }
    }


    @ViewBuilder
    private func buttonsSection(_ suggestion: Suggestion) -> some View {
        HStack(spacing: 8) {
            actionButton(icon: "text.cursor", title: "Name") {
                VM.name = suggestion.name
                VM.showSuggestions = false
            }

            actionButton(icon: "text.alignleft", title: "Desc") {
                VM.description = suggestion.description
                VM.showSuggestions = false
            }

            if !suggestion.suggestedCategoryNames.isEmpty {
                actionButton(icon: "tag", title: "Cat") {
                    applySuggestedCategories(suggestion.suggestedCategoryNames)
                    VM.showSuggestions = false
                }
            }
        }

        useAllButton(suggestion)
    }

    @ViewBuilder
    private func useAllButton(_ suggestion: Suggestion) -> some View {
        Button {
            VM.name = suggestion.name
            VM.description = suggestion.description
            if !suggestion.suggestedCategoryNames.isEmpty {
                applySuggestedCategories(suggestion.suggestedCategoryNames)
            }
            VM.showSuggestions = false
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                Text("useAllButton")
                    .font(.subheadline.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [Color.fiitPrimary, Color.fiitPrimary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .shadow(color: Color.fiitPrimary.opacity(0.3), radius: 6, y: 3)
        }
    }


    private func applySuggestedCategories(_ categoryNames: [String]) {
        for name in categoryNames {
            if let match = VM.availableCategories.first(where: { $0.name.lowercased() == name.lowercased() }) {
                if !VM.selectedCategories.contains(where: { $0.id == match.id }) {
                    VM.selectedCategories.append(match)
                }
            }
        }
    }

    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(LocalizedStringKey(title))
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.fiitPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.fiitPrimary)
        }
    }

    func colorForPercentage(_ percent: Double) -> Color {
        switch percent {
        case 90...: return .green
        case 75..<90: return .yellow
        case 50..<75: return .orange
        default: return .red
        }
    }
}
