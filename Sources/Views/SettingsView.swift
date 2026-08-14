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
    /// Set when an import returns nothing, so the fallback advice only appears
    /// once the user has actually tried.
    @State private var importFailed = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: { showBirthYearPicker = true }) {
                        HStack {
                            Text("Year of birth")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(vitaminDCalculator.birthYear.map(String.init) ?? "Not set")
                                .foregroundColor(.secondary)
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
                } header: {
                    Text("About you")
                } footer: {
                    if importFailed {
                        Text("Apple Health did not return a date of birth. It may not be set, or access may have been declined. You can tap Year of birth above and choose it yourself.")
                            .foregroundColor(.orange)
                    } else {
                        Text("Vitamin D synthesis declines gradually with age, so SUNniDAY adjusts its estimate if you set a birth year. The year is enough; it never asks for a full date of birth, and importing keeps only the year. Leave it unset and no age adjustment is applied.")
                    }
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

    private func importFromHealth() {
        isImporting = true
        importFailed = false
        healthManager.importBirthYearFromHealth { year in
            isImporting = false
            if let year {
                vitaminDCalculator.birthYear = year
            } else {
                importFailed = true
            }
        }
    }
}
