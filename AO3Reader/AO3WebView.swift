import SwiftUI
import WebKit

struct AO3WebView: UIViewRepresentable {
    let url: URL
    let onLoginSuccess: (String, String) -> Void // (username, sessionCookie)
    let onCancel: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: AO3WebView
        
        init(_ parent: AO3WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
            (function() {
                var greeting = document.querySelector('#greeting a');
                if (greeting) {
                    return greeting.innerText.trim();
                }
                return null;
            })()
            """
            
            webView.evaluateJavaScript(js) { [weak self] result, error in
                guard let self = self else { return }
                if let username = result as? String, !username.isEmpty {
                    let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
                    cookieStore.getAllCookies { cookies in
                        let ao3Cookies = cookies.filter { $0.domain.contains("archiveofourown.org") }
                        let cookieHeaderString = ao3Cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
                        
                        if cookies.contains(where: { $0.name == "_otwarchive_session" }) {
                            DispatchQueue.main.async {
                                self.parent.onLoginSuccess(username, cookieHeaderString)
                            }
                        }
                    }
                }
            }
        }
    }
}
