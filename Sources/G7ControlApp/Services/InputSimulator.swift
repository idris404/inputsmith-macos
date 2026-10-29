import Foundation

final class InputSimulator {
    var onStateChanged: ((ControllerInputState) -> Void)?

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
    }

    deinit {
        stop()
    }
}
