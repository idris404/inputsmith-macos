import AppKit

final class MainViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let scanner: DeviceScanner
    private let simulator = InputSimulator()
    private let rawRecorder = RawReportRecorder()
    private let tableView = NSTableView()
    private let detailStack = NSStackView()
    private let statusLabel = NSTextField(labelWithString: "")
    private var displayedDevices: [ControllerDevice] = []
    private weak var monitorView: ControllerMonitorView?
    private weak var reportInspectorView: RawReportInspectorView?

    init(scanner: DeviceScanner) {
        self.scanner = scanner
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        buildInterface()

        scanner.onDevicesChanged = { [weak self] devices in
            self?.update(devices: devices)
        }
        simulator.onStateChanged = { [weak self] state in
            self?.monitorView?.inputState = state
        }
        simulator.onRawReport = { [weak self] reportID, bytes in
            self?.rawRecorder.receive(reportID: reportID, bytes: bytes)
        }
        simulator.start()
        update(devices: scanner.devices)
    }

    private func buildInterface() {
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitView)

        NSLayoutConstraint.activate([
            splitView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splitView.topAnchor.constraint(equalTo: view.topAnchor),
            splitView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let sidebar = NSVisualEffectView()
        sidebar.material = .sidebar
        sidebar.blendingMode = .behindWindow
        sidebar.translatesAutoresizingMaskIntoConstraints = false
        sidebar.widthAnchor.constraint(equalToConstant: 270).isActive = true

        let sidebarStack = NSStackView()
        sidebarStack.orientation = .vertical
        sidebarStack.alignment = .leading
        sidebarStack.spacing = 12
        sidebarStack.edgeInsets = NSEdgeInsets(top: 22, left: 16, bottom: 16, right: 16)
        sidebarStack.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(sidebarStack)
        NSLayoutConstraint.activate([
            sidebarStack.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor),
            sidebarStack.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            sidebarStack.topAnchor.constraint(equalTo: sidebar.topAnchor),
            sidebarStack.bottomAnchor.constraint(equalTo: sidebar.bottomAnchor)
        ])

        let title = NSTextField(labelWithString: "InputSmith")
        title.font = .systemFont(ofSize: 24, weight: .bold)
        sidebarStack.addArrangedSubview(title)

        let subtitle = NSTextField(wrappingLabelWithString: "Périphériques GameSir")
        subtitle.textColor = .secondaryLabelColor
        sidebarStack.addArrangedSubview(subtitle)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("device"))
        column.title = "Appareils"
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 52
        tableView.selectionHighlightStyle = .regular

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true
        sidebarStack.addArrangedSubview(scrollView)
        scrollView.widthAnchor.constraint(equalTo: sidebarStack.widthAnchor, constant: -32).isActive = true

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        sidebarStack.addArrangedSubview(spacer)

        let simulation = NSButton(checkboxWithTitle: "Mode simulation", target: self, action: #selector(toggleSimulation(_:)))
        simulation.state = scanner.simulationEnabled ? .on : .off
        sidebarStack.addArrangedSubview(simulation)

        let refresh = NSButton(title: "Relancer la détection", target: self, action: #selector(refreshDevices))
        refresh.bezelStyle = .rounded
        sidebarStack.addArrangedSubview(refresh)

        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        sidebarStack.addArrangedSubview(statusLabel)

        let detailScrollView = NSScrollView()
        detailScrollView.hasVerticalScroller = true
        detailScrollView.drawsBackground = false

        let detailView = NSView()
        detailView.translatesAutoresizingMaskIntoConstraints = false
        detailStack.orientation = .vertical
        detailStack.alignment = .leading
        detailStack.spacing = 18
        detailStack.edgeInsets = NSEdgeInsets(top: 42, left: 42, bottom: 42, right: 42)
        detailStack.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(detailStack)
        detailScrollView.documentView = detailView
        NSLayoutConstraint.activate([
            detailView.leadingAnchor.constraint(equalTo: detailScrollView.contentView.leadingAnchor),
            detailView.trailingAnchor.constraint(equalTo: detailScrollView.contentView.trailingAnchor),
            detailView.topAnchor.constraint(equalTo: detailScrollView.contentView.topAnchor),
            detailView.widthAnchor.constraint(equalTo: detailScrollView.contentView.widthAnchor),
            detailView.heightAnchor.constraint(greaterThanOrEqualTo: detailScrollView.contentView.heightAnchor),
            detailStack.leadingAnchor.constraint(equalTo: detailView.leadingAnchor),
            detailStack.trailingAnchor.constraint(equalTo: detailView.trailingAnchor),
            detailStack.topAnchor.constraint(equalTo: detailView.topAnchor),
            detailStack.bottomAnchor.constraint(equalTo: detailView.bottomAnchor)
        ])

        splitView.addArrangedSubview(sidebar)
        splitView.addArrangedSubview(detailScrollView)
    }

    private func update(devices: [ControllerDevice]) {
        displayedDevices = devices
        tableView.reloadData()
        statusLabel.stringValue = devices.isEmpty ? "Aucun appareil détecté" : "Scanner actif · \(devices.count) interface(s)"

        if !devices.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            show(device: devices[0])
        } else {
            showEmptyState()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        displayedDevices.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let device = displayedDevices[row]
        let cell = NSTableCellView()

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        stack.translatesAutoresizingMaskIntoConstraints = false

        let name = NSTextField(labelWithString: device.productName)
        name.font = .systemFont(ofSize: 13, weight: .semibold)
        let identifier = NSTextField(labelWithString: "\(device.vendorIDHex):\(device.productIDHex)")
        identifier.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        identifier.textColor = .secondaryLabelColor
        stack.addArrangedSubview(name)
        stack.addArrangedSubview(identifier)
        cell.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
            stack.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard displayedDevices.indices.contains(row) else { return }
        show(device: displayedDevices[row])
    }

    private func show(device: ControllerDevice) {
        clearDetails()

        let icon = NSImageView(image: NSImage(systemSymbolName: "gamecontroller.fill", accessibilityDescription: nil) ?? NSImage())
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 50, weight: .medium)
        icon.contentTintColor = .systemBlue
        icon.setFrameSize(NSSize(width: 72, height: 72))
        detailStack.addArrangedSubview(icon)

        let title = NSTextField(labelWithString: device.productName)
        title.font = .systemFont(ofSize: 30, weight: .bold)
        detailStack.addArrangedSubview(title)

        let state = device.isSimulated ? "SIMULATION · LECTURE SEULE" : "CONNECTÉE · LECTURE SEULE"
        let badge = NSTextField(labelWithString: state)
        badge.font = .systemFont(ofSize: 11, weight: .semibold)
        badge.textColor = device.isSimulated ? .systemOrange : .systemGreen
        detailStack.addArrangedSubview(badge)

        if let catalogName = device.catalogName {
            let catalog = NSTextField(wrappingLabelWithString: catalogName)
            catalog.textColor = .secondaryLabelColor
            detailStack.addArrangedSubview(catalog)
        }

        detailStack.addArrangedSubview(makeSectionTitle("Identité USB/HID"))
        let rows = [
            ["Vendor ID", device.vendorIDHex],
            ["Product ID", device.productIDHex],
            ["Transport", device.transport],
            ["Usage HID", "\(ControllerDevice.hex(device.usagePage)) : \(ControllerDevice.hex(device.usage))"],
            ["Numéro de série", device.serialNumber ?? "Non exposé"]
        ]
        let grid = NSGridView(views: rows.map { row in
            let label = NSTextField(labelWithString: row[0])
            label.textColor = .secondaryLabelColor
            let value = NSTextField(labelWithString: row[1])
            value.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            value.isSelectable = true
            return [label, value]
        })
        grid.rowSpacing = 10
        grid.columnSpacing = 24
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).xPlacement = .leading
        detailStack.addArrangedSubview(grid)

        detailStack.addArrangedSubview(makeSectionTitle("Entrées en direct"))
        let monitor = ControllerMonitorView()
        monitor.translatesAutoresizingMaskIntoConstraints = false
        monitor.heightAnchor.constraint(equalToConstant: 305).isActive = true
        detailStack.addArrangedSubview(monitor)
        monitor.widthAnchor.constraint(equalTo: detailStack.widthAnchor, constant: -84).isActive = true
        monitorView = monitor

        detailStack.addArrangedSubview(makeSectionTitle("Rapports bruts"))
        let inspector = RawReportInspectorView(recorder: rawRecorder, sourceName: device.productName)
        inspector.translatesAutoresizingMaskIntoConstraints = false
        inspector.heightAnchor.constraint(equalToConstant: 330).isActive = true
        detailStack.addArrangedSubview(inspector)
        inspector.widthAnchor.constraint(equalTo: detailStack.widthAnchor, constant: -84).isActive = true
        reportInspectorView = inspector

        detailStack.addArrangedSubview(makeSectionTitle("Prochaine étape"))
        let next = NSTextField(wrappingLabelWithString: "À la réception de la manette, remplacer la source simulée par le callback IOHID réel sans changer l’inspecteur.")
        next.textColor = .secondaryLabelColor
        detailStack.addArrangedSubview(next)
    }

    private func showEmptyState() {
        clearDetails()
        let icon = NSImageView(image: NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: nil) ?? NSImage())
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 52, weight: .regular)
        icon.contentTintColor = .secondaryLabelColor
        detailStack.addArrangedSubview(icon)
        let title = NSTextField(labelWithString: "Aucune GameSir détectée")
        title.font = .systemFont(ofSize: 26, weight: .bold)
        detailStack.addArrangedSubview(title)
        let message = NSTextField(wrappingLabelWithString: "Branchez la manette en USB ou activez le mode simulation.")
        message.textColor = .secondaryLabelColor
        detailStack.addArrangedSubview(message)
    }

    private func clearDetails() {
        monitorView = nil
        reportInspectorView = nil
        detailStack.arrangedSubviews.forEach { view in
            detailStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func makeSectionTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }

    @objc private func toggleSimulation(_ sender: NSButton) {
        scanner.simulationEnabled = sender.state == .on
    }

    @objc private func refreshDevices() {
        scanner.refresh()
    }

    deinit {
        simulator.stop()
    }
}
