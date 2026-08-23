import AppKit
import Foundation

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var runtime: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        launchRuntime()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        launchRuntime()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.launchRuntime()
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        if let runtime, !runtime.isTerminated {
            runtime.terminate()
        }
    }

    private func launchRuntime() {
        if let runtime, !runtime.isTerminated {
            activateRuntime()
            return
        }
        runtime = nil

        guard let resources = Bundle.main.resourceURL else {
            fail("Le risorse interne dell’app non sono disponibili.")
            return
        }

        let runtimeApp = resources.appendingPathComponent("Sky Go Fixed Runtime.app", isDirectory: true)
        let executable = runtimeApp.appendingPathComponent("Contents/MacOS/Electron")
        let bundledHook = resources.appendingPathComponent("skygo-compat.js")

        guard FileManager.default.isExecutableFile(atPath: executable.path),
              FileManager.default.fileExists(atPath: bundledHook.path) else {
            fail("Il motore Sky Go Fixed è incompleto o danneggiato.")
            return
        }

        guard let hook = installHook(from: bundledHook) else {
            fail("Il modulo di compatibilità non può essere preparato.")
            return
        }

        var environment = ProcessInfo.processInfo.environment
        environment["MallocNanoZone"] = "0"
        environment["NODE_OPTIONS"] = "--require=\(hook.path)"

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = false
        configuration.environment = environment

        NSWorkspace.shared.openApplication(at: runtimeApp, configuration: configuration) {
            application, error in
            Task { @MainActor in
                (NSApp.delegate as? AppDelegate)?.runtimeDidLaunch(
                    application: application,
                    error: error
                )
            }
        }
    }

    private func activateRuntime() {
        guard let runtime, !runtime.isTerminated else { return }
        runtime.activate(options: [.activateAllWindows])
    }

    private func runtimeDidLaunch(
        application: NSRunningApplication?,
        error: Error?
    ) {
        guard let application else {
            fail("Il motore Sky Go non è partito: \(error?.localizedDescription ?? "errore sconosciuto")")
            return
        }

        runtime = application
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(runtimeDidTerminate),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
        activateRuntime()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.activateRuntime()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            self?.activateRuntime()
        }
    }

    @objc private func runtimeDidTerminate(_ notification: Notification) {
        guard let terminated = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication,
              terminated.processIdentifier == runtime?.processIdentifier else { return }
        runtime = nil
    }

    private func installHook(from bundledHook: URL) -> URL? {
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/SkyGoFixed", isDirectory: true)
        let installedHook = folder.appendingPathComponent("skygo-compat.js")

        do {
            try FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )
            let data = try Data(contentsOf: bundledHook)
            try data.write(to: installedHook, options: .atomic)
            return installedHook
        } catch {
            return nil
        }
    }

    private func fail(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Sky Go Fixed non può avviarsi"
        alert.informativeText = message
        alert.addButton(withTitle: "Chiudi")
        alert.runModal()
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
