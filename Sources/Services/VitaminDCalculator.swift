import Foundation
import Combine
import CoreLocation
import HealthKit
import UserNotifications
import WidgetKit
import UIKit
import OSLog

enum ClothingLevel: Int, CaseIterable {
    case none = -1
    case minimal = 0
    case light = 1
    case moderate = 2
    case heavy = 3
    
    var description: String {
        switch self {
        case .none: return "Nude!"
        case .minimal: return "Minimal (swimwear)"
        case .light: return "Light (shorts, tee)"
        case .moderate: return "Moderate (pants, tee)"
        case .heavy: return "Heavy (pants, sleeves)"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .none: return "Nude!"
        case .minimal: return "Minimal"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .heavy: return "Heavy"
        }
    }
    
    var exposureFactor: Double {
        switch self {
        case .none: return 1.0
        case .minimal: return 0.80
        case .light: return 0.50
        case .moderate: return 0.30
        case .heavy: return 0.10
        }
    }
}

enum SunscreenLevel: Int, CaseIterable {
    case none = 0
    case spf15 = 15
    case spf30 = 30
    case spf50 = 50
    case spf100 = 100
    
    var description: String {
        switch self {
        case .none: return "None"
        case .spf15: return "SPF 15"
        case .spf30: return "SPF 30"
        case .spf50: return "SPF 50"
        case .spf100: return "SPF 100+"
        }
    }
    
    var uvTransmissionFactor: Double {
        switch self {
        case .none: return 1.0      // 100% UV passes through
        case .spf15: return 0.07    // ~7% UV passes through (blocks 93%)
        case .spf30: return 0.03    // ~3% UV passes through (blocks 97%)
        case .spf50: return 0.02    // ~2% UV passes through (blocks 98%)
        case .spf100: return 0.01   // ~1% UV passes through (blocks 99%)
        }
    }
}

enum SkinType: Int, CaseIterable {
    case type1 = 1
    case type2 = 2
    case type3 = 3
    case type4 = 4
    case type5 = 5
    case type6 = 6
    
    var description: String {
        switch self {
        case .type1: return "Very fair"
        case .type2: return "Fair"
        case .type3: return "Light"
        case .type4: return "Medium"
        case .type5: return "Dark"
        case .type6: return "Very dark"
        }
    }
    
    var vitaminDFactor: Double {
        switch self {
        case .type1: return 1.25   // Very fair produces more
        case .type2: return 1.1    // Fair produces more
        case .type3: return 1.0    // Light skin is reference
        case .type4: return 0.7    // Medium skin
        case .type5: return 0.4    // Dark skin
        case .type6: return 0.2    // Very dark skin
        }
    }
}

class VitaminDCalculator: ObservableObject {
    @Published var isInSun = false
    @Published var clothingLevel: ClothingLevel = .light {
        didSet {
            UserDefaults.standard.set(clothingLevel.rawValue, forKey: "preferredClothingLevel")
        }
    }
    @Published var sunscreenLevel: SunscreenLevel = .none {
        didSet {
            UserDefaults.standard.set(sunscreenLevel.rawValue, forKey: "preferredSunscreenLevel")
        }
    }
    @Published var skinType: SkinType = .type3 {
        didSet {
            UserDefaults.standard.set(skinType.rawValue, forKey: "userSkinType")
            // Check if manually selected type matches HealthKit value
            if !isSettingFromHealth {
                checkIfMatchesHealthKitSkinType()
            }
        }
    }
    @Published var currentVitaminDRate: Double = 0.0
    @Published var sessionVitaminD: Double = 0.0
    @Published var sessionStartTime: Date?
    @Published var skinTypeFromHealth = false
    /// Erythemal dose accumulated this session — drives burn risk.
    @Published var cumulativeMEDFraction: Double = 0.0
    /// Vitamin-D-effective dose accumulated this session: the erythemal dose
    /// weighted per-increment by solar elevation and sunscreen. Integrated
    /// incrementally because those vary during a session — applying the current
    /// values to the whole session retroactively would (for example) zero out
    /// everything synthesised earlier once the sun sets.
    @Published var cumulativeVitaminDDose: Double = 0.0
    @Published var userAge: Int? = nil {
        didSet {
            if let age = userAge {
                UserDefaults.standard.set(age, forKey: "userAge")
            } else {
                UserDefaults.standard.removeObject(forKey: "userAge")
            }
        }
    }
    @Published var ageFromHealth = false
    @Published var currentUVQualityFactor: Double = 1.0
    @Published var currentAdaptationFactor: Double = 1.0
    
