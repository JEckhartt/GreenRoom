import Foundation
import Capacitor
import WebKit
import UIKit

// The app's main screen: Capacitor's view controller, plus Green Room's own native plugins.
class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(NativeStreamPlugin())
        bridge?.registerPluginInstance(JanitorBrowserPlugin())
        bridge?.registerPluginInstance(StoryPdfPlugin())
        // Scrolling a chat mustn't close the keyboard (only a tap does, handled in the page)
        UIScrollView.grKeepKeyboardOnScroll()
        webView?.scrollView.keyboardDismissMode = .none
        WKWebView.grTraceResign()
    }
}

// Settings → Debug: when iOS asks the web view to give up the keyboard, note which code asked (to find what closes it while
// scrolling a chat)
extension WKWebView {
    private static var grTraced = false
    static func grTraceResign() {
        if grTraced { return }
        grTraced = true
        let cls: AnyClass = WKWebView.self
        guard let o = class_getInstanceMethod(cls, #selector(UIResponder.resignFirstResponder)),
              let r = class_getInstanceMethod(cls, #selector(WKWebView.gr_resignFirstResponder)) else { return }
        if class_addMethod(cls, #selector(UIResponder.resignFirstResponder), method_getImplementation(r), method_getTypeEncoding(r)) {
            class_replaceMethod(cls, #selector(WKWebView.gr_resignFirstResponder), method_getImplementation(o), method_getTypeEncoding(o))
        } else {
            method_exchangeImplementations(o, r)
        }
    }
    @objc func gr_resignFirstResponder() -> Bool {
        let frames = Thread.callStackSymbols.prefix(28).map { line -> String in
            // "3   UIKitCore   0x00000001 -[UIScrollView _something] + 120" → "-[UIScrollView _something]"
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count > 3 else { return line }
            var sym = parts[3...].joined(separator: " ")
            if let plus = sym.range(of: " + ", options: .backwards) { sym = String(sym[..<plus.lowerBound]) }
            return sym
        }
        let msg = "native: web view asked to give up the keyboard by: " + frames.joined(separator: " < ")
        if let data = try? JSONSerialization.data(withJSONObject: [msg]), let json = String(data: data, encoding: .utf8) {
            evaluateJavaScript("window.dbg && dbg('kb', \(json)[0])", completionHandler: nil)
        }
        return gr_resignFirstResponder() // the original
    }
}

// iOS scroll views can close the keyboard as soon as you drag them. Every scroll view inside the web view (the page
// makes one for each scrolling area, like a chat's messages) is set not to, whenever it appears or is changed.
extension UIScrollView {
    private static var grSwapped = false
    static func grKeepKeyboardOnScroll() {
        if grSwapped { return }
        grSwapped = true
        grSwap(#selector(UIView.didMoveToWindow), #selector(UIScrollView.gr_didMoveToWindow))
        grSwap(#selector(setter: UIScrollView.keyboardDismissMode), #selector(UIScrollView.gr_setKeyboardDismissMode(_:)))
    }
    private static func grSwap(_ original: Selector, _ replacement: Selector) {
        let cls: AnyClass = UIScrollView.self
        guard let o = class_getInstanceMethod(cls, original), let r = class_getInstanceMethod(cls, replacement) else { return }
        if class_addMethod(cls, original, method_getImplementation(r), method_getTypeEncoding(r)) {
            class_replaceMethod(cls, replacement, method_getImplementation(o), method_getTypeEncoding(o))
        } else {
            method_exchangeImplementations(o, r)
        }
    }
    private var grWebView: WKWebView? {
        var v: UIView? = superview
        while let x = v { if let w = x as? WKWebView { return w }; v = x.superview }
        return nil
    }
    @objc func gr_didMoveToWindow() {
        gr_didMoveToWindow() // the original
        guard window != nil, let wv = grWebView else { return }
        if keyboardDismissMode != .none {
            let was = keyboardDismissMode.rawValue
            gr_setKeyboardDismissMode(.none) // the original setter
            wv.evaluateJavaScript("window.dbg && dbg('kb', 'native: a scroll view in the page would close the keyboard on drag (mode \(was)); turned off')", completionHandler: nil)
        }
    }
    @objc func gr_setKeyboardDismissMode(_ mode: UIScrollView.KeyboardDismissMode) {
        gr_setKeyboardDismissMode(grWebView != nil ? .none : mode) // the original setter
    }
}

// Native connection: sends a proxy request straight from iOS (not from the web view, so without the
// "came from a web page" Origin header some services block) and streams the answer back piece by piece,
// so replies are still written live. Events go to the "ns" listener: head (status + headers), data
// (a chunk, base64) and end (with an error message if it failed).
@objc(NativeStreamPlugin)
public class NativeStreamPlugin: CAPPlugin, CAPBridgedPlugin, URLSessionDataDelegate {
    public let identifier = "NativeStreamPlugin"
    public let jsName = "NativeStream"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "cancel", returnType: CAPPluginReturnPromise)
    ]

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 300
        cfg.timeoutIntervalForResource = 900
        return URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }()
    private var streamIds: [Int: String] = [:]
    private var tasks: [String: URLSessionDataTask] = [:]
    private let lock = NSLock()

    @objc func start(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let urlString = call.getString("url"), let url = URL(string: urlString) else {
            call.reject("Invalid request")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = call.getString("method") ?? "POST"
        if let headers = call.getObject("headers") {
            for (name, value) in headers {
                if let text = value as? String { request.setValue(text, forHTTPHeaderField: name) }
            }
        }
        if let body = call.getString("body") { request.httpBody = body.data(using: .utf8) }
        let task = session.dataTask(with: request)
        lock.lock(); streamIds[task.taskIdentifier] = id; tasks[id] = task; lock.unlock()
        task.resume()
        call.resolve()
    }

    @objc func cancel(_ call: CAPPluginCall) {
        if let id = call.getString("id") {
            lock.lock(); let task = tasks[id]; lock.unlock()
            task?.cancel()
        }
        call.resolve()
    }

    private func streamId(_ task: URLSessionTask) -> String? {
        lock.lock(); defer { lock.unlock() }
        return streamIds[task.taskIdentifier]
    }

    // A redirect to the same server (LoreBary sends …/chat/completions to the bare address) keeps the
    // request's headers (the API key) and body; iOS would otherwise drop the Authorization header.
    // Never for another server, so a key can't leak elsewhere.
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        var next = request
        if let original = task.originalRequest, original.url?.host == request.url?.host, original.url?.scheme == request.url?.scheme {
            for (name, value) in original.allHTTPHeaderFields ?? [:] where next.value(forHTTPHeaderField: name) == nil {
                next.setValue(value, forHTTPHeaderField: name)
            }
            if response.statusCode == 307 || response.statusCode == 308 {
                next.httpMethod = original.httpMethod
                if next.httpBody == nil { next.httpBody = original.httpBody }
            }
        }
        completionHandler(next)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let id = streamId(dataTask), let http = response as? HTTPURLResponse {
            var headers: [String: String] = [:]
            for (name, value) in http.allHeaderFields { headers[String(describing: name).lowercased()] = String(describing: value) }
            notifyListeners("ns", data: ["id": id, "type": "head", "status": http.statusCode, "headers": headers])
        }
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let id = streamId(dataTask) {
            notifyListeners("ns", data: ["id": id, "type": "data", "b64": data.base64EncodedString()])
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let id = streamId(task) else { return }
        var event: [String: Any] = ["id": id, "type": "end"]
        if let nsError = error as NSError? {
            event["error"] = nsError.code == NSURLErrorCancelled ? "cancelled" : nsError.localizedDescription
        }
        notifyListeners("ns", data: event)
        lock.lock(); streamIds.removeValue(forKey: task.taskIdentifier); tasks.removeValue(forKey: id); lock.unlock()
    }
}
