import AppKit

final class ControllerMonitorView: NSView {
    var inputState = ControllerInputState.neutral {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let panel = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 18, yRadius: 18)
        NSColor.controlBackgroundColor.setFill()
        panel.fill()
        NSColor.separatorColor.setStroke()
        panel.lineWidth = 1
        panel.stroke()

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ]
        NSAttributedString(string: "Moniteur d’entrées · 60 Hz simulés", attributes: headerAttributes)
            .draw(at: NSPoint(x: 18, y: 15))

        let controllerRect = NSRect(
            x: bounds.midX - 205,
            y: 55,
            width: 410,
            height: 205
        )
        drawController(in: controllerRect)
        drawTelemetry(at: NSPoint(x: 18, y: bounds.height - 42))
    }

    private func drawController(in rect: NSRect) {
        let body = NSBezierPath()
        body.move(to: NSPoint(x: rect.minX + 92, y: rect.minY + 28))
        body.curve(to: NSPoint(x: rect.minX + 28, y: rect.minY + 170),
                   controlPoint1: NSPoint(x: rect.minX + 40, y: rect.minY + 38),
                   controlPoint2: NSPoint(x: rect.minX + 5, y: rect.minY + 118))
        body.curve(to: NSPoint(x: rect.minX + 112, y: rect.minY + 144),
                   controlPoint1: NSPoint(x: rect.minX + 50, y: rect.minY + 210),
                   controlPoint2: NSPoint(x: rect.minX + 82, y: rect.minY + 158))
        body.curve(to: NSPoint(x: rect.maxX - 112, y: rect.minY + 144),
                   controlPoint1: NSPoint(x: rect.midX - 45, y: rect.minY + 128),
                   controlPoint2: NSPoint(x: rect.midX + 45, y: rect.minY + 128))
        body.curve(to: NSPoint(x: rect.maxX - 28, y: rect.minY + 170),
                   controlPoint1: NSPoint(x: rect.maxX - 82, y: rect.minY + 158),
                   controlPoint2: NSPoint(x: rect.maxX - 50, y: rect.minY + 210))
        body.curve(to: NSPoint(x: rect.maxX - 92, y: rect.minY + 28),
                   controlPoint1: NSPoint(x: rect.maxX - 5, y: rect.minY + 118),
                   controlPoint2: NSPoint(x: rect.maxX - 40, y: rect.minY + 38))
        body.curve(to: NSPoint(x: rect.minX + 92, y: rect.minY + 28),
                   controlPoint1: NSPoint(x: rect.midX + 78, y: rect.minY + 7),
                   controlPoint2: NSPoint(x: rect.midX - 78, y: rect.minY + 7))
        body.close()

        NSColor(deviceWhite: 0.23, alpha: 1).setFill()
        body.fill()
        NSColor(deviceWhite: 0.42, alpha: 1).setStroke()
        body.lineWidth = 2
        body.stroke()

        drawTrigger(value: inputState.leftTrigger, rect: NSRect(x: rect.minX + 75, y: rect.minY + 9, width: 92, height: 9))
        drawTrigger(value: inputState.rightTrigger, rect: NSRect(x: rect.maxX - 167, y: rect.minY + 9, width: 92, height: 9))

        drawStick(inputState.leftStick, center: NSPoint(x: rect.minX + 128, y: rect.minY + 83))
        drawStick(inputState.rightStick, center: NSPoint(x: rect.midX + 52, y: rect.minY + 125))
        drawDPad(center: NSPoint(x: rect.minX + 110, y: rect.minY + 137))

        let faceCenter = NSPoint(x: rect.maxX - 116, y: rect.minY + 80)
        drawButton(.y, center: NSPoint(x: faceCenter.x, y: faceCenter.y - 25), color: .systemYellow)
        drawButton(.a, center: NSPoint(x: faceCenter.x, y: faceCenter.y + 25), color: .systemGreen)
        drawButton(.x, center: NSPoint(x: faceCenter.x - 25, y: faceCenter.y), color: .systemBlue)
        drawButton(.b, center: NSPoint(x: faceCenter.x + 25, y: faceCenter.y), color: .systemRed)

        drawSmallButton(.view, center: NSPoint(x: rect.midX - 30, y: rect.minY + 72))
        drawSmallButton(.menu, center: NSPoint(x: rect.midX + 30, y: rect.minY + 72))
    }

    private func drawStick(_ position: StickPosition, center: NSPoint) {
        let base = NSBezierPath(ovalIn: NSRect(x: center.x - 27, y: center.y - 27, width: 54, height: 54))
        NSColor(deviceWhite: 0.12, alpha: 1).setFill()
        base.fill()

        let offset = NSPoint(x: position.x * 15, y: -position.y * 15)
        let capRect = NSRect(x: center.x + offset.x - 16, y: center.y + offset.y - 16, width: 32, height: 32)
        let cap = NSBezierPath(ovalIn: capRect)
        NSColor(deviceWhite: 0.56, alpha: 1).setFill()
        cap.fill()
        NSColor.systemBlue.setStroke()
        cap.lineWidth = 2
        cap.stroke()
    }

    private func drawButton(_ button: ControllerButton, center: NSPoint, color: NSColor) {
        let pressed = inputState.pressedButtons.contains(button)
        let circle = NSBezierPath(ovalIn: NSRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24))
        (pressed ? color : color.withAlphaComponent(0.25)).setFill()
        circle.fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: pressed ? NSColor.white : color
        ]
        let string = NSAttributedString(string: button.rawValue, attributes: attributes)
        let size = string.size()
        string.draw(at: NSPoint(x: center.x - size.width / 2, y: center.y - size.height / 2))
    }

    private func drawSmallButton(_ button: ControllerButton, center: NSPoint) {
        let pressed = inputState.pressedButtons.contains(button)
        let path = NSBezierPath(roundedRect: NSRect(x: center.x - 12, y: center.y - 6, width: 24, height: 12), xRadius: 6, yRadius: 6)
        (pressed ? NSColor.systemBlue : NSColor(deviceWhite: 0.55, alpha: 1)).setFill()
        path.fill()
    }

    private func drawDPad(center: NSPoint) {
        let vertical = NSBezierPath(roundedRect: NSRect(x: center.x - 7, y: center.y - 25, width: 14, height: 50), xRadius: 3, yRadius: 3)
        let horizontal = NSBezierPath(roundedRect: NSRect(x: center.x - 25, y: center.y - 7, width: 50, height: 14), xRadius: 3, yRadius: 3)
        NSColor(deviceWhite: 0.12, alpha: 1).setFill()
        vertical.fill()
        horizontal.fill()
    }

    private func drawTrigger(value: Double, rect: NSRect) {
        let track = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
        NSColor(deviceWhite: 0.12, alpha: 1).setFill()
        track.fill()

        let fillRect = NSRect(x: rect.minX, y: rect.minY, width: rect.width * min(max(value, 0), 1), height: rect.height)
        let fill = NSBezierPath(roundedRect: fillRect, xRadius: rect.height / 2, yRadius: rect.height / 2)
        NSColor.systemOrange.setFill()
        fill.fill()
    }

    private func drawTelemetry(at point: NSPoint) {
        let text = String(
            format: "LS  x %+.2f  y %+.2f     RS  x %+.2f  y %+.2f     LT %.2f  RT %.2f     Gyro  P %+.1f°  R %+.1f°  Y %+.1f°",
            inputState.leftStick.x,
            inputState.leftStick.y,
            inputState.rightStick.x,
            inputState.rightStick.y,
            inputState.leftTrigger,
            inputState.rightTrigger,
            inputState.gyroscope.pitch,
            inputState.gyroscope.roll,
            inputState.gyroscope.yaw
        )
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        NSAttributedString(string: text, attributes: attributes).draw(at: point)
    }
}
