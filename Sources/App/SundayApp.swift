import SwiftUI
import SwiftData

@main
struct SundayApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthManager = HealthManager()
    @StateObject private var uvService = UVService()
    @StateObject private var vitaminDCalculator = VitaminDCalculator()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    let modelContainer: ModelContainer
    
    init() {
        // Configure ModelContainer with proper storage location
        let schema = Schema([
            UserPreferences.self,
            VitaminDSession.self,
            CachedUVData.self
        ])

        do {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Perform migration from UserDefaults to SwiftData
            MigrationService.migrateUserDefaults(to: modelContainer.mainContext)
        } catch {
            // A corrupt or unreadable store used to be a fatalError, which
            // bricked the app on every launch with no way out short of
            // deleting it. Session history lives in HealthKit, and preferences
            // in UserDefaults, so an in-memory fallback loses only the local
            // cache and keeps the app usable.
            modelContainer = SundayApp.inMemoryFallbackContainer(for: schema)
        }
    }

    /// Last resort when the on-disk store cannot be opened. If even an
    /// in-memory container fails the schema itself is broken, which is a
    /// programming error rather than a runtime condition.
    private static func inMemoryFallbackContainer(for schema: Schema) -> ModelContainer {
        let fallback = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        return try! ModelContainer(for: schema, configurations: [fallback])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(healthManager)
                .environmentObject(uvService)
                .environmentObject(vitaminDCalculator)
                .environmentObject(networkMonitor)
                .modelContainer(modelContainer)
        }
    }
}