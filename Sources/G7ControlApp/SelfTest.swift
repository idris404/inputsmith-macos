import Foundation

enum SelfTest {
    static func run() {
        precondition(ControllerDevice.hex(0x3537) == "0x3537")
        precondition(ControllerDevice.hex(0x0A) == "0x000A")
        precondition(GameSirCatalog.name(for: 0x1003) != nil)
        precondition(GameSirCatalog.name(for: 0xFFFF) == nil)
        precondition(StickPosition(x: 4, y: -3) == StickPosition(x: 1, y: -1))
        precondition(ControllerInputState.neutral.pressedButtons.isEmpty)
        let neutralReport = InputSimulator.encodeReport(.neutral)
        precondition(neutralReport.count == 24)
        precondition(neutralReport[0] == 0 && neutralReport[1] == 0)
        precondition(RawReportRecorder.changedIndices(previous: [0, 1, 2], current: [0, 9, 2]) == [1])
        let recorder = RawReportRecorder(capacity: 2)
        recorder.receive(reportID: 0x12, bytes: [0, 1])
        recorder.receive(reportID: 0x12, bytes: [0, 2])
        recorder.receive(reportID: 0x12, bytes: [0, 3])
        precondition(recorder.reports.count == 2)
        precondition(recorder.reports.last?.changedIndices == [1])
        print("SELF_TEST_OK")
    }
}
