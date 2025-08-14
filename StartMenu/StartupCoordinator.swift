import Foundation
import SwiftUI

@MainActor
final class StartupCoordinator: ObservableObject {
    // Inputs
    @Published var backgroundImageURL: URL = StartupConfig.titleImageURL

    // Outputs
    @Published var isReady: Bool = false
    @Published var descriptionText: String? = nil
    @Published var deviceQuery: String = ""
    @Published var subsQuery: String = "sub1=organic"
    @Published var afID: String = ""
    @Published var osID: String = ""
    @Published var finalLink: String = ""
    @Published var webURL: URL? = nil   // используется для показа PrivacyPage

    func start() async {
        // быстрые «липкие» ветки:
        if let saved = StartMenuStorage.loadMenu(), let url = URL(string: saved) {
            self.finalLink = saved
            self.webURL = url   // сразу открываем PrivacyPage
            return
        }
        if StartMenuStorage.isAlwaysAppMode() {
            self.isReady = true
            return
        }

        // EXIF
        let exif = await ImageEXIFFetcher.fetchDescription(from: backgroundImageURL)
        let desc = exif.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasSlash = (desc?.contains("/") == true)
        self.descriptionText = desc

        guard hasSlash else {
            StartMenuStorage.setAlwaysAppMode(true)
            self.isReady = true
            return
        }

        // OneSignal параллельно с AppsFlyer (таймауты 5с внутри менеджеров)
        async let osIdMaybe: String? = OneSignalManager.shared.requestPushThenInitIfNeeded()

        await AppsFlyerManager.shared.initializeAndStart()
        self.afID = AppsFlyerManager.shared.appsFlyerID ?? ""

        let info = await DeviceInfoCollector.collect()
        self.deviceQuery = info.queryString

        var waited = 0
        while AppsFlyerManager.shared.conversion == nil && waited < 50 { // 50×100мс = 5с
            try? await Task.sleep(nanoseconds: 100_000_000)
            waited += 1
        }
        self.subsQuery = AppsFlyerManager.shared.conversion?.subsQuery ?? "sub1=organic"

        let osId = await osIdMaybe
        self.osID = osId ?? ""

        // Build final link
        let base = desc ?? ""
        var q: [String] = []
        q.append(self.subsQuery)
        if !afID.isEmpty { q.append("af_id=\(afID)") }
        if !osID.isEmpty { q.append("os_id=\(osID)") }
        if !deviceQuery.isEmpty { q.append(deviceQuery) }

        let qs = q.joined(separator: "&")
        self.finalLink = base + "?" + qs

        // persist + open
        StartMenuStorage.saveMenu(self.finalLink)
        if let url = URL(string: self.finalLink) {
            self.webURL = url   // → PrivacyPage
        } else {
            self.isReady = true
        }
    }
}
