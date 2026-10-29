import Foundation
import IOKit.hid

enum HIDInputReportSourceStatus: Equatable {
    case idle
    case listening(deviceName: String, maximumReportSize: Int)
    case unavailable(reason: String)

    var displayText: String {
        switch self {
        case .idle:
            return "Source inactive"
        case let .listening(deviceName, maximumReportSize):
            return "IOHID en écoute · \(deviceName) · buffer \(maximumReportSize) octets"
        case let .unavailable(reason):
            return "IOHID indisponible · \(reason)"
        }
    }
}

final class HIDInputReportSource {
    var onReport: ((UInt8, [UInt8], Date) -> Void)?
    var onStatusChanged: ((HIDInputReportSourceStatus) -> Void)?

    private(set) var status: HIDInputReportSourceStatus = .idle {
        didSet { onStatusChanged?(status) }
    }

    private var activeDevice: IOHIDDevice?
    private var reportBuffer: UnsafeMutablePointer<UInt8>?
    private var reportBufferCapacity = 0

    func start(device: IOHIDDevice, deviceName: String) {
        stop()

        let maximumReportSize = max(Self.integerProperty(kIOHIDMaxInputReportSizeKey, from: device), 64)
        ensureBufferCapacity(maximumReportSize)
        guard let reportBuffer else {
            status = .unavailable(reason: "allocation du buffer impossible")
            return
        }

        activeDevice = device
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(
            device,
            reportBuffer,
            reportBufferCapacity,
            { context, result, _, reportType, reportID, report, reportLength in
                guard
                    result == kIOReturnSuccess,
                    reportType == kIOHIDReportTypeInput,
                    let context,
                    reportLength > 0
                else { return }

                let source = Unmanaged<HIDInputReportSource>.fromOpaque(context).takeUnretainedValue()
                let bytes = Array(UnsafeBufferPointer(start: report, count: reportLength))
                let safeReportID = UInt8(clamping: Int(reportID))
                let timestamp = Date()

                if Thread.isMainThread {
                    source.onReport?(safeReportID, bytes, timestamp)
                } else {
                    DispatchQueue.main.async {
                        source.onReport?(safeReportID, bytes, timestamp)
                    }
                }
            },
            context
        )
        status = .listening(deviceName: deviceName, maximumReportSize: maximumReportSize)
    }

    func stop() {
        if let activeDevice, let reportBuffer {
            IOHIDDeviceRegisterInputReportCallback(
                activeDevice,
                reportBuffer,
                reportBufferCapacity,
                nil,
                nil
            )
        }
        activeDevice = nil
        status = .idle
    }

    private func ensureBufferCapacity(_ requestedCapacity: Int) {
        guard requestedCapacity > reportBufferCapacity else { return }
        reportBuffer?.deallocate()
        reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: requestedCapacity)
        reportBuffer?.initialize(repeating: 0, count: requestedCapacity)
        reportBufferCapacity = requestedCapacity
    }

    private static func integerProperty(_ key: String, from device: IOHIDDevice) -> Int {
        (IOHIDDeviceGetProperty(device, key as CFString) as? NSNumber)?.intValue ?? 0
    }

    deinit {
        stop()
        reportBuffer?.deinitialize(count: reportBufferCapacity)
        reportBuffer?.deallocate()
    }
}
