import AppKit
import UniformTypeIdentifiers

final class RawReportInspectorView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    private let recorder: RawReportRecorder
    private let sourceName: String
    private let tableView = NSTableView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let pauseButton = NSButton()
    private var refreshScheduled = false

    init(recorder: RawReportRecorder, sourceName: String) {
        self.recorder = recorder
        self.sourceName = sourceName
        super.init(frame: .zero)
        buildInterface()
        recorder.onReportsChanged = { [weak self] in
            self?.scheduleRefresh()
        }
        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildInterface() {
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor),
            root.trailingAnchor.constraint(equalTo: trailingAnchor),
            root.topAnchor.constraint(equalTo: topAnchor),
            root.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let toolbar = NSStackView()
        toolbar.orientation = .horizontal
        toolbar.alignment = .centerY
        toolbar.spacing = 8

        pauseButton.title = "Pause"
        pauseButton.target = self
        pauseButton.action = #selector(togglePause)
        pauseButton.bezelStyle = .rounded
        toolbar.addArrangedSubview(pauseButton)

        let clearButton = NSButton(title: "Effacer", target: self, action: #selector(clearReports))
        clearButton.bezelStyle = .rounded
        toolbar.addArrangedSubview(clearButton)

        let exportButton = NSButton(title: "Exporter JSON…", target: self, action: #selector(exportReports))
        exportButton.bezelStyle = .rounded
        toolbar.addArrangedSubview(exportButton)

        let toolbarSpacer = NSView()
        toolbarSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        toolbar.addArrangedSubview(toolbarSpacer)

        statusLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor = .secondaryLabelColor
        toolbar.addArrangedSubview(statusLabel)
        root.addArrangedSubview(toolbar)
        toolbar.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -24).isActive = true

        addColumn(identifier: "sequence", title: "#", width: 58)
        addColumn(identifier: "time", title: "Temps", width: 96)
        addColumn(identifier: "reportID", title: "ID", width: 58)
        addColumn(identifier: "length", title: "Taille", width: 58)
        addColumn(identifier: "payload", title: "Octets — orange = modifié", width: 520)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 23
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = true

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        root.addArrangedSubview(scrollView)
        scrollView.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -24).isActive = true
        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 245).isActive = true
    }

    private func addColumn(identifier: String, title: String, width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier))
        column.title = title
        column.width = width
        column.minWidth = min(width, 44)
        tableView.addTableColumn(column)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        recorder.reports.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard recorder.reports.indices.contains(row), let identifier = tableColumn?.identifier.rawValue else { return nil }
        let report = recorder.reports[row]
        let field = NSTextField(labelWithString: "")
        field.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        field.lineBreakMode = .byClipping

        switch identifier {
        case "sequence":
            field.stringValue = String(report.sequence)
        case "time":
            field.stringValue = Self.timestampFormatter.string(from: report.timestamp)
        case "reportID":
            field.stringValue = report.reportIDHex
        case "length":
            field.stringValue = String(report.bytes.count)
        case "payload":
            field.attributedStringValue = attributedPayload(for: report)
        default:
            break
        }
        return field
    }

    private func attributedPayload(for report: RawInputReport) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let changed = Set(report.changedIndices)

        for (index, byte) in report.bytes.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: " "))
            }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: changed.contains(index) ? .bold : .regular),
                .foregroundColor: changed.contains(index) ? NSColor.systemOrange : NSColor.secondaryLabelColor
            ]
            result.append(NSAttributedString(string: String(format: "%02X", byte), attributes: attributes))
        }
        return result
    }

    private func scheduleRefresh() {
        guard !refreshScheduled else { return }
        refreshScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.refreshScheduled = false
            self?.refresh()
        }
    }

    private func refresh() {
        tableView.reloadData()
        pauseButton.title = recorder.isPaused ? "Reprendre" : "Pause"

        let frequency = recorder.observedFrequency.map { String(format: "%.1f Hz", $0) } ?? "— Hz"
        statusLabel.stringValue = "\(recorder.reports.count)/\(recorder.capacity) rapports · \(frequency)"

        if !recorder.reports.isEmpty {
            tableView.scrollRowToVisible(recorder.reports.count - 1)
        }
    }

    @objc private func togglePause() {
        recorder.togglePaused()
    }

    @objc private func clearReports() {
        recorder.clear()
    }

    @objc private func exportReports() {
        guard !recorder.reports.isEmpty else {
            NSSound.beep()
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "inputsmith-capture-\(Self.fileDateFormatter.string(from: Date())).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try recorder.export(to: url, source: sourceName)
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "Impossible d’exporter la capture"
            alert.runModal()
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()
}
