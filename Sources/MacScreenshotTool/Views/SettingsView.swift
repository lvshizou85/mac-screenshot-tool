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

            // Scrolling capture settings
            Section("Scrolling Capture") {
                HStack {
                    Text("Max Segments")
                    Spacer()
                    Stepper(value: $settings.scrollSegments, in: 2...20) {
                        Text("\(settings.scrollSegments)")
                            .monospacedDigit()
                    }
                }
                HStack {
                    Text("Scroll Step")
                    Spacer()
                    Stepper(value: $settings.scrollStepPercent, in: 50...95, step: 5) {
                        Text("\(settings.scrollStepPercent)%")
                            .monospacedDigit()
                    }
                }
                HStack {
                    Text("Scroll Delay")
                    Spacer()
                    Stepper(value: $settings.scrollDelay, in: 0.1...2.0, step: 0.05) {
                        Text(String(format: "%.2fs", settings.scrollDelay))
                            .monospacedDigit()
                    }
                }
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
