import UIKit
import WebKit
import Capacitor

// "Connect to JanitorAI": opens JanitorAI in a browser window inside the app. You log in as usual (the
// login is remembered). While you browse, the data the site's own page loads (chat lists, messages,
// characters) is recorded, so an inspection file can be saved and shared to work out a chat import.
// Login tokens, passwords, cookies and e-mail addresses are removed from the file.
@objc(JanitorBrowserPlugin)
public class JanitorBrowserPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "JanitorBrowserPlugin"
    public let jsName = "JanitorBrowser"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise)
    ]

    @objc func open(_ call: CAPPluginCall) {
        let start = URL(string: call.getString("url") ?? "") ?? URL(string: "https://janitorai.com")!
        DispatchQueue.main.async {
            let browser = JanitorBrowserController(start: start)
            browser.modalPresentationStyle = .fullScreen
            self.bridge?.viewController?.present(browser, animated: true)
            call.resolve()
        }
    }
}

// The web page holds its message handler weakly, so the browser window can be released when closed
private class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}

class JanitorBrowserController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private let start: URL
    private var webView: WKWebView!
    private var recorded: [[String: Any]] = []
    private var recordedBytes = 0
    private let countLabel = UILabel()

    init(start: URL) {
        self.start = start
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default() // stays logged in
        let content = WKUserContentController()
        content.add(WeakMessageHandler(self), name: "gr")
        content.addUserScript(WKUserScript(source: JanitorBrowserController.recorder, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        config.userContentController = content

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

        let close = UIButton(type: .system)
        close.setTitle("Close", for: .normal)
        close.titleLabel?.font = .systemFont(ofSize: 17)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let save = UIButton(type: .system)
        save.setTitle("Save inspection file", for: .normal)
        save.titleLabel?.font = .boldSystemFont(ofSize: 16)
        save.addTarget(self, action: #selector(saveTapped(_:)), for: .touchUpInside)

        countLabel.font = .systemFont(ofSize: 12)
        countLabel.textColor = .secondaryLabel
        countLabel.text = "0 recorded"

        let bar = UIStackView(arrangedSubviews: [close, countLabel, save])
        bar.axis = .horizontal
        bar.alignment = .center
        bar.distribution = .equalSpacing
        bar.isLayoutMarginsRelativeArrangement = true
        bar.layoutMargins = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)

        bar.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 44),
            webView.topAnchor.constraint(equalTo: bar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        webView.load(URLRequest(url: start))
    }

    // One recorded response from the page
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let entry = message.body as? [String: Any] else { return }
        let size = ((entry["body"] as? String)?.utf8.count ?? 0) + ((entry["sent"] as? String)?.utf8.count ?? 0)
        if recorded.count >= 800 || recordedBytes + size > 25_000_000 { return }
        recorded.append(entry)
        recordedBytes += size
        countLabel.text = "\(recorded.count) recorded"
    }

    // Links that would open a new window open here instead
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    @objc private func saveTapped(_ sender: UIButton) {
        webView.evaluateJavaScript("[location.href, document.title, document.documentElement.outerHTML]") { [weak self] result, _ in
            guard let self = self else { return }
            let page = result as? [Any] ?? []
            let html = (page.count > 2 ? page[2] as? String : nil) ?? ""
            let file: [String: Any] = [
                "app": "Green Room",
                "kind": "janitorai-inspection",
                "version": 1,
                "created": ISO8601DateFormatter().string(from: Date()),
                "page": (page.first as? String) ?? "",
                "title": (page.count > 1 ? page[1] as? String : nil) ?? "",
                "html": String(html.prefix(2_000_000)),
                "requests": self.recorded
            ]
            guard let data = try? JSONSerialization.data(withJSONObject: file, options: [.prettyPrinted]),
                  let raw = String(data: data, encoding: .utf8) else { return }
            let text = JanitorBrowserController.redact(raw)
            let stamp = DateFormatter()
            stamp.dateFormat = "yyyy-MM-dd-HHmm"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("janitorai-inspection-\(stamp.string(from: Date())).json")
            do { try text.write(to: url, atomically: true, encoding: .utf8) } catch { return }
            let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            share.popoverPresentationController?.sourceView = sender
            self.present(share, animated: true)
        }
    }

    // Removes login tokens (JWTs), secret-looking fields and e-mail addresses from the file
    static func redact(_ input: String) -> String {
        var text = input
        let rules: [(String, String)] = [
            (#"eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{4,}"#, "[removed]"),
            (#"(?i)(\\?"(?:[a-z_]*token|authorization|cookie|password|secret|api_?key|session[a-z_]*|refresh[a-z_]*)\\?"\s*:\s*\\?")[^"\\]*(\\?")"#, "$1[removed]$2"),
            (#"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#, "[email removed]")
        ]
        for (pattern, template) in rules {
            if let re = try? NSRegularExpression(pattern: pattern) {
                text = re.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
            }
        }
        return text
    }

    // Runs in every page before the site's own code: records the data the page fetches (not images,
    // scripts, styles or trackers). Request headers are never recorded, so no login headers are kept
    static let recorder = #"""
    (function () {
      if (window.__grRecorder) return; window.__grRecorder = true;
      var post = function (d) { try { window.webkit.messageHandlers.gr.postMessage(d); } catch (e) {} };
      var skip = function (u) {
        return /\.(js|mjs|css|png|jpe?g|gif|webp|avif|svg|woff2?|ttf|otf|ico|mp4|webm|mp3)(\?|$)/i.test(u) ||
          /google-analytics|googletagmanager|doubleclick|sentry|clarity|hotjar|facebook|cloudflareinsights|cdn-cgi|stripe|recaptcha|hcaptcha|turnstile/i.test(u);
      };
      var cleanUrl = function (u) {
        try { var x = new URL(u, location.href); Array.from(x.searchParams.keys()).forEach(function (k) { if (/token|key|auth|sig|session|secret|code/i.test(k)) x.searchParams.set(k, 'removed'); }); return x.href; }
        catch (e) { return String(u); }
      };
      var LIMIT = 300000;
      var realFetch = window.fetch;
      window.fetch = function (input, init) {
        var url = typeof input === 'string' ? input : (input && input.url) || String(input);
        var method = (init && init.method) || (input && input.method) || 'GET';
        var sent = init && typeof init.body === 'string' ? init.body.slice(0, 20000) : '';
        var p = realFetch.apply(this, arguments);
        if (!skip(url)) p.then(function (r) {
          var ct = r.headers.get('content-type') || '';
          if (!/json|text|event-stream/i.test(ct)) return;
          r.clone().text().then(function (t) {
            post({ via: 'fetch', method: method, url: cleanUrl(url), status: r.status, type: ct, sent: sent, body: t.slice(0, LIMIT), truncated: t.length > LIMIT, at: Date.now() });
          }).catch(function () {});
        }).catch(function () {});
        return p;
      };
      var open = XMLHttpRequest.prototype.open, send = XMLHttpRequest.prototype.send;
      XMLHttpRequest.prototype.open = function (m, u) { this.__gr = { method: m, url: String(u) }; return open.apply(this, arguments); };
      XMLHttpRequest.prototype.send = function (b) {
        var info = this.__gr, xhr = this;
        if (info && !skip(info.url)) {
          info.sent = typeof b === 'string' ? b.slice(0, 20000) : '';
          xhr.addEventListener('load', function () {
            try {
              var ct = xhr.getResponseHeader('content-type') || '';
              if (!/json|text/i.test(ct)) return;
              var t = typeof xhr.responseText === 'string' ? xhr.responseText : '';
              post({ via: 'xhr', method: info.method, url: cleanUrl(info.url), status: xhr.status, type: ct, sent: info.sent, body: t.slice(0, LIMIT), truncated: t.length > LIMIT, at: Date.now() });
            } catch (e) {}
          });
        }
        return send.apply(this, arguments);
      };
    })();
    """#
}
