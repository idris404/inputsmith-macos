import Foundation

final class InputSimulator {
    var onStateChanged: ((ControllerInputState) -> Void)?
    var onRawReport: ((UInt8, [UInt8]) -> Void)?

    private var timer: Timer?
    private var phase = 0.0

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        phase += 0.025

        var buttons = Set<ControllerButton>()
        if sin(phase * 1.8) > 0.72 { buttons.insert(.a) }
        if cos(phase * 1.35) > 0.78 { buttons.insert(.b) }
        if sin(phase * 0.7) < -0.82 { buttons.insert(.x) }
        if cos(phase * 0.55) < -0.9 { buttons.insert(.rightBack) }

        let state = ControllerInputState(
            leftStick: StickPosition(x: sin(phase), y: cos(phase * 0.82)),
            rightStick: StickPosition(x: cos(phase * 0.63), y: sin(phase * 1.17)),
            leftTrigger: (sin(phase * 0.58) + 1) / 2,
            rightTrigger: (cos(phase * 0.74) + 1) / 2,
            pressedButtons: buttons,
            gyroscope: GyroscopeState(
                pitch: sin(phase * 0.45) * 32,
                roll: cos(phase * 0.38) * 24,
                yaw: sin(phase * 0.29) * 48
            )
        )
        onStateChanged?(state)
        onRawReport?(0x12, Self.encodeReport(state))
    }

    static func encodeReport(_ state: ControllerInputState) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 24)

        var buttonMask: UInt16 = 0
        for (index, button) in ControllerButton.allCases.enumerated() where state.pressedButtons.contains(button) {
            buttonMask |= UInt16(1 << index)
        }
        write(buttonMask, to: &bytes, at: 0)
        write(axisValue(state.leftStick.x), to: &bytes, at: 2)
        write(axisValue(state.leftStick.y), to: &bytes, at: 4)
        write(axisValue(state.rightStick.x), to: &bytes, at: 6)
        write(axisValue(state.rightStick.y), to: &bytes, at: 8)
        write(triggerValue(state.leftTrigger), to: &bytes, at: 10)
        write(triggerValue(state.rightTrigger), to: &bytes, at: 12)
        write(Int16(clamping: Int(state.gyroscope.pitch * 100)), to: &bytes, at: 14)
        write(Int16(clamping: Int(state.gyroscope.roll * 100)), to: &bytes, at: 16)
        write(Int16(clamping: Int(state.gyroscope.yaw * 100)), to: &bytes, at: 18)
        bytes[20] = 82 // batterie simulée
        bytes[21] = 1  // connexion simulée
        return bytes
    }

    private static func axisValue(_ value: Double) -> Int16 {
        Int16(clamping: Int(min(max(value, -1), 1) * Double(Int16.max)))
    }

    private static func triggerValue(_ value: Double) -> UInt16 {
        UInt16(clamping: Int(min(max(value, 0), 1) * Double(UInt16.max)))
    }

    private static func write<T: FixedWidthInteger>(_ value: T, to bytes: inout [UInt8], at index: Int) {
        let littleEndian = value.littleEndian
        withUnsafeBytes(of: littleEndian) { rawBytes in
            for offset in rawBytes.indices where index + offset < bytes.count {
                bytes[index + offset] = rawBytes[offset]
            }
        }
    }

    deinit {
        stop()
    }
}
