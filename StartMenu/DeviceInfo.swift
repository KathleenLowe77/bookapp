import Foundation
import UIKit
import SystemConfiguration.CaptiveNetwork
import Network
import StoreKit

enum DeviceInfoCollector {
    struct Info {
        let region: String
        let locale: String
        let model: String
        let device: String
        let version: String
        let proxy: Bool
        let vpn: Bool
        let store: String
        let timezone: String
        
        var queryString: String {
            let parts: [String: String] = [
                "region": region,
                "locale": locale,
                "model": model,
                "device": device,
                "version": version,
                "proxy": proxy ? "true" : "false",
                "vpn": vpn ? "true" : "false",
                "store": store,
                "timezone": timezone
            ]
            return parts.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        }
    }

    static func collect() async -> Info {
        let region = Locale.current.region?.identifier.lowercased() ?? "us"
        let locale = Locale.current.identifier.replacingOccurrences(of: "-", with: "_").lowercased()
        let model = "arm64" // modern iOS devices
        let version = UIDevice.current.systemVersion
        let device = marketingNameFallback()
        let vpn = isVPNActive()
        let proxy = isProxyConfigured()
        let timezone = TimeZone.current.identifier
        let store = await storefrontCountryCode()?.lowercased() ?? region

        return Info(region: region,
                    locale: locale,
                    model: model,
                    device: device,
                    version: version,
                    proxy: proxy,
                    vpn: vpn,
                    store: store,
                    timezone: timezone)
    }

    private static func isVPNActive() -> Bool {
        // heuristic: presence of utun/ppp/ipsec interfaces
        guard let dict = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scoped = dict["__SCOPED__"] as? [String: Any] else { return false }
        return scoped.keys.contains { key in
            key.contains("tap") || key.contains("tun") || key.contains("ppp") || key.contains("ipsec") || key.contains("utun")
        }
    }

    private static func isProxyConfigured() -> Bool {
        // Cross-platform proxy detection without using HTTPS-specific key
        guard let cfSettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() else { return false }
        let testURL = URL(string: "https://example.com")! as CFURL
        let proxiesCF = CFNetworkCopyProxiesForURL(testURL, cfSettings).takeRetainedValue()
        let proxies = proxiesCF as NSArray
        guard let first = proxies.firstObject as? [String: Any],
              let type = first[kCFProxyTypeKey as String] as? String else {
            return false
        }
        // If type is "kCFProxyTypeNone" → no proxy; otherwise some proxy/PAC/WPAD/SOCKS/HTTP is in effect
        return type != (kCFProxyTypeNone as String)
    }

    private static func storefrontCountryCode() async -> String? {
        if #available(iOS 13.0, *) {
            // Requires StoreKit import; works even without IAP setup in most cases.
            return await withCheckedContinuation { cont in
                DispatchQueue.main.async {
                    let code = SKPaymentQueue.default().storefront?.countryCode
                    cont.resume(returning: code)
                }
            }
        } else { return nil }
    }

    private static func marketingNameFallback() -> String {
        // Use hardware identifier if available, else UIDevice model
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: 1) { cptr in
                String(cString: cptr)
            }
        }
        // e.g. iPhone16,2 → iPhone16.2
        return machine.replacingOccurrences(of: ",", with: ".")
    }
}
