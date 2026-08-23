import AppKit
import Foundation

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow!
    private var statusLabel: NSTextField!
    private var detailLabel: NSTextField!
    private var progressIndicator: NSProgressIndicator!
    private var closeButton: NSButton!
    private var installer: Process?
    private var timer: Timer?
    private var logHandle: FileHandle?
    private var statusURL: URL!
    private var logURL: URL!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildWindow()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        startInstallation()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        if let installer, installer.isRunning {
            installer.terminate()
        }
        try? logHandle?.close()
    }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 350),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Installa Sky Go Fixed"
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self

        let iconView = NSImageView()
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 92).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 92).isActive = true
        if let iconURL = Bundle.main.url(forResource: "SkyGo", withExtension: "icns") {
            iconView.image = NSImage(contentsOf: iconURL)
        }

        let title = NSTextField(labelWithString: "Sky Go Fixed")
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.alignment = .center

        let subtitle = NSTextField(labelWithString: "Compatibilità per Sky Go su macOS 26")
        subtitle.font = .systemFont(ofSize: 14, weight: .regular)
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .center

        statusLabel = NSTextField(labelWithString: "Preparazione dell’installazione…")
        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statusLabel.alignment = .center
        statusLabel.maximumNumberOfLines = 2

        detailLabel = NSTextField(labelWithString: "Non chiudere questa finestra. Non verranno copiati account o password.")
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.alignment = .center
        detailLabel.maximumNumberOfLines = 2

        progressIndicator = NSProgressIndicator()
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 1
        progressIndicator.doubleValue = 0.02
        progressIndicator.controlSize = .large

        closeButton = NSButton(title: "Chiudi", target: self, action: #selector(closeInstaller))
        closeButton.bezelStyle = .rounded
        closeButton.isHidden = true

        let stack = NSStackView(views: [
            iconView,
            title,
            subtitle,
            statusLabel,
            progressIndicator,
            detailLabel,
            closeButton
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.setCustomSpacing(5, after: title)
        stack.setCustomSpacing(22, after: subtitle)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(stack)
        window.contentView = content

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 42),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -42),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 26),
            progressIndicator.widthAnchor.constraint(equalTo: stack.widthAnchor),
            detailLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            statusLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    private func startInstallation() {
        guard let script = Bundle.main.url(forResource: "install", withExtension: "sh") else {
            showFailure("Lo script di installazione non è presente.")
            return
        }

        let fileManager = FileManager.default
        let cacheFolder = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/SkyGoFixedInstaller", isDirectory: true)
        let logsFolder = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Sky Go Fixed", isDirectory: true)
        statusURL = cacheFolder.appendingPathComponent("status.txt")
        logURL = logsFolder.appendingPathComponent("installer.log")

        do {
            try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: logsFolder, withIntermediateDirectories: true)
            try Data().write(to: statusURL, options: .atomic)
            try Data().write(to: logURL, options: .atomic)
            logHandle = try FileHandle(forWritingTo: logURL)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = [script.path]
            var environment = ProcessInfo.processInfo.environment
            environment["SKYGO_FIXED_STATUS_FILE"] = statusURL.path
            process.environment = environment
            process.standardOutput = logHandle
            process.standardError = logHandle
            process.terminationHandler = { process in
                let status = process.terminationStatus
                Task { @MainActor in
                    (NSApp.delegate as? AppDelegate)?.installationFinished(status: status)
                }
            }

            try process.run()
            installer = process
            timer = Timer.scheduledTimer(
                timeInterval: 0.25,
                target: self,
                selector: #selector(pollStatus),
                userInfo: nil,
                repeats: true
            )
        } catch {
            showFailure(error.localizedDescription)
        }
    }

    @objc private func pollStatus() {
        guard let statusURL,
              let text = try? String(contentsOf: statusURL, encoding: .utf8) else { return }
        let parts = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return }
        if let progress = Double(parts[0]) {
            progressIndicator.doubleValue = min(max(progress, 0), 1)
        }
        statusLabel.stringValue = String(parts[1])
    }

    private func installationFinished(status: Int32) {
        timer?.invalidate()
        timer = nil
        try? logHandle?.close()
        logHandle = nil

        if status == 0 {
            progressIndicator.doubleValue = 1
            statusLabel.stringValue = "Installazione completata"
            detailLabel.stringValue = "Sky Go Fixed è nella cartella Applicazioni e sta per aprirsi."
            closeButton.isHidden = false

            let destination = ProcessInfo.processInfo.environment["SKYGO_FIXED_DESTINATION"]
                ?? "/Applications/Sky Go Fixed.app"
            if ProcessInfo.processInfo.environment["SKYGO_FIXED_NO_OPEN"] != "1" {
                NSWorkspace.shared.open(URL(fileURLWithPath: destination))
            }
        } else {
            showFailure("Consulta il log in \(logURL.path)")
        }
    }

    private func showFailure(_ detail: String) {
        timer?.invalidate()
        progressIndicator.doubleValue = 0
        statusLabel.stringValue = "Installazione non riuscita"
        detailLabel.stringValue = detail
        closeButton.isHidden = false
    }

    @objc private func closeInstaller() {
        NSApp.terminate(nil)
    }
}

let application = NSApplication.shared
private let delegate = AppDelegate()
application.delegate = delegate
application.run()
