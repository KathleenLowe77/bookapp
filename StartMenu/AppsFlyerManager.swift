import Foundation
#if canImport(AppsFlyerLib)
import AppsFlyerLib
#endif

final class AppsFlyerManager: NSObject {
    static let shared = AppsFlyerManager()
    private override init() {}

    struct Conversion {
        let rawCampaign: String?
        let subsQuery: String // e.g. sub1=val1&sub2=val2 or fallback "sub1-organic"
        let status: String?   // af_status
    }

    private(set) var appsFlyerID: String? // af_id
    private(set) var conversion: Conversion?

    func initializeAndStart() async {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().appsFlyerDevKey = StartupConfig.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = StartupConfig.appsFlyerAppID
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().isDebug = true
        
        // Start SDK
        DispatchQueue.main.async {
            AppsFlyerLib.shared().start()
        }
        self.appsFlyerID = AppsFlyerLib.shared().getAppsFlyerUID()
        #else

#endif
    }
}

#if canImport(AppsFlyerLib)
extension AppsFlyerManager: AppsFlyerLibDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable : Any]) {
        let status = data["af_status"] as? String
        let campaign = data["campaign"] as? String

        let isNonOrganic = (status?.lowercased() == "non-organic")
        let subs: String
        if isNonOrganic, let campaign, !campaign.isEmpty {
            // Expect val1_val2_val3 → sub1=val1&sub2=val2&sub3=val3
            let parts = campaign.split(separator: "_").map(String.init)
            if parts.isEmpty {
                subs = "sub1=organic"
            } else {
                subs = parts.enumerated().map { idx, val in
                    "sub\(idx+1)=\(val)"
                }.joined(separator: "&")
            }
        } else {
            subs = "sub1=organic"
        }
        self.conversion = Conversion(rawCampaign: campaign, subsQuery: subs, status: status)

    }

    func onConversionDataFail(_ error: Error) {

        self.conversion = Conversion(rawCampaign: nil, subsQuery: "sub1=organic", status: nil)
    }
}
#endif
