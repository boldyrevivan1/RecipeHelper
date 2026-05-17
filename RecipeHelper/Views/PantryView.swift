import SwiftUI

struct PantryView: View {
    @ObservedObject private var fs = FirestoreService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showAddSheet   = false
    @State private var newItemName    = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if fs.pantry.isEmpty {
                        ContentUnavailableView("No spices yet",
                            systemImage: "leaf",
                            description: Text("Tap + to add your first spice"))
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(fs.pantry) { item in
                            PantryRow(item: item)
                        }
                        .onDelete(perform: deleteCustom)
                    }
                } header: {
                    Text("Toggle what you always have at home. These ingredients count as available for any recipe and won't be deducted after cooking.")
                        .font(.footnote)
                        .textCase(nil)
                        .foregroundStyle(.secondary)
                } footer: {
                    let on = fs.pantry.filter { $0.isAvailable }.count
                    Text("\(on) of \(fs.pantry.count) spices available")
                        .font(.footnote)
                }
            }
            .navigationTitle("Pantry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Add spice", isPresented: $showAddSheet) {
                TextField("Name (e.g. Paprika)", text: $newItemName)
                    .textInputAutocapitalization(.words)
                Button("Cancel", role: .cancel) { newItemName = "" }
                Button("Add") {
                    let name = newItemName
                    newItemName = ""
                    Task { try? await fs.addPantryItem(name: name) }
                }
            }
        }
    }

    private func deleteCustom(at offsets: IndexSet) {
        for idx in offsets {
            let item = fs.pantry[idx]

            guard item.isCustom, let id = item.id else { continue }
            Task { try? await fs.deletePantryItem(id: id) }
        }
    }
}

private struct PantryRow: View {
    let item: FSPantryItem
    @ObservedObject private var fs = FirestoreService.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: item.name))
                .foregroundStyle(item.isAvailable ? .green : .secondary)
                .frame(width: 26)

            Text(item.name)
                .foregroundStyle(item.isAvailable ? .primary : .secondary)

            Spacer()

            if item.isCustom {
                Text("custom")
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                    .foregroundStyle(.secondary)
            }

            Toggle("", isOn: Binding(
                get: { item.isAvailable },
                set: { newValue in
                    guard let id = item.id else { return }
                    Task { try? await fs.togglePantryItem(id: id, isAvailable: newValue) }
                }
            ))
            .labelsHidden()
        }
    }

    private func icon(for name: String) -> String {
        switch name.lowercased() {
        case "salt":            return "cube"
        case "sugar":           return "cube.transparent"
        case "black pepper",
             "pepper":          return "circle.grid.3x3.fill"
        case let n where n.contains("oil"):    return "drop.fill"
        case let n where n.contains("butter"): return "square.fill"
        case let n where n.contains("flour"):  return "bag.fill"
        default:                return "leaf"
        }
    }
}

#Preview {
    PantryView()
}
