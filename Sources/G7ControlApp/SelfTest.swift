import Foundation

enum SelfTest {
    static func run() {
        precondition(ControllerDevice.hex(0x3537) == "0x3537")
        precondition(ControllerDevice.hex(0x0A) == "0x000A")
        precondition(GameSirCatalog.name(for: 0x1003) != nil)
        precondition(GameSirCatalog.name(for: 0xFFFF) == nil)
        precondition(StickPosition(x: 4, y: -3) == StickPosition(x: 1, y: -1))
        precondition(ControllerInputState.neutral.pressedButtons.isEmpty)
        print("SELF_TEST_OK")
    }
}