    private var timer: Timer?
    private var lastUV: Double = 0.0
    private var healthManager: HealthManager?
    private var isSettingFromHealth = false
    private weak var uvService: UVService?
    private var healthKitSkinType: SkinType?
    private var lastUpdateTime: Date?
    private var lastRateUpdateTime: Date?
    private var lastRateUV: Double = -1
    private let sharedDefaults = UserDefaults(suiteName: "group.jway21.sunniday.widget")
    private var appActiveObserver: NSObjectProtocol?
    private var appBackgroundObserver: NSObjectProtocol?
    private var wasTrackingBeforeBackground = false
    private var lastSessionSaveTime: Date?
    /// Manually logged amounts added during an active session. Kept separate so
    /// recomputing synthesis from the dose each tick can't wipe them.
    private var manualSessionAdjustment: Double = 0.0
    /// Ensures the approaching-burn notification fires once per session.
    private var hasWarnedApproachingBurn = false
    /// The day's accumulated dose at the moment this session began — the point
    /// on the shared daily curve this session starts climbing from.
    private var sessionStartDayDose: Double = 0
    /// Dose of a pending Log Past entry / adjusted window, committed on save.
    private var pendingLoggedDose: Double = 0
    private var pendingWindowDose: Double = 0
    private var lastWidgetUpdateTime: Date?
    private let widgetUpdateThrottle: TimeInterval = 60.0
    private var todaysHealthBase: Double = 0.0
    private var lastHealthBaseRefreshTime: Date?
    private let healthBaseRefreshInterval: TimeInterval = 900.0 // 15 min
    #if DEBUG
    private var sessionInterval: OSSignpostIntervalState?
    private static let logger = Logger(subsystem: "com.jway.sunniday", category: "Calculator")
    private let signposter = OSSignposter(subsystem: "com.jway.sunniday", category: "Calculator")
    #endif
    
    // MARK: - Vitamin D synthesis model
    //
    // Dose is expressed as a fraction of an MED — the same unit the photobiology
    // literature uses — and synthesis SATURATES rather than accumulating
    // linearly:
    //
    //     D(m) = Dmax × (1 − e^(−k·m))        m = cumulative MED fraction
    //
    // The plateau reflects previtamin D3 reaching photoequilibrium at ~10–15%
    // conversion of 7-dehydrocholesterol, beyond which it photoisomerises to
    // lumisterol3 and tachysterol3 (Holick, Science 1981) — long assumed inert,
    // now known to yield bioactive metabolites, but they make no vitamin D.
    // That is the mechanism preventing vitamin D intoxication from prolonged
    // sun, so unbounded linear accumulation is not physiological.
    //
    // Calibration: Holick's figures are fluorescent-lamp derived, and solar UV
    // is ~1.32× more previtamin-D-effective per unit erythemal dose. We scale by
    // a deliberately conservative 1.25.
    //   Dmax = 20,000 × 1.25 = 25,000 IU (whole-body asymptote)
    //   k    = 0.92
    // Which reproduces the literature anchors:
    //   ¼ MED over ¼ body → ~1,280 IU   (Holick's rule ~1,000 lamp / ~1,250 solar)
    //   1 MED whole body  → ~15,000 IU  (Holick 10,000–25,000)
    private let vitaminDMaxIU = 25000.0
    private let vitaminDSaturationK = 0.92

    /// MED minutes at UV index 1 by Fitzpatrick type. Must match UVService.
    static let medMinutesAtUV1: [Int: Double] = [
        1: 150.0, 2: 250.0, 3: 425.0, 4: 600.0, 5: 850.0, 6: 1100.0
    ]
    
    init() {
        loadUserPreferences()
        setupAppLifecycleObservers()
        restoreActiveSession()
    }
    
