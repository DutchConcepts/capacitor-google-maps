import UIKit
import Capacitor
import GoogleMaps

class CustomOfflineView: UIView {
    let webView: WKWebView

    let serverURL: URL

    let loadingLabel: UILabel

    init (webView: WKWebView, serverURL: URL) {
        self.webView = webView

        self.serverURL = serverURL

        self.loadingLabel = UILabel()

        super.init(frame: CGRect.zero)
        createSubViews()
    }

    override init(frame: CGRect) {
        fatalError("init(coder:) has not been implemented")
    }

    init (labelText: String) {
        fatalError("init(coder:) has not been implemented")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction
    func offlineReloadButtonClicked() {
        self.loadingLabel.isHidden = false
        self.webView.load(URLRequest(url: self.serverURL))
    }

    // Creating subview
    private func createSubViews() {
        backgroundColor = .orange

        // Descriptive text
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        label.text = "Failed loading Amigos"

        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Reload button
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        button.backgroundColor = UIColor.purple
        button.layer.cornerRadius = 5
        button.setTitle("Reload", for: UIControl.State.normal)
        button.setTitleColor(UIColor.white, for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        button.addTarget(self, action: #selector(self.offlineReloadButtonClicked), for: .touchUpInside)

        addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 50)
        ])

        // Loading indicator
        self.loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        self.loadingLabel.textColor = UIColor.white
        self.loadingLabel.numberOfLines = 0
        self.loadingLabel.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        self.loadingLabel.text = "Loading..."
        self.loadingLabel.isHidden = true

        addSubview(self.loadingLabel)

        NSLayoutConstraint.activate([
            self.loadingLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.loadingLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 100)
        ])
    }

}

class CustomWKWebView: WKWebView {
    var customMapViews = [String : CustomMapView]();

    public var customOfflineView: CustomOfflineView? = nil

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if (self.customOfflineView?.isHidden ?? true) {
            let values = self.customMapViews.map({ $0.value })
            for customMapView in values {
                let convertedPoint = self.convert(point, to: customMapView.GMapView)
                let mapView = customMapView.GMapView.hitTest(convertedPoint, with: event)
                let contentView = scrollView.subviews[self.customMapViews.count]

                if (mapView != nil), contentView.layer.pixelColorAtPoint(point: point) == true{
                    return mapView
                }
            }
        }
        return view
    }
}

open class CustomMapViewController: CAPBridgeViewController, UIScrollViewDelegate, WKNavigationDelegate {
    var customWKWebView: CustomWKWebView? = nil

    open override func viewDidLoad() {
        webView?.navigationDelegate = self
        super.viewDidLoad()

        let serverURL = self.bridge?.config.serverURL

        if (self.customWKWebView?.customOfflineView == nil && serverURL != nil) {
            self.customWKWebView?.customOfflineView = CustomOfflineView(webView: self.webView!, serverURL: serverURL!)

            if (self.customWKWebView?.customOfflineView != nil) {
                self.customWKWebView!.customOfflineView!.translatesAutoresizingMaskIntoConstraints = false

                self.customWKWebView!.customOfflineView!.isHidden = true

                self.webView?.scrollView.addSubview(self.customWKWebView!.customOfflineView!)

                NSLayoutConstraint.activate([
                    self.customWKWebView!.customOfflineView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    self.customWKWebView!.customOfflineView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    self.customWKWebView!.customOfflineView!.topAnchor.constraint(equalTo: view.topAnchor),
                    self.customWKWebView!.customOfflineView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                ])

                self.webView?.scrollView.bringSubviewToFront(self.customWKWebView!.customOfflineView!)
            }
        }
    }

    open override func webView(with frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        self.customWKWebView = CustomWKWebView(frame: frame, configuration: configuration)
        return self.customWKWebView ?? CustomWKWebView(frame: frame, configuration: configuration);
    }

    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.customWKWebView?.customOfflineView?.isHidden = true
        self.customWKWebView?.customOfflineView?.loadingLabel.isHidden = true
    }

    open func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.customWKWebView?.customOfflineView?.isHidden = false
        self.customWKWebView?.customOfflineView?.loadingLabel.isHidden = true
    }

    open func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.customWKWebView?.customOfflineView?.isHidden = false
        self.customWKWebView?.customOfflineView?.loadingLabel.isHidden = true
    }
}
