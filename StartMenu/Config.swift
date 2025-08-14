import Foundation

/// Central config for IDs and remote assets.
enum StartupConfig {
    // Remote title image with EXIF (Image Description)
    static let titleImageURL = URL(string: "https://github.com/DannyOceanGamesTest/dogt/blob/main/IconTitle.jpg?raw=true")!

    // AppsFlyer keys (REQUIRED)
    static let appsFlyerDevKey: String = "hewwVhT8ZaCvQfTjGi66ME"   // e.g. "abcd1234..."
    static let appsFlyerAppID: String = "6749445226"      // numeric string from App Store Connect

    // OneSignal app id (OPTIONAL) — empty by default means disabled
    static let oneSignalAppID: String = "25b49bc3-5c13-479c-ab7b-a8ccb2d3d232" // e.g. "559954f0-36e3-4458-b9cf-c2832912cb5e"
}