    deinit {
        if let observer = appActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = appBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func setHealthManager(_ healthManager: HealthManager) {
        self.healthManager = healthManager
        checkHealthKitSkinType()
        checkHealthKitAge()
        updateAdaptationFactor()
        // Prime today's base from Health
        refreshTodaysHealthBase(force: true)
    }
    
    func setUVService(_ uvService: UVService) {
        self.uvService = uvService
    }
    
    private func getSafeMinutes() -> Int {
        guard let uvService = uvService else { return 60 }
        return uvService.burnTimeMinutes[skinType.rawValue] ?? 60
    }
    
    private func loadUserPreferences() {
        if let savedClothingLevel = UserDefaults.standard.object(forKey: "preferredClothingLevel") as? Int,
           let clothing = ClothingLevel(rawValue: savedClothingLevel) {
            clothingLevel = clothing
        }
        
        if let savedSunscreenLevel = UserDefaults.standard.object(forKey: "preferredSunscreenLevel") as? Int,
           let sunscreen = SunscreenLevel(rawValue: savedSunscreenLevel) {
            sunscreenLevel = sunscreen
        }
        
        if let savedSkinType = UserDefaults.standard.object(forKey: "userSkinType") as? Int,
           let skin = SkinType(rawValue: savedSkinType) {
            skinType = skin
        }
        
        if let savedAge = UserDefaults.standard.object(forKey: "userAge") as? Int {
            userAge = savedAge
        } else {
            userAge = nil
        }
    }
    
    private func setupAppLifecycleObservers() {
        appBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // Save tracking state and pause timer
            self.wasTrackingBeforeBackground = self.isInSun
            if self.isInSun {
                // Save session state before going to background
                self.saveActiveSession()
                self.timer?.invalidate()
                self.timer = nil
            }
        }
        
        appActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // Resume timer if was tracking
            if self.wasTrackingBeforeBackground && self.isInSun && self.timer == nil {
                // Resume with 1-second timer
                self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    let currentUV = self.lastUV
                    self.updateVitaminD(uvIndex: currentUV)
                }
                // Update immediately
                self.updateVitaminD(uvIndex: self.lastUV)
            }
        }
    }
    
    func startSession(uvIndex: Double) {
        guard isInSun else { return }
        
        // Only reset session data if we're starting a new session (not resuming)
        if sessionStartTime == nil {
            sessionStartTime = Date()
            sessionVitaminD = 0.0
            cumulativeMEDFraction = 0.0
            cumulativeVitaminDDose = 0.0
            manualSessionAdjustment = 0.0
            hasWarnedApproachingBurn = false
            sessionStartDayDose = todaysDose   // pick up where the day left off
            lastUpdateTime = Date()
        }
        
        lastUV = uvIndex

        // Save initial session state
        saveActiveSession()
        writeSessionState()
        #if DEBUG
        let state = signposter.beginInterval("Session")
        sessionInterval = state
        Self.logger.debug("Session start UV=\(uvIndex, privacy: .public)")
        #endif
        
        // Update every second for real-time display
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Use the current UV from UVService, not lastUV
            let currentUV = self.lastUV
            // updateVitaminD advances the MED dose and derives synthesis from it.
            self.updateVitaminD(uvIndex: currentUV)
        }
        
        updateVitaminDRate(uvIndex: uvIndex)
    }
    
    func stopSession() {
        timer?.invalidate()
        timer = nil
        sessionStartTime = nil
        cumulativeMEDFraction = 0.0
        cumulativeVitaminDDose = 0.0
        manualSessionAdjustment = 0.0
        hasWarnedApproachingBurn = false
        
        // Cancel any pending burn warnings
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["burnWarning"])
        
        // Clear saved session state
        saveActiveSession()

        // Authoritative "not tracking" write, then refresh the rest
        writeSessionState()
        updateWidgetData(force: true)
        #if DEBUG
        if let state = sessionInterval {
            signposter.endInterval("Session", state)
            sessionInterval = nil
        }
        Self.logger.debug("Session stop")
        #endif
    }

    /// The single source that writes tracking flag + session start to the app
    /// group. Only the session lifecycle calls this, so periodic widget
    /// refreshes can never flip a widget-initiated session off.
    private func writeSessionState() {
        sharedDefaults?.set(isInSun, forKey: "isTracking")
        if isInSun, let start = sessionStartTime {
            sharedDefaults?.set(start, forKey: "sessionStartDate")
        } else {
            sharedDefaults?.removeObject(forKey: "sessionStartDate")
        }
    }

    func updateUV(_ uvIndex: Double) {
        lastUV = uvIndex
        updateVitaminDRate(uvIndex: uvIndex)
    }
    
    private func updateVitaminDRate(uvIndex: Double) {
        // Calculate UV quality factor based on time of day. This is also the hook
        // for the erythemal→previtamin-D action-spectrum correction: UV index is
        // erythemally weighted, and wavelengths above 330 nm drive erythema but
        // not vitamin D synthesis, so erythemal dose over-credits synthesis at
        // low solar elevation (Young et al., PNAS 2021).
        currentUVQualityFactor = calculateUVQualityFactor()

        // Instantaneous rate is the slope of the saturating curve at the dose
        // accumulated so far, converted to IU/hr. As a session progresses the
        // marginal rate falls — approaching photoequilibrium.
        let medPerHour = medFractionPerMinute(uvIndex: uvIndex) * 60.0
        currentVitaminDRate = marginalIUPerMED(atMEDFraction: todaysDose)
            * medPerHour
            * doseWeighting
            * yieldModifiers

        // Throttled widget update
        updateWidgetData()
    }
    
    private func updateVitaminD(uvIndex: Double) {
        guard isInSun else { return }
        
        let now = Date()

        // Calculate actual time elapsed since last update (should be ~1 second)
        let elapsed = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 1.0
        lastUpdateTime = now

        // Advance the dose FIRST — synthesis is a function of it. Uses real
        // elapsed time so a stuttering timer can't skew it.
        if uvIndex > 0 {
            let deltaMED = medFractionPerMinute(uvIndex: uvIndex) * (elapsed / 60.0)
            cumulativeMEDFraction += deltaMED
            // Weight this increment by the conditions during it, then bank it
            // into both the session and the shared daily accumulator.
            let deltaDose = deltaMED * doseWeighting
            cumulativeVitaminDDose += deltaDose
            todaysDose += deltaDose
            checkBurnWarning()
        }

        // Recalculate rate only when UV changed meaningfully or quality factor needs refresh (~60s)
        let uvChanged = abs(uvIndex - lastRateUV) > 0.01
        let needsQualityRefresh = lastRateUpdateTime == nil || now.timeIntervalSince(lastRateUpdateTime!) >= 60.0
        if uvChanged || needsQualityRefresh {
            updateVitaminDRate(uvIndex: uvIndex)
            lastRateUpdateTime = now
            lastRateUV = uvIndex
        }

        // Recompute from the dose rather than integrating a rate — this is what
        // makes synthesis saturate toward photoequilibrium instead of climbing
        // linearly for as long as the session runs.
        sessionVitaminD = incrementIU(from: sessionStartDayDose,
                                     to: todaysDose,
                                     modifiers: yieldModifiers)
            + manualSessionAdjustment

        // Save session state every 10 seconds
        if lastSessionSaveTime == nil || now.timeIntervalSince(lastSessionSaveTime!) >= 10.0 {
            saveActiveSession()
            lastSessionSaveTime = now
        }
        
        // Throttled widget update
        updateWidgetData()
    }
    
    func toggleSunExposure(uvIndex: Double) {
        isInSun.toggle()
        #if DEBUG
        Self.logger.debug("Toggle exposure -> isInSun=\(self.isInSun, privacy: .public) UV=\(uvIndex, privacy: .public)")
        #endif
        
        if isInSun {
            startSession(uvIndex: uvIndex)
        } else {
            stopSession()
        }
    }
    
    /// Adopt a session that was started from the widget while the app was closed.
    /// Accounting catches up from the widget's start date at the current rate on the first tick.
    func adoptWidgetSession(startDate: Date, uvIndex: Double) {
        guard !isInSun else { return }
        isInSun = true
        sessionStartTime = startDate
        sessionVitaminD = 0.0
        cumulativeMEDFraction = 0.0
        lastUpdateTime = startDate
        lastUV = uvIndex
        startSession(uvIndex: uvIndex)
    }

    /// End the in-app session without saving — used when a widget End action
    /// already produced the authoritative record for the same session.
    func discardActiveSession() {
        guard isInSun else { return }
        isInSun = false
        stopSession()
    }

    func addManualEntry(amount: Double) {
        // Simply add the manual entry amount to today's session vitamin D
        // This will be saved to Health by the view that calls this.
        // Tracked separately so an active session's per-tick recompute (which
        // derives synthesis from the accumulated dose) doesn't discard it.
        manualSessionAdjustment += amount
        sessionVitaminD += amount
        commitLoggedDose()
        
        // Update widget data to reflect the new total
        updateWidgetData(force: true)
    }
    
    func calculateVitaminD(uvIndex: Double, exposureMinutes: Double, skinType: SkinType, clothingLevel: ClothingLevel, sunscreenLevel: SunscreenLevel = .none) -> Double {
        // Same saturating, MED-anchored model as a live session, so a logged
        // past session and a tracked one of equal exposure agree.
        guard uvIndex > 0,
              let medAtUV1 = Self.medMinutesAtUV1[skinType.rawValue],
              medAtUV1 > 0 else { return 0 }

        // Dose accrued, as a fraction of this skin type's MED at this UV,
        // weighted for how vitamin-D-effective that UV is (solar elevation) and
        // for sunscreen — mirroring how a live session banks each increment.
        let medFraction = (uvIndex / medAtUV1) * exposureMinutes
        let effectiveDose = medFraction
            * currentUVQualityFactor
            * sunscreenLevel.uvTransmissionFactor

        // No skin-pigment term — MED already encodes phototype (see yieldModifiers).
        // Sits on top of the day's dose so a logged session earns the flatter
        // part of the shared daily curve, exactly like a live one.
        pendingLoggedDose = effectiveDose
        let modifiers = clothingLevel.exposureFactor * ageFactor * currentAdaptationFactor
        return incrementIU(from: todaysDose,
                           to: todaysDose + effectiveDose,
                           modifiers: modifiers)
    }

    /// Commit a Log Past entry's dose into the day once it's actually saved.
    func commitLoggedDose() {
        todaysDose += pendingLoggedDose
        pendingLoggedDose = 0
    }

    /// Commit an adjusted session window, replacing this session's contribution
    /// to the day rather than adding to it.
    func commitAdjustedSessionWindow() {
        guard pendingWindowDose > 0 else { return }
        todaysDose = sessionStartDayDose + pendingWindowDose
        pendingWindowDose = 0
    }
    
    private func checkHealthKitSkinType() {
        healthManager?.getFitzpatrickSkinType { [weak self] hkSkinType in
            guard let self = self, let hkSkinType = hkSkinType else { return }
            
            // Map HealthKit Fitzpatrick skin type to our SkinType enum
            let mappedSkinType: SkinType?
            switch hkSkinType {
            case .I:
                mappedSkinType = .type1
            case .II:
                mappedSkinType = .type2
            case .III:
                mappedSkinType = .type3
            case .IV:
                mappedSkinType = .type4
            case .V:
                mappedSkinType = .type5
            case .VI:
                mappedSkinType = .type6
            case .notSet:
                mappedSkinType = nil
            @unknown default:
                mappedSkinType = nil
            }
            
            // Store the HealthKit skin type for comparison
            self.healthKitSkinType = mappedSkinType
            
            // If we got a valid skin type from Health, use it
            if let mappedSkinType = mappedSkinType {
                self.isSettingFromHealth = true
                self.skinType = mappedSkinType
                self.skinTypeFromHealth = true
                self.isSettingFromHealth = false
            } else {
                self.skinTypeFromHealth = false
            }
        }
    }
    
    private func checkHealthKitAge() {
        healthManager?.getAge { [weak self] age in
            guard let self = self else { return }
            
            if let age = age {
                self.userAge = age
                self.ageFromHealth = true
            } else {
                self.userAge = nil
                self.ageFromHealth = false
            }
            
            // Recalculate vitamin D rate with new age (or without it)
            self.updateVitaminDRate(uvIndex: self.lastUV)
        }
    }
    
    private func checkIfMatchesHealthKitSkinType() {
        // If user manually selects the same skin type as HealthKit, show the heart icon
        if let healthKitType = healthKitSkinType, healthKitType == skinType {
            skinTypeFromHealth = true
        } else {
            skinTypeFromHealth = false
        }
    }
    
    // MARK: - Synthesis model helpers

    /// Whole-body vitamin D (IU) synthesised at a cumulative MED fraction,
    /// before body-surface and physiological modifiers.
    private func synthesisedIU(atMEDFraction m: Double) -> Double {
        vitaminDMaxIU * (1 - exp(-vitaminDSaturationK * max(0, m)))
    }

    /// Marginal synthesis per additional MED fraction — the slope of the
    /// saturating curve, used for the live "potential" rate display.
    private func marginalIUPerMED(atMEDFraction m: Double) -> Double {
        vitaminDMaxIU * vitaminDSaturationK * exp(-vitaminDSaturationK * max(0, m))
    }

    /// Vitamin D synthesis decreases with age as cutaneous 7-dehydrocholesterol
    /// declines (~25% of youthful capacity by 70). Only applied when we have age.
    /// Declines linearly from full capacity at 20 to a 25% floor at 70 — a
    /// slope of 1.5%/year, so the ramp actually reaches the floor.
    ///
    /// (The previous 1%/year slope only reached 50% by 70 and was then clamped
    /// straight to 25%, which meant a 70th birthday halved the estimate
    /// overnight.) Note the age decline itself is contested — see the info
    /// screen's limitations.
    private var ageFactor: Double {
        guard let age = userAge else { return 1.0 }
        let declined = 1.0 - Double(age - 20) * 0.015
        return min(1.0, max(0.25, declined))
    }

    /// Weights an erythemal dose increment into a vitamin-D-effective one.
    /// Both terms describe how much vitamin-D-active UV actually reaches the
    /// skin *at this moment*, so they belong in the dose, not the output.
    private var doseWeighting: Double {
        currentUVQualityFactor * sunscreenLevel.uvTransmissionFactor
    }

    /// Scales the synthesised total: how much skin is exposed and how well it
    /// converts. These change rarely within a session, so applying them to the
    /// total is fine.
    ///
    /// There is deliberately NO skin-pigment term here. MED already encodes
    /// phototype — type VI takes ~7× longer to reach 1 MED than type I — and
    /// per MED, synthesis is broadly comparable across pigmentation (Holick,
    /// Science 1981: "skin pigment is not an essential regulator"). Applying
    /// `skinType.vitaminDFactor` on top would double-count melanin, compounding
    /// to a ~44× penalty for type VI.
    private var yieldModifiers: Double {
        clothingLevel.exposureFactor * ageFactor * currentAdaptationFactor
    }

    // MARK: - Daily dose: the plateau belongs to the day, not the session
    //
    // Photoequilibrium is a property of your skin over a day — the 7-DHC pool
    // and its ceiling don't reset because you came inside for lunch. So the
    // saturating curve is shared across every session in a day: a later session
    // starts where the earlier one left off and earns the flatter part of the
    // curve. Without this, three 1-MED sessions would yield 45,111 IU against
    // 23,418 IU for the same dose taken in one stretch — and would sail past
    // D_max, contradicting the whole "sunlight can't overdose you" claim.

    private static let dayDoseKey = "todaysVitaminDDose"
    private static let dayDoseStampKey = "todaysVitaminDDoseDate"

    /// Cumulative vitamin-D-weighted dose accrued today. Resets at local
    /// midnight (a simplification — real recovery is gradual over ~a day).
    var todaysDose: Double {
        get {
            let d = UserDefaults.standard
            guard let stamp = d.object(forKey: Self.dayDoseStampKey) as? Date,
                  Calendar.current.isDateInToday(stamp) else { return 0 }
            return d.double(forKey: Self.dayDoseKey)
        }
        set {
            let d = UserDefaults.standard
            d.set(max(0, newValue), forKey: Self.dayDoseKey)
            d.set(Date(), forKey: Self.dayDoseStampKey)
        }
    }

    /// Synthesis earned by moving along the shared daily curve from `d0` to `d1`.
    private func incrementIU(from d0: Double, to d1: Double, modifiers: Double) -> Double {
        max(0, synthesisedIU(atMEDFraction: d1) - synthesisedIU(atMEDFraction: d0)) * modifiers
    }

    /// Re-integrate synthesised vitamin D (IU) over an arbitrary window earlier
    /// today, using that day's cached hourly UV and the solar-elevation
    /// weighting — the same kinetics a live session uses.
    ///
    /// This replaces linearly scaling a logged session's amount by its duration.
    /// Linear scaling credits every added minute at the tracked-period rate, so
    /// extending a session back into weaker morning sun (lower UV, low sun angle)
    /// over-counts badly, and it ignores the saturation plateau. Integrating the
    /// real per-hour UV and elevation quality fixes both.
    ///
    /// Returns 0 when the day's UV isn't cached (caller should fall back).
    func synthesisedIU(from start: Date, to end: Date) -> Double {
        guard end > start,
              let uvService = uvService,
              let medAtUV1 = Self.medMinutesAtUV1[skinType.rawValue], medAtUV1 > 0
        else { return 0 }

        let lat = UserDefaults.standard.double(forKey: "lastKnownLatitude")
        let lon = UserDefaults.standard.double(forKey: "lastKnownLongitude")
        let location = (lat != 0 || lon != 0) ? CLLocation(latitude: lat, longitude: lon) : nil

        let points = uvService.historicalUVPoints(from: start, to: end, near: location)
        guard points.count >= 2 else { return 0 }

        // Keep the same manual cloud override the session tracked with.
        let overrideFactor = uvService.cloudOverrideFactor

        // Trapezoidal integration of the elevation-weighted MED dose.
        var dose = 0.0
        for i in 0..<(points.count - 1) {
            let (t0, uv0) = points[i]
            let (t1, uv1) = points[i + 1]
            let minutes = t1.timeIntervalSince(t0) / 60.0
            guard minutes > 0 else { continue }
            let mid = t0.addingTimeInterval(t1.timeIntervalSince(t0) / 2)
            let uv = ((uv0 + uv1) / 2.0) * overrideFactor
            let quality = solarElevationDegrees(at: mid)
                .map { vitaminDQualityFactor(forElevationDegrees: $0) } ?? 1.0
            dose += (uv / medAtUV1) * quality * minutes
        }
        // Measured from where this session began on the day's curve, so an
        // adjusted window replaces (not stacks on) its own contribution.
        pendingWindowDose = dose
        return incrementIU(from: sessionStartDayDose,
                           to: sessionStartDayDose + dose,
                           modifiers: yieldModifiers)
    }

    /// MED fraction accrued per minute of exposure at a given UV.
    private func medFractionPerMinute(uvIndex: Double) -> Double {
        guard uvIndex > 0,
              let medAtUV1 = Self.medMinutesAtUV1[skinType.rawValue],
              medAtUV1 > 0 else { return 0 }
        return uvIndex / medAtUV1
    }

    /// Warn once when approaching the burn threshold (80% MED). The dose itself
    /// is advanced in `updateVitaminD`, which owns the elapsed-time bookkeeping,
    /// so this only inspects it.
    private func checkBurnWarning() {
        guard isInSun, !hasWarnedApproachingBurn, cumulativeMEDFraction >= 0.8 else { return }
        hasWarnedApproachingBurn = true
        scheduleImmediateBurnWarning()
    }
    
    private func scheduleImmediateBurnWarning() {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Approaching burn limit!"
        content.body = "You've reached 80% of your burn threshold. Consider seeking shade."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "burnWarning", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Vitamin-D-effective UV per unit erythemal UV, as a function of solar
    /// elevation.
    ///
    /// A low sun means a longer atmospheric path, which preferentially strips
    /// the short UVB that drives vitamin D synthesis while leaving the longer
    /// wavelengths that drive erythema. So an MED earned at 8am is worth far
    /// less vitamin D than one earned at midday — erythemally-weighted dose
    /// alone over-credits low sun (Young et al., PNAS 2021: "SED is a poor
    /// predictor of vitamin D synthesis").
    ///
    /// Normalised so 50°+ elevation is full synthesis: ~0.8 at 40°, ~0.5 at
    /// 30°, ~0.3 at 20°, ~0.1 at 10°, and nothing below the horizon. This is a
    /// deliberately simple approximation of the action-spectrum ratio.
    private func calculateUVQualityFactor() -> Double {
        let now = Date()
        guard let elevation = solarElevationDegrees(at: now) else {
            return legacyTimeOfDayQualityFactor(at: now)
        }
        return vitaminDQualityFactor(forElevationDegrees: elevation)
    }

    /// The elevation→yield curve itself. Exposed so the info screen can chart
    /// the exact function the model uses rather than re-deriving it.
    func vitaminDQualityFactor(forElevationDegrees elevation: Double) -> Double {
        guard elevation > 0 else { return 0.0 }   // sun below horizon
        let reference = sin(50.0 * .pi / 180.0)
        let ratio = sin(elevation * .pi / 180.0) / reference
        return min(1.0, pow(max(0.0, ratio), 1.5))
    }

    /// Synthesised IU for a given vitamin-D-effective dose, before yield
    /// modifiers. Exposed for the info screen's saturation chart.
    func synthesisCurveIU(atDose m: Double) -> Double {
        synthesisedIU(atMEDFraction: m)
    }

    /// The model's calibration constants, for display.
    var modelConstants: (dmax: Double, k: Double) { (vitaminDMaxIU, vitaminDSaturationK) }

    /// Solar elevation in degrees, or nil if we lack the location/sun times.
    ///
    /// Solar noon is taken as the midpoint of sunrise and sunset. Because those
    /// arrive from the API already in local time, that single step corrects for
    /// daylight saving, the location's longitude offset within its timezone,
    /// and the equation of time — all of which a clock-derived hour angle would
    /// get wrong (the previous hardcoded 13:00 solar noon was ~69 minutes late
    /// in Byron Bay outside DST).
    func solarElevationDegrees(at date: Date) -> Double? {
        guard let uvService = uvService,
              let sunrise = uvService.todaySunrise,
              let sunset = uvService.todaySunset,
              sunset > sunrise else { return nil }

        let solarNoon = Date(timeIntervalSince1970:
            (sunrise.timeIntervalSince1970 + sunset.timeIntervalSince1970) / 2.0)
        let hoursFromNoon = date.timeIntervalSince(solarNoon) / 3600.0

        // Solar declination — Cooper's equation, accurate to ~±0.5°
        let dayOfYear = Double(Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 172)
        let declination = 23.45 * sin(2.0 * .pi * (284.0 + dayOfYear) / 365.0)

        // Signed latitude: using the absolute value would invert the seasons
        // in the southern hemisphere.
        let lat = uvService.signedLatitude * .pi / 180.0
        let dec = declination * .pi / 180.0
        let hourAngle = 15.0 * hoursFromNoon * .pi / 180.0

        let sinElevation = sin(lat) * sin(dec) + cos(lat) * cos(dec) * cos(hourAngle)
        return asin(max(-1.0, min(1.0, sinElevation))) * 180.0 / .pi
    }

    /// Fallback for before sun times load. Assumes solar noon at 12:00 rather
    /// than the old 13:00, which was biased by daylight saving.
    private func legacyTimeOfDayQualityFactor(at date: Date) -> Double {
        let calendar = Calendar.current
        let t = Double(calendar.component(.hour, from: date))
            + Double(calendar.component(.minute, from: date)) / 60.0
        return max(0.1, min(1.0, exp(-abs(t - 12.0) * 0.2)))
    }
    
    private func updateAdaptationFactor() {
        healthManager?.getVitaminDHistory(days: 7) { [weak self] history in
            guard let self = self else { return }
            
            // Calculate average daily exposure over past 7 days
            let totalDays = 7.0
            let totalVitaminD = history.values.reduce(0, +)
            let averageDailyExposure = totalVitaminD / totalDays
            
            // Adaptation factor based on recent exposure
            // Low exposure (0-1000 IU/day avg) → 0.8x
            // Moderate exposure (5000 IU/day avg) → 1.0x  
            // High exposure (10000+ IU/day avg) → 1.2x
            let adaptationFactor: Double
            if averageDailyExposure < 1000 {
                adaptationFactor = 0.8
            } else if averageDailyExposure >= 10000 {
                adaptationFactor = 1.2
            } else {
                // Linear interpolation between 0.8 and 1.2
                adaptationFactor = 0.8 + (averageDailyExposure - 1000) / 9000 * 0.4
            }
            
            self.currentAdaptationFactor = adaptationFactor
            
            // Recalculate rate with new adaptation factor
            self.updateVitaminDRate(uvIndex: self.lastUV)
        }
    }
    
    private func refreshTodaysHealthBase(force: Bool = false) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let now = Date()
        if !force, let last = lastHealthBaseRefreshTime, now.timeIntervalSince(last) < healthBaseRefreshInterval {
            return
        }
        healthManager?.readVitaminDIntake(from: startOfDay, to: endOfDay) { [weak self] total, _ in
            guard let self = self else { return }
            self.todaysHealthBase = total
            self.lastHealthBaseRefreshTime = Date()
        }
    }

    // Expose a public refresh for callers after Health writes
    func refreshTodayTotals(forceWidget: Bool = false) {
        refreshTodaysHealthBase(force: true)
        if forceWidget { updateWidgetData(force: true) }
    }

    private func updateWidgetData() { updateWidgetData(force: false) }

    private func updateWidgetData(force: Bool) {
        guard let uvService = uvService else { return }

        // Cache latest simple values for widget.
        // NOTE: isTracking / sessionStartDate are written ONLY by the session
        // lifecycle methods (writeSessionState), never here — otherwise a
        // periodic refresh could clobber a session the widget just started
        // before the app has reconciled it.
        // Don't clobber the widget's last-known UV with a transient 0 during a
        // cold launch (currentUV is 0.0 until the first fetch returns). A real
        // 0 — night, sun down — only counts once we've actually loaded data
        // (lastSuccessfulUpdate != nil), so night still correctly shows "No UV".
        if uvService.currentUV > 0 || uvService.lastSuccessfulUpdate != nil {
            sharedDefaults?.set(uvService.currentUV, forKey: "currentUV")
        }
        sharedDefaults?.set(currentVitaminDRate, forKey: "vitaminDRate")
        // Don't clobber a clothing change made on the widget that the app
        // hasn't reconciled yet — same race as isTracking above, where a
        // periodic refresh would overwrite the widget's fresh value.
        if sharedDefaults?.bool(forKey: "widgetClothingChanged") != true {
            sharedDefaults?.set(clothingLevel.rawValue, forKey: "clothingLevel")
        }
        sharedDefaults?.set(UserDefaults.standard.bool(forKey: "usesMCG"), forKey: "usesMCG")

        // Ensure health base is reasonably fresh
        refreshTodaysHealthBase()

        // Compute today total without a Health read.
        // `todaysBase` is everything logged today EXCLUDING the current live
        // session; the widget adds its own live session estimate on top of it
        // so the day's total climbs in real time without double-counting.
        let todaysTotal = todaysHealthBase + sessionVitaminD
        sharedDefaults?.set(todaysHealthBase, forKey: "todaysBase")
        sharedDefaults?.set(todaysTotal, forKey: "todaysTotal")

        // Throttle widget timeline reloads
        let now = Date()
        if force || lastWidgetUpdateTime == nil || now.timeIntervalSince(lastWidgetUpdateTime!) >= widgetUpdateThrottle {
            WidgetCenter.shared.reloadAllTimelines()
            lastWidgetUpdateTime = now
            #if DEBUG
            Self.logger.debug("Widget reload (throttled): UV=\(uvService.currentUV, privacy: .public) rate=\(self.currentVitaminDRate, privacy: .public) today=\(todaysTotal, privacy: .public)")
            #endif
        }
    }
    
    private func saveActiveSession() {
        guard isInSun else {
            // Clear any saved session if not tracking
            UserDefaults.standard.removeObject(forKey: "activeSessionStartTime")
            UserDefaults.standard.removeObject(forKey: "activeSessionVitaminD")
            UserDefaults.standard.removeObject(forKey: "activeSessionMED")
            UserDefaults.standard.removeObject(forKey: "activeSessionVitDDose")
            UserDefaults.standard.removeObject(forKey: "activeSessionStartDayDose")
            UserDefaults.standard.removeObject(forKey: "activeSessionLastUV")
            UserDefaults.standard.removeObject(forKey: "activeSessionLastUpdate")
            return
        }
        
        // Save current session state
        UserDefaults.standard.set(sessionStartTime, forKey: "activeSessionStartTime")
        UserDefaults.standard.set(sessionVitaminD, forKey: "activeSessionVitaminD")
        UserDefaults.standard.set(cumulativeMEDFraction, forKey: "activeSessionMED")
        UserDefaults.standard.set(cumulativeVitaminDDose, forKey: "activeSessionVitDDose")
        UserDefaults.standard.set(sessionStartDayDose, forKey: "activeSessionStartDayDose")
        UserDefaults.standard.set(lastUV, forKey: "activeSessionLastUV")
        UserDefaults.standard.set(lastUpdateTime, forKey: "activeSessionLastUpdate")
    }
    
    private func restoreActiveSession() {
        // Check if there's a saved active session
        guard let savedStartTime = UserDefaults.standard.object(forKey: "activeSessionStartTime") as? Date else {
            return
        }
        
        // Check if session is from today (don't restore old sessions)
        let calendar = Calendar.current
        guard calendar.isDateInToday(savedStartTime) else {
            // Clear old session data
            UserDefaults.standard.removeObject(forKey: "activeSessionStartTime")
            UserDefaults.standard.removeObject(forKey: "activeSessionVitaminD")
            UserDefaults.standard.removeObject(forKey: "activeSessionMED")
            UserDefaults.standard.removeObject(forKey: "activeSessionVitDDose")
            UserDefaults.standard.removeObject(forKey: "activeSessionStartDayDose")
            UserDefaults.standard.removeObject(forKey: "activeSessionLastUV")
            UserDefaults.standard.removeObject(forKey: "activeSessionLastUpdate")
            return
        }
        
        // Restore session state
        sessionStartTime = savedStartTime
        sessionVitaminD = UserDefaults.standard.double(forKey: "activeSessionVitaminD")
        cumulativeMEDFraction = UserDefaults.standard.double(forKey: "activeSessionMED")
        cumulativeVitaminDDose = UserDefaults.standard.double(forKey: "activeSessionVitDDose")
        sessionStartDayDose = UserDefaults.standard.double(forKey: "activeSessionStartDayDose")
        lastUV = UserDefaults.standard.double(forKey: "activeSessionLastUV")
        lastUpdateTime = UserDefaults.standard.object(forKey: "activeSessionLastUpdate") as? Date
        
        // Mark as tracking but don't start timer yet (wait for app to be fully initialized)
        isInSun = true
        wasTrackingBeforeBackground = true
    }
}
