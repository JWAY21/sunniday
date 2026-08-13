import SwiftUI

/// Set-once personal values that feed the model.
///
/// These live behind the gear rather than on the main screen, which is for
/// things you change per session: clothing, sunscreen, starting and ending a
/// session.
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vitaminDCalculator: VitaminDCalculator

    @State private var showBirthYearPicker = false

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
                } header: {
                    Text("About you")
                } footer: {
                    Text("Vitamin D synthesis declines gradually with age, so SUNniDAY adjusts its estimate if you set a birth year. The year is enough; it never asks for a full date of birth. Leave it unset and no age adjustment is applied.")
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
}
