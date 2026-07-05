import OSLog

enum Logging {
    static let networking = Logger(subsystem: "com.jway21.sunniday", category: "Networking")
    static let uv = Logger(subsystem: "com.jway21.sunniday", category: "UV")
    static let health = Logger(subsystem: "com.jway21.sunniday", category: "Health")
    static let calculator = Logger(subsystem: "com.jway21.sunniday", category: "Calculator")
    static let widget = Logger(subsystem: "com.jway21.sunniday", category: "Widget")
    static let signpost = OSSignposter(subsystem: "com.jway21.sunniday", category: "Signpost")
}

