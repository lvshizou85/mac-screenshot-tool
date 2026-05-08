import SwiftUI
import AppKit

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            // Save directory
            Section("Save Location") {
                HStack {
                    TextField("Directory", text: $settings.saveDirectory)
                    Button("Browse...") {
                        selectDirectory()
                    }
                }
            }

            // Image format
            Section("Image Format") {
                Picker("Format", selection: $settings.imageFormat) {
                    Text("PNG").tag("png")
                    Text("JPG").tag("jpg")
                    Text("PDF").tag("pdf")
                    Text("TIFF").tag("tiff")
                }
                .pickerStyle(.segmented)
            }

            // Options
            Section("Options") {
                Toggle("Copy to clipboard after capture", isOn: $settings.copyToClipboard)
                Toggle("Show in Finder after capture", isOn: $settings.showInFinder)
            }
        }
        .padding()
        .frame(minWidth: 400)
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to save screenshots"

        if panel.runModal() == .OK, let url = panel.url {
            settings.saveDirectory = url.path
            settings.save()
        }
    }
}
