import Foundation

struct RawInputReport: Identifiable, Codable, Equatable {
    let id: UUID
    let sequence: UInt64
    let timestamp: Date
    let reportID: UInt8
    let bytes: [UInt8]
    let changedIndices: [Int]

    init(
        id: UUID = UUID(),
        sequence: UInt64,
        timestamp: Date = Date(),
        reportID: UInt8,
        bytes: [UInt8],
        changedIndices: [Int]
    ) {
        self.id = id
        self.sequence = sequence
        self.timestamp = timestamp
        self.reportID = reportID
        self.bytes = bytes
        self.changedIndices = changedIndices
    }

    var reportIDHex: String {
        String(format: "0x%02X", reportID)
    }

    var payloadHex: String {
        bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

struct RawCaptureExport: Codable {
    let schemaVersion: Int
    let generatedAt: Date
    let source: String
    let reportCount: Int
    let reports: [RawInputReport]
}
