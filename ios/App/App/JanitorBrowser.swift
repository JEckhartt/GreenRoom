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

    // Forwards what the importer collected to Green Room's own page
    func send(_ data: [String: Any]) { notifyListeners("janitor", data: data) }

    @objc func open(_ call: CAPPluginCall) {
        let start = URL(string: call.getString("url") ?? "") ?? URL(string: "https://janitorai.com")!
        DispatchQueue.main.async {
            let browser = JanitorBrowserController(start: start, plugin: self)
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
    private weak var plugin: JanitorBrowserPlugin?
    private var importing = false
    private let importButton = UIButton(type: .system)
    private var webView: WKWebView!
    private var recorded: [[String: Any]] = []
    private var recordedBytes = 0
    private let countLabel = UILabel()

    init(start: URL, plugin: JanitorBrowserPlugin) {
        self.start = start
        self.plugin = plugin
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
        content.add(WeakMessageHandler(self), name: "grImport")
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
        save.setTitle("Save file", for: .normal)
        save.titleLabel?.font = .systemFont(ofSize: 15)
        save.addTarget(self, action: #selector(saveTapped(_:)), for: .touchUpInside)

        importButton.setTitle("Import chats", for: .normal)
        importButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        importButton.addTarget(self, action: #selector(importTapped), for: .touchUpInside)

        countLabel.font = .systemFont(ofSize: 12)
        countLabel.textColor = .secondaryLabel
        countLabel.text = "Log in first"
        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.minimumScaleFactor = 0.7

        let right = UIStackView(arrangedSubviews: [save, importButton])
        right.axis = .horizontal
        right.spacing = 16
        let bar = UIStackView(arrangedSubviews: [close, countLabel, right])
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

    // One recorded response from the page, or a message from the importer
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let entry = message.body as? [String: Any] else { return }
        if message.name == "grImport" { return importMessage(entry) }
        let size = ((entry["body"] as? String)?.utf8.count ?? 0) + ((entry["sent"] as? String)?.utf8.count ?? 0)
        if recorded.count >= 800 || recordedBytes + size > 25_000_000 { return }
        recorded.append(entry)
        recordedBytes += size
        countLabel.text = "\(recorded.count) recorded"
    }

    @objc private func importTapped() {
        if importing { return }
        importing = true
        importButton.isEnabled = false
        countLabel.text = "Starting…"
        plugin?.send(["type": "start"])
        webView.evaluateJavaScript(JanitorBrowserController.importer) { [weak self] _, error in
            if let error = error { self?.importMessage(["kind": "error", "message": error.localizedDescription]) }
        }
    }

    // Progress, characters and chats from the importer: shown here and passed on to Green Room
    private func importMessage(_ m: [String: Any]) {
        let kind = m["kind"] as? String ?? ""
        switch kind {
        case "progress":
            countLabel.text = m["label"] as? String ?? ""
        case "char", "chat":
            plugin?.send(["type": kind, "json": m["json"] as? String ?? ""])
        case "done":
            importing = false
            plugin?.send(["type": "done"])
            dismiss(animated: true)
        case "error":
            importing = false
            importButton.isEnabled = true
            let text = m["message"] as? String ?? "Something went wrong."
            countLabel.text = "Import failed"
            plugin?.send(["type": "error", "message": text])
            let alert = UIAlertController(title: "Import failed", message: text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        default: break
        }
    }

    // Links that would open a new window open here instead
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }

    @objc private func closeTapped() {
        if importing { webView.evaluateJavaScript("window.__grStop = true") }
        if importing { plugin?.send(["type": "error", "message": "cancelled"]) }
        dismiss(animated: true)
    }

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

    // Import chats: runs in the JanitorAI page (so it is logged in, like the site itself) and asks the
    // site's API for every character you chatted with, their details, and every chat with its messages.
    // Each one is passed to Green Room as it arrives.
    static let importer = #"""
    (async function () {
      var post = function (d) { try { window.webkit.messageHandlers.grImport.postMessage(d); } catch (e) {} };
      window.__grStop = false;
      var f = window.__grFetch || window.fetch;
      var wait = function (ms) { return new Promise(function (r) { setTimeout(r, ms); }); };
      var get = async function (path) {
        for (var attempt = 0; attempt < 5; attempt++) {
          if (window.__grStop) throw new Error('cancelled');
          var r = await f.call(window, 'https://janitorai.com/hampter/' + path, { credentials: 'include', headers: Object.assign({ accept: 'application/json' }, window.__grAuth || {}) });
          if (r.status === 429 || r.status >= 500) { await wait(1500 * (attempt + 1)); continue; }
          if (r.status === 401 || r.status === 403) throw new Error('JanitorAI says you are not logged in (' + r.status + '). Log in, open your chats once, then try again.');
          if (!r.ok) throw new Error('JanitorAI answered ' + r.status + ' for ' + path.split('?')[0]);
          await wait(120);
          return await r.text();
        }
        throw new Error('JanitorAI is busy. Try again in a minute.');
      };
      try {
        post({ kind: 'progress', label: 'Finding your chats…' });
        var chars = [];
        for (var page = 1; page < 200; page++) {
          var list = JSON.parse(await get('chats/character-chats?page=' + page + '&sortBy=latest&pageSize=30'));
          chars = chars.concat(list.characters || []);
          post({ kind: 'progress', label: chars.length + ' characters found…' });
          if (!list.hasMore || !(list.characters || []).length) break;
        }
        var chatIds = [];
        for (var i = 0; i < chars.length; i++) {
          var c = chars[i];
          post({ kind: 'progress', label: 'Character ' + (i + 1) + ' of ' + chars.length });
          try { post({ kind: 'char', json: await get('characters/' + c.character_id) }); }
          catch (e) { if (e.message === 'cancelled') throw e; post({ kind: 'char', json: JSON.stringify({ id: c.character_id, name: c.name, avatar: c.avatar, gone: true }) }); }
          for (var cp = 1; cp < 50; cp++) {
            var cl = JSON.parse(await get('chats/character/' + c.character_id + '/chats' + (cp > 1 ? '?page=' + cp : '')));
            var got = (cl.chats || []).map(function (x) { return x.id; }).filter(function (id) { return chatIds.indexOf(id) < 0; });
            chatIds = chatIds.concat(got);
            if (!cl.hasMore || !got.length) break;
          }
        }
        for (var j = 0; j < chatIds.length; j++) {
          post({ kind: 'progress', label: 'Chat ' + (j + 1) + ' of ' + chatIds.length });
          post({ kind: 'chat', json: await get('chats/' + chatIds[j]) });
        }
        post({ kind: 'done' });
      } catch (e) {
        if (e && e.message === 'cancelled') return;
        post({ kind: 'error', message: String((e && e.message) || e) });
      }
    })();
    0;
    """#

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
      window.__grFetch = realFetch;
      // The site's own login headers for its API, kept in memory for the importer (never saved to the file)
      window.__grAuth = window.__grAuth || {};
      var keep = function (u, name, value) {
        if (!/janitorai\.com\/hampter\//.test(new URL(u, location.href).href)) return;
        var n = String(name).toLowerCase();
        if (n === 'authorization' || (/^x-/.test(n))) window.__grAuth[n] = String(value);
      };
      var noteHeaders = function (u, h) {
        try {
          if (!h) return;
          if (typeof h.forEach === 'function' && !Array.isArray(h)) h.forEach(function (v, k) { keep(u, k, v); });
          else if (Array.isArray(h)) h.forEach(function (p) { keep(u, p[0], p[1]); });
          else Object.keys(h).forEach(function (k) { keep(u, k, h[k]); });
        } catch (e) {}
      };
      window.fetch = function (input, init) {
        var url = typeof input === 'string' ? input : (input && input.url) || String(input);
        noteHeaders(url, input && typeof input !== 'string' && input.headers);
        noteHeaders(url, init && init.headers);
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
      var setHeader = XMLHttpRequest.prototype.setRequestHeader;
      XMLHttpRequest.prototype.setRequestHeader = function (k, v) { try { if (this.__gr) keep(this.__gr.url, k, v); } catch (e) {} return setHeader.apply(this, arguments); };
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
