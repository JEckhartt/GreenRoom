import UIKit
import UniformTypeIdentifiers
import Capacitor

// Automatic backup: you pick a folder once (Files, iCloud Drive, On My iPhone…); the app remembers it with a
// bookmark and writes backups there by itself. Only files it made itself (Green-Room-autobackup-…) are ever
// deleted, to keep the number you chose.
@objc(BackupFolderPlugin)
public class BackupFolderPlugin: CAPPlugin, CAPBridgedPlugin, UIDocumentPickerDelegate, UIAdaptivePresentationControllerDelegate {
    public let identifier = "BackupFolderPlugin"
    public let jsName = "BackupFolder"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "pick", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "status", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "write", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "forget", returnType: CAPPluginReturnPromise)
    ]
    private let key = "greenroom.backupFolder"
    private let prefix = "Green-Room-autobackup-"
    private var pickCall: CAPPluginCall?
    private var picker: UIDocumentPickerViewController?

    // Every step is written to Settings → Debug, to see where choosing a folder stops
    private func trace(_ text: String) { notifyListeners("bklog", data: ["msg": text]) }

    // Opens Files straight away to choose the folder
    @objc func pick(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.pickCall = call
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
            picker.delegate = self
            picker.allowsMultipleSelection = false
            picker.shouldShowFileExtensions = true
            self.picker = picker // held on to until it's closed
            var top = self.bridge?.viewController
            while let shown = top?.presentedViewController { top = shown }
            guard let host = top else { self.trace("Backup folder: no screen to show the picker on"); return call.reject("Could not open Files") }
            self.trace("Backup folder: picker opened from \(type(of: host))")
            host.present(picker, animated: true) {
                picker.presentationController?.delegate = self
                self.trace("Backup folder: picker shown")
            }
        }
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        trace("Backup folder: Open tapped, \(urls.count) folder(s): \(urls.map { $0.lastPathComponent })")
        picked(controller, urls.first)
    }
    // older iOS name of the same message
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        trace("Backup folder: Open tapped (single): \(url.lastPathComponent)")
        picked(controller, url)
    }
    private func picked(_ controller: UIDocumentPickerViewController, _ url: URL?) {
        picker = nil
        if controller.presentingViewController != nil { controller.dismiss(animated: true) }
        guard let call = pickCall, let url = url else { return trace("Backup folder: nothing waiting for the folder") }
        pickCall = nil
        let ok = url.startAccessingSecurityScopedResource()
        trace("Backup folder: access \(ok ? "granted" : "not granted") for \(url.path)")
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(data, forKey: key)
            trace("Backup folder: remembered \(url.lastPathComponent)")
            call.resolve(["name": url.lastPathComponent])
        } catch {
            trace("Backup folder: could not remember it: \(error)")
            call.reject("Could not use that folder: \(error.localizedDescription)")
        }
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        trace("Backup folder: picker swiped away")
        picker = nil
        pickCall?.resolve(["cancelled": true])
        pickCall = nil
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        trace("Backup folder: picker cancelled")
        picker = nil
        pickCall?.resolve(["cancelled": true])
        pickCall = nil
    }

    private func folder() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale) else { return nil }
        if stale, let fresh = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(fresh, forKey: key)
        }
        return url
    }

    @objc func status(_ call: CAPPluginCall) {
        if let url = folder() { call.resolve(["name": url.lastPathComponent]) } else { call.resolve([:]) }
    }

    @objc func forget(_ call: CAPPluginCall) {
        UserDefaults.standard.removeObject(forKey: key)
        call.resolve()
    }

    // Writes one backup file into the folder, then removes its own oldest backups beyond `keep`
    @objc func write(_ call: CAPPluginCall) {
        guard let name = call.getString("name"), let text = call.getString("data") else { return call.reject("Nothing to write") }
        let keep = max(1, call.getInt("keep") ?? 5)
        DispatchQueue.global(qos: .utility).async {
            guard let dir = self.folder() else { return call.reject("No backup folder chosen") }
            let ok = dir.startAccessingSecurityScopedResource()
            defer { if ok { dir.stopAccessingSecurityScopedResource() } }
            var failure: Error?
            let coordinator = NSFileCoordinator()
            var coordError: NSError?
            coordinator.coordinate(writingItemAt: dir.appendingPathComponent(name), options: .forReplacing, error: &coordError) { target in
                do { try text.write(to: target, atomically: true, encoding: .utf8) } catch { failure = error }
            }
            if let e = failure ?? coordError { return call.reject("The backup could not be written: \(e.localizedDescription)") }
            let fm = FileManager.default
            if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                let mine = files.filter { $0.lastPathComponent.hasPrefix(self.prefix) && $0.pathExtension == "json" }
                    .sorted { $0.lastPathComponent > $1.lastPathComponent }
                for old in mine.dropFirst(keep) { try? fm.removeItem(at: old) }
            }
            call.resolve(["folder": dir.lastPathComponent])
        }
    }
}
