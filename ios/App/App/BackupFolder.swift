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
        CAPPluginMethod(name: "forget", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "readShared", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "begin", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "append", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "finish", returnType: CAPPluginReturnPromise)
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

    // A card opened in place from Files (not copied into the app): read it with the access iOS gave for it
    @objc func readShared(_ call: CAPPluginCall) {
        guard let s = call.getString("url"), let url = URL(string: s) else { return call.reject("No file") }
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        var result: Data?
        var coordError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordError) { u in result = try? Data(contentsOf: u) }
        guard let data = result else { return call.reject("Could not read the file: \(coordError?.localizedDescription ?? "no access")") }
        call.resolve(["data": data.base64EncodedString()])
    }

    @objc func forget(_ call: CAPPluginCall) {
        UserDefaults.standard.removeObject(forKey: key)
        call.resolve()
    }

    // A backup is written in pieces (begin, append…, finish) into a temporary file, so the whole backup never
    // has to be in memory at once; finish copies it into the folder and removes the oldest ones beyond `keep`
    private var tempFile: URL?
    private var tempHandle: FileHandle?
    private let io = DispatchQueue(label: "greenroom.backup")

    @objc func begin(_ call: CAPPluginCall) {
        io.async {
            try? self.tempHandle?.close()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("greenroom-backup-\(UUID().uuidString).json")
            FileManager.default.createFile(atPath: url.path, contents: nil)
            guard let h = try? FileHandle(forWritingTo: url) else { return call.reject("Could not start the backup") }
            self.tempFile = url; self.tempHandle = h
            call.resolve()
        }
    }

    @objc func append(_ call: CAPPluginCall) {
        guard let text = call.getString("data") else { return call.reject("Nothing to write") }
        io.async {
            guard let h = self.tempHandle, let d = text.data(using: .utf8) else { return call.reject("The backup was not started") }
            do { try h.write(contentsOf: d); call.resolve() } catch { call.reject("Writing failed: \(error.localizedDescription)") }
        }
    }

    @objc func finish(_ call: CAPPluginCall) {
        guard let name = call.getString("name") else { return call.reject("No name") }
        let keep = max(1, call.getInt("keep") ?? 5)
        io.async {
            try? self.tempHandle?.close(); self.tempHandle = nil
            guard let src = self.tempFile else { return call.reject("The backup was not started") }
            self.tempFile = nil
            defer { try? FileManager.default.removeItem(at: src) }
            guard let dir = self.folder() else { return call.reject("No backup folder chosen") }
            let ok = dir.startAccessingSecurityScopedResource()
            defer { if ok { dir.stopAccessingSecurityScopedResource() } }
            var failure: Error?
            var coordError: NSError?
            NSFileCoordinator().coordinate(writingItemAt: dir.appendingPathComponent(name), options: .forReplacing, error: &coordError) { target in
                do {
                    if FileManager.default.fileExists(atPath: target.path) { try FileManager.default.removeItem(at: target) }
                    try FileManager.default.copyItem(at: src, to: target)
                } catch { failure = error }
            }
            if let e = failure ?? coordError { return call.reject("The backup could not be saved: \(e.localizedDescription)") }
            let fm = FileManager.default
            if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                let mine = files.filter { $0.lastPathComponent.hasPrefix(self.prefix) && $0.pathExtension == "json" }
                    .sorted { $0.lastPathComponent > $1.lastPathComponent }
                for old in mine.dropFirst(keep) { try? fm.removeItem(at: old) }
            }
            call.resolve(["folder": dir.lastPathComponent])
        }
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
