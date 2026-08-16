import SwiftUI

/// Set-once personal values that feed the model.
///
/// These live behind the gear rather than on the main screen, which is for
/// things you change per session: clothing, sunscreen, starting and ending a
/// session.
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vitaminDCalculator: VitaminDCalculator
    @EnvironmentObject var healthManager: HealthManager

    @State private var showBirthYearPicker = false
    @State private var isImporting = false
    /// Nil until an import has actually been attempted, so the advice below
    /// only appears once the user has tried.
    @State private var lastImport: HealthManager.BirthYearImportResult?

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: { showBirthYearPicker = true }) {
                        HStack {
                            Text("Year of birth")
                                .foregroundColor(.primary)
                            Spacer()
                            if let year = vitaminDCalculator.birthYear {
                                Text(String(year))
                                    .foregroundColor(.secondary)
                            } else {
                                // Called out rather than shown as ordinary
                                // placeholder text: unset means no age
                                // adjustment at all, which quietly inflates the
                                // estimate for anyone over 20.
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text("Not set")
                                }
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }

                    Button(action: importFromHealth) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                            Text("Import from Apple Health")
                            Spacer()
                            if isImporting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isImporting)

                    if case .accessDenied = lastImport {
                        Button(action: openHealthApp) {
                            HStack {
                                Image(systemName: "arrow.up.forward.app.fill")
                                    .foregroundColor(.pink)
                                Text("Open Apple Health")
                            }
                        }
                    }
                } header: {
                    Text("About you")
                } footer: {
                    footerText
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showBirthYearPicker) {
                BirthYearPicker(selection: $vitaminDCalculator.birthYear)
            }
        }
        .presentationBackground(Color(UIColor.systemBackground).opacity(0.99))
    }

    @ViewBuilder
    private var footerText: some View {
        switch lastImport {
        case .accessDenied:
            // iOS will not show the permission sheet again once this app has
            // been answered about date of birth, so pointing at the sheet would
            // be useless advice. The Health app is the only route back.
            Text("SUNniDAY does not have permission to read your date of birth, and iOS will not ask again. Turn it on in Apple Health under Profile, Apps and Services, SUNniDAY. Or just tap Year of birth above and choose it yourself.")
                .foregroundColor(.orange)
        case .noDateInHealth:
            Text("Apple Health does not have a date of birth set. You can add one in Health, or tap Year of birth above and choose it yourself.")
                .foregroundColor(.orange)
        case .healthUnavailable:
            Text("Apple Health is not available on this device. Tap Year of birth above to set it yourself.")
                .foregroundColor(.orange)
        case .imported, .none:
            if vitaminDCalculator.birthYear == nil {
                Text("Please set your year of birth. Vitamin D synthesis declines gradually with age, and until this is set SUNniDAY applies no age adjustment at all, which overestimates for anyone over 20. The year is enough; it never asks for a full date of birth, and importing keeps only the year.")
                    .foregroundColor(.orange)
            } else {
                Text("Vitamin D synthesis declines gradually with age, so SUNniDAY adjusts its estimate using your birth year. The year is enough; it never asks for a full date of birth, and importing keeps only the year.")
            }
        }
    }

    private func importFromHealth() {
        isImporting = true
        lastImport = nil
        healthManager.importBirthYearFromHealth { result in
            isImporting = false
            lastImport = result
            if case .imported(let year) = result {
                vitaminDCalculator.birthYear = year
            }
        }
    }

    private func openHealthApp() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
}
