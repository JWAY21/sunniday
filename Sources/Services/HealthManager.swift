import Foundation
import HealthKit
import OSLog

class HealthManager: ObservableObject {
    private static let logger = Logger(subsystem: "com.jway.sunniday", category: "Health")
    @Published var isAuthorized = false
    @Published var lastError: String?
    
    private let healthStore = HKHealthStore()
    private let vitaminDType = HKQuantityType.quantityType(forIdentifier: .dietaryVitaminD)!
    private let fitzpatrickSkinType = HKObjectType.characteristicType(forIdentifier: .fitzpatrickSkinType)!
    /// Requested only on demand, never in the first-launch sheet. HealthKit has
    /// no "age" characteristic, so a birth year can only come from here.
    private let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!

    init() {
        checkAuthorizationStatus()
    }
    
    /// - Parameter completion: called once the Health sheet has been dismissed,
    ///   whatever the user chose. Used to chain the notification prompt so the
    ///   two don't stack on top of each other at first launch.
    func requestAuthorization(completion: (() -> Void)? = nil) {
        guard HKHealthStore.isHealthDataAvailable() else {
            lastError = "Health data not available on this device"
            completion?()
            return
        }

        let typesToWrite: Set<HKSampleType> = [vitaminDType]
        // No dateOfBirth: the model only needs age in whole years, so the app
        // asks for a birth year instead of requesting a full date of birth on
        // the Health permission sheet.
        let typesToRead: Set<HKObjectType> = [vitaminDType, fitzpatrickSkinType]

        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                self?.lastError = error?.localizedDescription
                #if DEBUG
                if success {
                    Self.logger.debug("Health authorization granted")
                } else if let msg = error?.localizedDescription {
                    Self.logger.error("Health authorization failed: \(msg, privacy: .public)")
                }
                #endif
                completion?()
            }
        }
    }
    
    /// Asks Health for the date of birth and hands back the year only.
    ///
    /// Called only when the user taps Import in Settings, so the request never
    /// appears in the first-launch sheet. HealthKit has no age characteristic,
    /// so the sheet will say "Date of Birth" even though the app keeps nothing
    /// but the year.
    ///
    /// Why an import produced no year. The two failures need different advice,
    /// so they are reported separately rather than collapsed into "it failed".
    enum BirthYearImportResult {
        case imported(Int)
        /// Health holds no date of birth to read.
        case noDateInHealth
        /// Read access is off. iOS will not re-present the permission sheet for
        /// a type the user has already answered, so the only way back is the
        /// Health app itself.
        case accessDenied
        case healthUnavailable
    }

    func importBirthYearFromHealth(completion: @escaping (BirthYearImportResult) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.healthUnavailable)
            return
        }

        healthStore.requestAuthorization(toShare: [], read: [dateOfBirthType]) { [weak self] _, _ in
            guard let self else {
                DispatchQueue.main.async { completion(.healthUnavailable) }
                return
            }
            // Attempt the read regardless of the reported success flag: that
            // flag only says the sheet completed, not that access was granted.
            // Note the sheet does not appear at all if this app has already been
            // asked about date of birth on this device, which is the usual cause
            // of a silent failure on an install that predates this feature.
            var result: BirthYearImportResult
            do {
                let components = try self.healthStore.dateOfBirthComponents()
                if let year = components.year {
                    result = .imported(year)
                } else {
                    result = .noDateInHealth
                }
            } catch {
                let code = (error as NSError).code
                #if DEBUG
                Self.logger.error("Birth year import failed: \(error.localizedDescription, privacy: .public) (code \(code))")
                #endif
                // HKError.errorAuthorizationDenied / errorAuthorizationNotDetermined
                if code == HKError.errorAuthorizationDenied.rawValue
                    || code == HKError.errorAuthorizationNotDetermined.rawValue {
                    result = .accessDenied
                } else {
                    result = .noDateInHealth
                }
            }
            let outcome = result
            DispatchQueue.main.async { completion(outcome) }
        }
    }

    private func checkAuthorizationStatus() {
        let status = healthStore.authorizationStatus(for: vitaminDType)
        isAuthorized = status == .sharingAuthorized
    }
    
    func saveVitaminD(amount: Double, date: Date = Date(), completion: ((Bool) -> Void)? = nil) {
        guard isAuthorized else {
            requestAuthorization()
            completion?(false)
            return
        }
        
        // Convert IU to micrograms (1 IU = 0.025 mcg)
        let micrograms = amount * 0.025
        let quantity = HKQuantity(unit: .gramUnit(with: .micro), doubleValue: micrograms)
        let sample = HKQuantitySample(
            type: vitaminDType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: [
                HKMetadataKeyWasUserEntered: false,
                "Source": "SUNniDAY - UV Exposure",
                "Method": "Calculated from UV exposure",
                "OriginalValueInIU": amount
            ]
        )
        
        healthStore.save(sample) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = error.localizedDescription
                    #if DEBUG
                    Self.logger.error("Save vitamin D failed: \(error.localizedDescription, privacy: .public)")
                    #endif
                    completion?(false)
                } else {
                    #if DEBUG
                    Self.logger.debug("Saved vitamin D sample: \(micrograms, privacy: .public) mcg at \(date.timeIntervalSince1970, privacy: .public)")
                    #endif
                    completion?(true)
                }
            }
        }
    }
    
    func getTodaysVitaminD(completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: vitaminDType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    // Convert micrograms back to IU (1 mcg = 40 IU)
                    let micrograms = sum.doubleValue(for: .gramUnit(with: .micro))
                    let iuValue = micrograms * 40.0
                    completion(iuValue)
                } else {
                    completion(nil)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    func getVitaminDHistory(days: Int, completion: @escaping ([Date: Double]) -> Void) {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            completion([:])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        var dailyTotals: [Date: Double] = [:]
        
        let query = HKSampleQuery(
            sampleType: vitaminDType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else {
                DispatchQueue.main.async {
                    completion([:])
                }
                return
            }
            
            // Group samples by day
            for sample in samples {
                let micrograms = sample.quantity.doubleValue(for: .gramUnit(with: .micro))
                let iuValue = micrograms * 40.0
                let dayStart = calendar.startOfDay(for: sample.startDate)
                
                dailyTotals[dayStart, default: 0] += iuValue
            }
            
            DispatchQueue.main.async {
                completion(dailyTotals)
            }
        }
        
        healthStore.execute(query)
    }
    
    func getFitzpatrickSkinType(completion: @escaping (HKFitzpatrickSkinType?) -> Void) {
        do {
            let skinType = try healthStore.fitzpatrickSkinType()
            DispatchQueue.main.async {
                completion(skinType.skinType)
            }
        } catch {
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
                completion(nil)
            }
        }
    }
    

    
    func readVitaminDIntake(from startDate: Date, to endDate: Date, completion: @escaping (Double, Error?) -> Void) {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: vitaminDType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    // Convert micrograms back to IU (1 mcg = 40 IU)
                    let micrograms = sum.doubleValue(for: .gramUnit(with: .micro))
                    let iuValue = micrograms * 40.0
                    completion(iuValue, error)
                } else {
                    completion(0.0, error)
                }
            }
        }
        
        healthStore.execute(query)
    }
}
