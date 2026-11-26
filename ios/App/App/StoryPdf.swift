import UIKit
import WebKit
import Capacitor

// Stories → PDF: the story as HTML, laid out by WebKit into real book pages (A5).
// The layout happens in WebKit's own process and the pages are drawn a few at a time,
// so the app stays usable while a long story is turned into a PDF; "progress" events report how far it is.
@objc(StoryPdfPlugin)
public class StoryPdfPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "StoryPdfPlugin"
    public let jsName = "StoryPdf"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "make", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "awake", returnType: CAPPluginReturnPromise)
    ]
    private var job: StoryPdfJob?

    // While a story is being written the screen doesn't lock (iOS pauses the app when it does)
    @objc func awake(_ call: CAPPluginCall) {
        let on = call.getBool("on") ?? false
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = on
            call.resolve()
        }
    }

    @objc func make(_ call: CAPPluginCall) {
        guard let html = call.getString("html") else { return call.reject("No story to print") }
        let title = call.getString("title") ?? "Story"
        DispatchQueue.main.async {
            if self.job != nil { return call.reject("A PDF is already being made") }
            let job = StoryPdfJob(html: html, title: title, progress: { [weak self] done, total in
                self?.notifyListeners("progress", data: ["done": done, "total": total])
            }, finished: { [weak self] data, error in
                self?.job = nil
                if let data = data { call.resolve(["b64": data.base64EncodedString()]) }
                else { call.reject(error ?? "The PDF failed") }
            })
            self.job = job
            job.start(in: self.bridge?.viewController?.view.window)
        }
    }
}

final class StoryPdfJob: NSObject, WKNavigationDelegate {
    private let html: String
    private let title: String
    private let progress: (Int, Int) -> Void
    private let finished: (Data?, String?) -> Void
    private let page = CGRect(x: 0, y: 0, width: 419.53, height: 595.28) // A5 in points
    private var web: WKWebView?
    private var renderer: UIPrintPageRenderer?
    private var data: NSMutableData?
    private var context: CGContext?
    private var total = 0

    init(html: String, title: String, progress: @escaping (Int, Int) -> Void, finished: @escaping (Data?, String?) -> Void) {
        self.html = html; self.title = title; self.progress = progress; self.finished = finished
        super.init()
    }

    func start(in window: UIWindow?) {
        let web = WKWebView(frame: page)
        web.isUserInteractionEnabled = false
        web.navigationDelegate = self
        // kept behind everything else: it's only there so WebKit lays the story out
        window?.insertSubview(web, at: 0)
        self.web = web
        web.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.layOut() }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { fail(error.localizedDescription) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { fail(error.localizedDescription) }

    private func layOut() {
        guard let web = web else { return }
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(web.viewPrintFormatter(), startingAtPageAt: 0)
        renderer.setValue(NSValue(cgRect: page), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: page.insetBy(dx: 44, dy: 50)), forKey: "printableRect")
        total = renderer.numberOfPages
        if total == 0 { return fail("The story came out empty") }
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: total))
        let data = NSMutableData()
        var box = page
        let info = [kCGPDFContextTitle as String: title, kCGPDFContextCreator as String: "Green Room"] as CFDictionary
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &box, info) else { return fail("Could not start the PDF") }
        self.renderer = renderer; self.data = data; self.context = context
        progress(0, total)
        draw(from: 0)
    }

    // a few pages at a time, then back to the app so it keeps responding
    private func draw(from first: Int) {
        guard let renderer = renderer, let context = context else { return }
        let last = min(total, first + 6)
        for i in first..<last {
            context.beginPDFPage(nil)
            context.saveGState()
            context.translateBy(x: 0, y: page.height) // UIKit draws top-down
            context.scaleBy(x: 1, y: -1)
            UIGraphicsPushContext(context)
            renderer.drawPage(at: i, in: page)
            UIGraphicsPopContext()
            context.restoreGState()
            context.endPDFPage()
        }
        progress(last, total)
        if last < total {
            DispatchQueue.main.async { self.draw(from: last) }
        } else {
            context.closePDF()
            let out = data.map { Data(referencing: $0) }
            cleanUp()
            finished(out, nil)
        }
    }

    private func fail(_ message: String) {
        cleanUp()
        finished(nil, message)
    }

    private func cleanUp() {
        web?.navigationDelegate = nil
        web?.removeFromSuperview()
        web = nil; renderer = nil; context = nil; data = nil
    }
}
