import Foundation

struct StickPosition: Equatable {
    var x: Double
    var y: Double

    static let centered = StickPosition(x: 0, y: 0)

    init(x: Double, y: Double) {
        self.x = min(max(x, -1), 1)
        self.y = min(max(y, -1), 1)
    }
}

enum ControllerButton: String, CaseIterable, Hashable {
    case a = "A"
    case b = "B"
    case x = "X"
    case y = "Y"
    case leftBumper = "LB"
    case rightBumper = "RB"
    case menu = "Menu"
    case view = "View"
    case leftBack = "L4"
    case rightBack = "R4"
}

struct GyroscopeState: Equatable {
    var pitch: Double
    var roll: Double
    var yaw: Double

    static let zero = GyroscopeState(pitch: 0, roll: 0, yaw: 0)
}

struct ControllerInputState: Equatable {
    var leftStick: StickPosition
    var rightStick: StickPosition
    var leftTrigger: Double
    var rightTrigger: Double
    var pressedButtons: Set<ControllerButton>
    var gyroscope: GyroscopeState

    static let neutral = ControllerInputState(
        leftStick: .centered,
        rightStick: .centered,
        leftTrigger: 0,
        rightTrigger: 0,
        pressedButtons: [],
        gyroscope: .zero
    )
}
