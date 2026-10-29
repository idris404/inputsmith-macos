import Foundation

struct ControllerDevice: Identifiable, Hashable {
    let id: String
    let productName: String
    let vendorID: Int
    let productID: Int
    let transport: String
    let usagePage: Int
    let usage: Int
    let serialNumber: String?
    let isSimulated: Bool

    var vendorIDHex: String { Self.hex(vendorID) }
    var productIDHex: String { Self.hex(productID) }

    var catalogName: String? {
        GameSirCatalog.name(for: productID)
    }

    static func hex(_ value: Int) -> String {
        String(format: "0x%04X", value)
    }

    static let simulatedG7Pro = ControllerDevice(
        id: "simulated-g7-pro",
        productName: "GameSir G7 Pro",
        vendorID: GameSirCatalog.vendorID,
        productID: 0x1003,
        transport: "USB (simulation)",
        usagePage: 0x01,
        usage: 0x05,
        serialNumber: nil,
        isSimulated: true
    )
}

enum GameSirCatalog {
    static let vendorID = 0x3537

    private static let knownProducts: [Int: String] = [
        0x1003: "G7 Pro White — interface filaire rapportée",
        0x1004: "G7 Pro White — station/récepteur rapporté",
        0x100A: "G7 Pro — identité de transition rapportée",
        0x1022: "G7 Pro — mode natif/GIP rapporté",
        0x109B: "G7 Pro Shadow Ember — filaire rapporté",
        0x109C: "G7 Pro Shadow Ember — récepteur rapporté",
        0x10BA: "G7 Pro Amazon — filaire rapporté",
        0x10BB: "G7 Pro Amazon — récepteur rapporté"
    ]

    static func name(for productID: Int) -> String? {
        knownProducts[productID]
    }
}
