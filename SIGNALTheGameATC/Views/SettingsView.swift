import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var apiKeyDraft: String
    @Binding var modelDraft: String
    @Binding var streamURLDraft: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("OpenAI API key", text: $apiKeyDraft)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Stored in the device Keychain. Never committed to git.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("OpenAI")
                }

                Section {
                    TextField("Model", text: $modelDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Example: gpt-4o-mini or gpt-4o")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Model")
                }

                Section {
                    TextField("HTTPS stream URL (optional MP3/AAC)", text: $streamURLDraft, axis: .vertical)
                        .lineLimit(2 ... 4)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Use only media you have rights to play (public domain / CC with compliance). Leave blank for synthesized static.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Radio bed")
                }

                Section {
                    Button("Delete saved API key", role: .destructive) {
                        KeychainStore.deleteAPIKey()
                        apiKeyDraft = ""
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        KeychainStore.saveAPIKey(apiKeyDraft)
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}
