import SwiftUI
import WebKit

// Мост: ссылка на webView и флаг возможности назад
final class PrivacyBridge: ObservableObject {
    @Published var canGoBack: Bool = false
    weak var webView: WKWebView?
    func goBack() { webView?.goBack() }
}

public struct PrivacyPage: View {
    public let url: URL
    public let onClose: (() -> Void)?
    @Environment(\.verticalSizeClass) private var vSize
    @StateObject private var bridge = PrivacyBridge()

    public init(url: URL, onClose: (() -> Void)? = nil) {
        self.url = url
        self.onClose = onClose
    }

    public var body: some View {
        GeometryReader { geo in
            let isPortrait = (vSize == .regular) || (geo.size.height >= geo.size.width)

            ZStack(alignment: .topLeading) {
                // Чёрный фон позади
                Color.black.ignoresSafeArea()

                // Вебвью + фиксированный нижний отступ 75 pt в портрете
                VStack(spacing: 0) {
                    _PrivacyPage(url: url, bridge: bridge, onClose: onClose)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if isPortrait {
                        Color.black.frame(height: 0).allowsHitTesting(false)
                    }
                }

                // Минималистичная кнопка "назад" у границы safe area
                Button {
                    if bridge.canGoBack {
                        bridge.goBack()
                    } else {
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(bridge.canGoBack ? 1.0 : 0.35))
                        .frame(width: 34, height: 34)
                        .background(Color.black.opacity(0.7), in: Circle())
                        .contentShape(Circle())
                }
                .padding(.top,  geo.safeAreaInsets.top)
                .padding(.leading, geo.safeAreaInsets.leading)
            }
        }
    }
}

private struct _PrivacyPage: UIViewRepresentable {
    let url: URL
    @ObservedObject var bridge: PrivacyBridge
    let onClose: (() -> Void)?

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate, ObservableObject {
        @Published var isLoading: Bool = true
        let bridge: PrivacyBridge
        let onClose: (() -> Void)?

        // Храним последние ДВЕ успешные страницы (http/https)
        private var lastURL: URL?   // последняя «хорошая»
        private var prevURL: URL?   // предпоследняя «хорошая»

        init(bridge: PrivacyBridge, onClose: (() -> Void)?) {
            self.bridge = bridge
            self.onClose = onClose
        }

        @objc func didTap(_ recognizer: UITapGestureRecognizer) {
            RatePrompt.registerTap(source: "web")
        }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        // MARK: — Навигация

        // До загрузки: ловим спец-URL, например privacypolicypage → сразу закрыть WebView
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

            if let u = navigationAction.request.url?.absoluteString.lowercased(),
               u.contains("privacypolicypage") {

                decisionHandler(.cancel)
                DispatchQueue.main.async { self.onClose?() }
                return
            }

            decisionHandler(.allow)
        }

        // Как только контент начал приходить — обновляем пару (prev,last) и ПИШЕМ prev в хранилище
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            bridge.canGoBack = webView.canGoBack
            guard let u = webView.url, let scheme = u.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else { return }

            // сдвиг: prev ← last, last ← current
            if let last = lastURL { prevURL = last }
            lastURL = u

            if let prev = prevURL {
                StartMenuStorage.saveMenu(prev.absoluteString)

            } else {

            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            bridge.canGoBack = webView.canGoBack
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(bridge: bridge, onClose: onClose) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let webview = WKWebView(frame: .zero, configuration: config)
        context.coordinator.bridge.webView = webview

        webview.navigationDelegate = context.coordinator
        webview.uiDelegate = context.coordinator
        webview.allowsBackForwardNavigationGestures = true

        // наблюдение за загрузкой/историей (для логов/кнопки назад)
        webview.addObserver(context.coordinator, forKeyPath: "loading",  options: .new, context: nil)
        webview.addObserver(context.coordinator, forKeyPath: "canGoBack", options: .new, context: nil)

        // счётчик тапов
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator
        webview.addGestureRecognizer(tap)

        webview.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
        return webview
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.removeObserver(coordinator, forKeyPath: "loading")
        uiView.removeObserver(coordinator, forKeyPath: "canGoBack")
    }
}

private extension _PrivacyPage.Coordinator {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let web = object as? WKWebView else { return }
        if keyPath == "loading" {
            isLoading = web.isLoading
        } else if keyPath == "canGoBack" {
            bridge.canGoBack = web.canGoBack

        }
    }
}

// Совместимость со старым именем
public typealias StartMenuWebView = PrivacyPage
