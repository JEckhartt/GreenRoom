import Foundation
import Capacitor

// The app's main screen: Capacitor's view controller, plus Green Room's own native plugin.
class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(NativeStreamPlugin())
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
