import SwiftUI

struct ChipSelectionGrid<Item: Identifiable & Hashable>: View {
    let items: [Item]
    let selectedItems: Set<Item>
    let title: (Item) -> String
    let onToggle: (Item) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(chunked(items, size: 2), id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { item in
                        Button {
                            onToggle(item)
                        } label: {
                            Text(title(item))
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .foregroundStyle(selectedItems.contains(item) ? .white : LumenColors.textSecondary)
                                .background(
                                    selectedItems.contains(item)
                                    ? AnyShapeStyle(LinearGradient.primaryGradient)
                                    : AnyShapeStyle(Color.white.opacity(0.08))
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    if row.count == 1 {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func chunked(_ source: [Item], size: Int) -> [[Item]] {
        guard size > 0 else { return [] }
        var chunks: [[Item]] = []
        var index = 0
        while index < source.count {
            let end = min(index + size, source.count)
            chunks.append(Array(source[index..<end]))
            index += size
        }
        return chunks
    }
}
