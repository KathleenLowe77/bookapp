import SwiftUI
import WebKit

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.en.rawValue
    @AppStorage("dailyGoal") private var dailyGoal: Int = 20
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false

    @State private var showDeniedAlert = false

    // MARK: - In-app WKWebView state (sheet with Identifiable item)
    private let policyURL = URL(string: "https://www.termsfeed.com/live/c2de7e32-8b09-471f-92f7-00bd836be565")!
    @State private var webTarget: WebTarget?

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("App language", selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appThemeRaw) {
                        ForEach(AppTheme.allCases) { t in
                            Text(t.title).tag(t.rawValue)
                        }
                    }
                }

                Section("Daily Goal") {
                    Stepper(value: $dailyGoal, in: 0...200, step: 5) {
                        if dailyGoal > 0 {
                            Text("\(dailyGoal) pages/day")
                        } else {
                            Text("No daily goal")
                        }
                    }
                    Text("Track how many pages you read each day.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        webTarget = .privacy(policyURL)
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Button {
                        webTarget = .support(policyURL)
                    } label: {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background((AppTheme(rawValue: appThemeRaw) ?? .system).backgroundColor.ignoresSafeArea())
            .navigationTitle("Settings")
            .alert("Notifications are disabled", isPresented: $showDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Allow notifications in iOS Settings to receive daily reminders.")
            }
            .sheet(item: $webTarget) { target in
                WebContainer(url: target.url)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Identifiable wrapper for sheet(item:)
private enum WebTarget: Identifiable {
    case privacy(URL)
    case support(URL)

    var id: String {
        switch self {
        case .privacy(let url): return "privacy::\(url.absoluteString)"
        case .support(let url): return "support::\(url.absoluteString)"
        }
    }

    var url: URL {
        switch self {
        case .privacy(let url), .support(let url): return url
        }
    }
}

// MARK: - WKWebView container with simple nav + progress
private struct WebContainer: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var progress: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button {
                    NotificationCenter.default.post(name: .webViewGoBack, object: nil)
                } label: { Image(systemName: "chevron.left") }
                .disabled(!canGoBack)

                Button {
                    NotificationCenter.default.post(name: .webViewGoForward, object: nil)
                } label: { Image(systemName: "chevron.right") }
                .disabled(!canGoForward)

                Spacer()
                Button("Done") { dismiss() }
                    .font(.headline)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            if progress < 1.0 {
                ProgressView(value: progress)
                    .padding(.horizontal)
            }

            WebView(url: url,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    estimatedProgress: $progress)
        }
        .background(Color(.systemBackground))
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var estimatedProgress: Double

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // KVO for props
        webView.addObserver(context.coordinator, forKeyPath: "canGoBack", options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: "canGoForward", options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)

        // Notifications for external back/forward
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.goBack), name: .webViewGoBack, object: nil)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.goForward), name: .webViewGoForward, object: nil)

        webView.load(URLRequest(url: url))
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.removeObserver(coordinator, forKeyPath: "canGoBack")
        uiView.removeObserver(coordinator, forKeyPath: "canGoForward")
        uiView.removeObserver(coordinator, forKeyPath: "estimatedProgress")
        NotificationCenter.default.removeObserver(coordinator, name: .webViewGoBack, object: nil)
        NotificationCenter.default.removeObserver(coordinator, name: .webViewGoForward, object: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        weak var webView: WKWebView?

        init(_ parent: WebView) { self.parent = parent }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                   change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard let webView = object as? WKWebView else { return }
            switch keyPath {
            case "canGoBack": parent.canGoBack = webView.canGoBack
            case "canGoForward": parent.canGoForward = webView.canGoForward
            case "estimatedProgress": parent.estimatedProgress = webView.estimatedProgress
            default: break
            }
        }

        @objc func goBack() { webView?.goBack() }
        @objc func goForward() { webView?.goForward() }
    }
}

private extension Notification.Name {
    static let webViewGoBack = Notification.Name("SettingsWebViewGoBack")
    static let webViewGoForward = Notification.Name("SettingsWebViewGoForward")
}
