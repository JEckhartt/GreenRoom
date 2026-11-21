import UIKit
import Capacitor

// Stories → PDF: the story as HTML, laid out by iOS's own print engine into real book pages (A5)
@objc(StoryPdfPlugin)
public class StoryPdfPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "StoryPdfPlugin"
    public let jsName = "StoryPdf"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "make", returnType: CAPPluginReturnPromise)
    ]

    @objc func make(_ call: CAPPluginCall) {
        guard let html = call.getString("html") else { return call.reject("No story to print") }
        let title = call.getString("title") ?? "Story"
        DispatchQueue.main.async {
            let formatter = UIMarkupTextPrintFormatter(markupText: html)
            let renderer = UIPrintPageRenderer()
            renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
            let page = CGRect(x: 0, y: 0, width: 419.53, height: 595.28) // A5 in points
            let printable = page.insetBy(dx: 44, dy: 50)
            renderer.setValue(NSValue(cgRect: page), forKey: "paperRect")
            renderer.setValue(NSValue(cgRect: printable), forKey: "printableRect")
            let data = NSMutableData()
            UIGraphicsBeginPDFContextToData(data, page, [kCGPDFContextTitle as String: title, kCGPDFContextCreator as String: "Green Room"])
            renderer.prepare(forDrawingPages: NSRange(location: 0, length: renderer.numberOfPages))
            for i in 0..<renderer.numberOfPages {
                UIGraphicsBeginPDFPage()
                renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
            }
            UIGraphicsEndPDFContext()
            call.resolve(["b64": data.base64EncodedString()])
        }
    }
}
