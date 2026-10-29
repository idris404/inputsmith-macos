import Foundation

final class RawReportRecorder {
    private(set) var reports: [RawInputReport] = []
    private(set) var isPaused = false
    var onReportsChanged: (() -> Void)?

    let capacity: Int
    private var sequence: UInt64 = 0
    private var previousBytes: [UInt8]?

    init(capacity: Int = 500) {
        self.capacity = max(capacity, 1)
    }

    func receive(reportID: UInt8, bytes: [UInt8], timestamp: Date = Date()) {
        guard !isPaused else { return }

        let changedIndices = Self.changedIndices(previous: previousBytes, current: bytes)
        sequence += 1
        reports.append(
            RawInputReport(
                sequence: sequence,
                timestamp: timestamp,
                reportID: reportID,
                bytes: bytes,
                changedIndices: changedIndices
            )
        )
        previousBytes = bytes

        if reports.count > capacity {
            reports.removeFirst(reports.count - capacity)
        }
        onReportsChanged?()
    }

    func togglePaused() {
        isPaused.toggle()
        onReportsChanged?()
    }

    func clear() {
        reports.removeAll(keepingCapacity: true)
        previousBytes = nil
        sequence = 0
        onReportsChanged?()
    }

    func export(to url: URL, source: String) throws {
        let capture = RawCaptureExport(
            schemaVersion: 1,
            generatedAt: Date(),
            source: source,
            reportCount: reports.count,
            reports: reports
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(capture).write(to: url, options: .atomic)
    }

    var observedFrequency: Double? {
        let sample = reports.suffix(120)
        guard let first = sample.first, let last = sample.last, sample.count > 1 else { return nil }
        let duration = last.timestamp.timeIntervalSince(first.timestamp)
        guard duration > 0 else { return nil }
        return Double(sample.count - 1) / duration
    }

    static func changedIndices(previous: [UInt8]?, current: [UInt8]) -> [Int] {
        guard let previous else { return Array(current.indices) }
        return current.indices.filter { index in
            index >= previous.count || previous[index] != current[index]
        }
    }
}
