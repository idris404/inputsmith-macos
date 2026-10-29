import Foundation
import IOKit.hid

final class DeviceScanner {
    private(set) var devices: [ControllerDevice] = []
    private(set) var lastScan = Date()
    var onDevicesChanged: (([ControllerDevice]) -> Void)?
    var simulationEnabled = true {
        didSet { refresh() }
    }

    private let manager: IOHIDManager
    private var hidDevicesByID: [String: IOHIDDevice] = [:]

    init() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        let matching: [String: Any] = [
            kIOHIDVendorIDKey as String: GameSirCatalog.vendorID
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, _ in
            guard let context else { return }
            let scanner = Unmanaged<DeviceScanner>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async { scanner.refresh() }
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, _ in
            guard let context else { return }
            let scanner = Unmanaged<DeviceScanner>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async { scanner.refresh() }
        }, context)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        refresh()
    }

    deinit {
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    func refresh() {
        let hidDevices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
        var deviceMap: [String: IOHIDDevice] = [:]
        let detected = hidDevices
            .map { hidDevice in
                let model = Self.makeDevice(hidDevice)
                deviceMap[model.id] = hidDevice
                return model
            }
            .sorted {
                if $0.productID == $1.productID { return $0.usage < $1.usage }
                return $0.productID < $1.productID
            }

        hidDevicesByID = deviceMap
        devices = simulationEnabled && detected.isEmpty
            ? [.simulatedG7Pro]
            : detected
        lastScan = Date()
        onDevicesChanged?(devices)
    }

    func hidDevice(for id: ControllerDevice.ID) -> IOHIDDevice? {
        hidDevicesByID[id]
    }

    private static func makeDevice(_ device: IOHIDDevice) -> ControllerDevice {
        let vendorID = integerProperty(kIOHIDVendorIDKey, from: device)
        let productID = integerProperty(kIOHIDProductIDKey, from: device)
        let locationID = integerProperty(kIOHIDLocationIDKey, from: device)
        let usagePage = integerProperty(kIOHIDPrimaryUsagePageKey, from: device)
        let usage = integerProperty(kIOHIDPrimaryUsageKey, from: device)
        let name = stringProperty(kIOHIDProductKey, from: device) ?? "Périphérique GameSir"
        let transport = stringProperty(kIOHIDTransportKey, from: device) ?? "Inconnu"
        let serial = stringProperty(kIOHIDSerialNumberKey, from: device)
        let id = "\(vendorID)-\(productID)-\(locationID)-\(usagePage)-\(usage)"

        return ControllerDevice(
            id: id,
            productName: name,
            vendorID: vendorID,
            productID: productID,
            transport: transport,
            usagePage: usagePage,
            usage: usage,
            serialNumber: serial,
            isSimulated: false
        )
    }

    private static func integerProperty(_ key: String, from device: IOHIDDevice) -> Int {
        (IOHIDDeviceGetProperty(device, key as CFString) as? NSNumber)?.intValue ?? 0
    }

    private static func stringProperty(_ key: String, from device: IOHIDDevice) -> String? {
        IOHIDDeviceGetProperty(device, key as CFString) as? String
    }
}
