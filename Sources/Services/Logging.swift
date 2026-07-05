import OSLog

enum Logging {
    static let networking = Logger(subsystem: "com.jway.sunniday", category: "Networking")
    static let uv = Logger(subsystem: "com.jway.sunniday", category: "UV")
    static let health = Logger(subsystem: "com.jway.sunniday", category: "Health")
    static let calculator = Logger(subsystem: "com.jway.sunniday", category: "Calculator")
    static let widget = Logger(subsystem: "com.jway.sunniday", category: "Widget")
    static let signpost = OSSignposter(subsystem: "com.jway.sunniday", category: "Signpost")
}

