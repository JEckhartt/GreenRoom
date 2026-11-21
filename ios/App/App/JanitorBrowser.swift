import UIKit
import WebKit
import Capacitor

// "Connect to JanitorAI": opens JanitorAI in a browser window inside the app. You log in as usual (the
// login is remembered). Mode "import" downloads your characters and chats, "chars" only your characters,
// and passes them to Green Room for review; "prompts" passes on what the site loads while you open your
// custom prompts (until Done); "browse" just shows the site.
@objc(JanitorBrowserPlugin)
public class JanitorBrowserPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "JanitorBrowserPlugin"
    public let jsName = "JanitorBrowser"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logout", returnType: CAPPluginReturnPromise)
    ]

    // Forwards what the importer collected to Green Room's own page
    func send(_ data: [String: Any]) { notifyListeners("janitor", data: data) }

    @objc func open(_ call: CAPPluginCall) {
        let start = URL(string: call.getString("url") ?? "") ?? URL(string: "https://janitorai.com")!
        DispatchQueue.main.async {
            let browser = JanitorBrowserController(start: start, plugin: self, mode: call.getString("mode") ?? "browse")
            browser.modalPresentationStyle = .fullScreen
            self.bridge?.viewController?.present(browser, animated: true)
            call.resolve()
        }
    }

    // Log out: removes JanitorAI's saved login (cookies and site data) from the app; nothing else
    @objc func logout(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let store = WKWebsiteDataStore.default()
            let types = WKWebsiteDataStore.allWebsiteDataTypes()
            store.fetchDataRecords(ofTypes: types) { records in
                let mine = records.filter { $0.displayName.lowercased().contains("janitorai") }
                store.removeData(ofTypes: types, for: mine) { call.resolve(["removed": mine.count]) }
            }
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
    private let mode: String
    private var importing = false
    private var finished = false
    private var seen = 0
    private let importButton = UIButton(type: .system)
    private var webView: WKWebView!
    private let countLabel = UILabel()

    init(start: URL, plugin: JanitorBrowserPlugin, mode: String) {
        self.start = start
        self.plugin = plugin
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default() // stays logged in
        let content = WKUserContentController()
        content.add(WeakMessageHandler(self), name: "grImport")
        content.addUserScript(WKUserScript(source: JanitorBrowserController.loginHeaders, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        if mode == "prompts" {
            content.addUserScript(WKUserScript(source: JanitorBrowserController.promptWatch, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }
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

        importButton.setTitle(mode == "prompts" ? "Done" : "Continue", for: .normal)
        importButton.isHidden = mode != "prompts"
        importButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        importButton.addTarget(self, action: #selector(importTapped), for: .touchUpInside)

        countLabel.font = .systemFont(ofSize: 12)
        countLabel.textColor = .secondaryLabel
        countLabel.text = mode == "browse" ? "" : mode == "prompts" ? "Open your custom prompts" : "Opening JanitorAI…"
        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.minimumScaleFactor = 0.7

        let bar = UIStackView(arrangedSubviews: [close, countLabel, importButton])
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

    // A message from the importer
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let entry = message.body as? [String: Any] else { return }
        importMessage(entry)
    }

    // Starts by itself once the page has loaded; after logging in, again (or with Continue)
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if mode != "browse" && mode != "prompts" && !importing && !finished && webView.url?.host?.contains("janitorai.com") == true { importTapped() }
    }

    @objc private func importTapped() {
        if mode == "prompts" {
            plugin?.send(["type": "done", "mode": mode])
            return dismiss(animated: true)
        }
        if importing || finished || mode == "browse" { return }
        importing = true
        importButton.isHidden = true
        countLabel.text = "Starting…"
        plugin?.send(["type": "start", "mode": mode])
        webView.evaluateJavaScript("window.__grMode = '\(mode == "chars" ? "chars" : "import")';" + JanitorBrowserController.importer) { [weak self] _, error in
            if let error = error { self?.importMessage(["kind": "error", "message": error.localizedDescription]) }
        }
    }

    // Progress, characters and chats from the importer: shown here and passed on to Green Room
    private func importMessage(_ m: [String: Any]) {
        let kind = m["kind"] as? String ?? ""
        switch kind {
        case "progress":
            countLabel.text = m["label"] as? String ?? ""
        case "resp":
            plugin?.send(["type": "resp", "url": m["url"] as? String ?? "", "json": m["json"] as? String ?? ""])
            seen += 1
            countLabel.text = "Open your custom prompts · \(seen) loaded"
        case "char", "chat":
            plugin?.send(["type": kind, "json": m["json"] as? String ?? ""])
        case "login":
            importing = false
            countLabel.text = "Log in to continue"
            importButton.isHidden = false
        case "done":
            importing = false
            finished = true
            plugin?.send(["type": "done", "mode": mode])
            dismiss(animated: true)
        case "error":
            importing = false
            importButton.isHidden = false
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
          if (r.status === 401 || r.status === 403) throw new Error('login');
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
          if (window.__grMode === 'chars') continue;
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
        if (e && e.message === 'login') return post({ kind: 'login' });
        post({ kind: 'error', message: String((e && e.message) || e) });
      }
    })();
    0;
    """#

    // Import custom prompts: passes on the data (JSON) the JanitorAI site loads from its own server while
    // this window is open, so Green Room can pick out the prompts. Request headers are never passed on
    static let promptWatch = #"""
    (function () {
      if (window.__grPromptWatch) return; window.__grPromptWatch = true;
      var post = function (u, t) {
        try {
          if (!t || t.length > 2000000 || !/^\s*[\[{]/.test(t)) return;
          var x = new URL(u, location.href);
          if (!/(^|\.)janitorai\.com$/.test(x.hostname) || /dustpan|track|notifications|locales|emoji/.test(x.pathname)) return;
          window.webkit.messageHandlers.grImport.postMessage({ kind: 'resp', url: x.origin + x.pathname, json: t });
        } catch (e) {}
      };
      var f = window.fetch;
      window.fetch = function (input) {
        var url = typeof input === 'string' ? input : (input && input.url) || String(input);
        var p = f.apply(this, arguments);
        p.then(function (r) { if (/json/i.test(r.headers.get('content-type') || '')) r.clone().text().then(function (t) { post(url, t); }).catch(function () {}); }).catch(function () {});
        return p;
      };
      var open = XMLHttpRequest.prototype.open, send = XMLHttpRequest.prototype.send;
      XMLHttpRequest.prototype.open = function (m, u) { this.__grPUrl = String(u); return open.apply(this, arguments); };
      XMLHttpRequest.prototype.send = function () {
        var xhr = this;
        xhr.addEventListener('load', function () { try { if (/json/i.test(xhr.getResponseHeader('content-type') || '')) post(xhr.__grPUrl, xhr.responseText); } catch (e) {} });
        return send.apply(this, arguments);
      };
    })();
    """#

    // Runs in every page before the site's own code. Nothing is recorded: it only notes the login headers
    // the site sends to its own API, in memory, so Import chats is logged in the same way
    static let loginHeaders = #"""
    (function () {
      if (window.__grWatch) return; window.__grWatch = true;
      window.__grAuth = window.__grAuth || {};
      var keep = function (u, name, value) {
        try {
          if (!/janitorai\.com\/hampter\//.test(new URL(u, location.href).href)) return;
          var n = String(name).toLowerCase();
          if (n === 'authorization' || /^x-/.test(n)) window.__grAuth[n] = String(value);
        } catch (e) {}
      };
      var note = function (u, h) {
        try {
          if (!h) return;
          if (typeof h.forEach === 'function' && !Array.isArray(h)) h.forEach(function (v, k) { keep(u, k, v); });
          else if (Array.isArray(h)) h.forEach(function (p) { keep(u, p[0], p[1]); });
          else Object.keys(h).forEach(function (k) { keep(u, k, h[k]); });
        } catch (e) {}
      };
      var realFetch = window.fetch;
      window.__grFetch = realFetch;
      window.fetch = function (input, init) {
        var url = typeof input === 'string' ? input : (input && input.url) || String(input);
        note(url, input && typeof input !== 'string' && input.headers);
        note(url, init && init.headers);
        return realFetch.apply(this, arguments);
      };
      var open = XMLHttpRequest.prototype.open, setHeader = XMLHttpRequest.prototype.setRequestHeader;
      XMLHttpRequest.prototype.open = function (m, u) { this.__grUrl = String(u); return open.apply(this, arguments); };
      XMLHttpRequest.prototype.setRequestHeader = function (k, v) { if (this.__grUrl) keep(this.__grUrl, k, v); return setHeader.apply(this, arguments); };
    })();
    """#
}
