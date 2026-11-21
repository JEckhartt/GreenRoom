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

    // Opens Files straight away to choose the folder
    @objc func pick(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.pickCall = call
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
            picker.delegate = self
            picker.allowsMultipleSelection = false
            // a sheet with Cancel and Open in its bar, which can also be swiped down to close
            picker.modalPresentationStyle = .formSheet
            picker.isModalInPresentation = false
            picker.overrideUserInterfaceStyle = .unspecified
            var top = self.bridge?.viewController
            while let shown = top?.presentedViewController { top = shown }
            top?.present(picker, animated: true) {
                picker.presentationController?.delegate = self
            }
        }
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let call = pickCall, let url = urls.first else { return }
        pickCall = nil
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(data, forKey: key)
            call.resolve(["name": url.lastPathComponent])
        } catch {
            call.reject("Could not use that folder: \(error.localizedDescription)")
        }
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        pickCall?.resolve(["cancelled": true])
        pickCall = nil
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
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
