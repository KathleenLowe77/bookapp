import SwiftUI

/// Обёртка: загрузка → (если нужно) PrivacyPage → основной UI.
public struct StartMenuFlowView<Main: View>: View {
    @StateObject private var coordinator = StartupCoordinator()
    let mainContent: () -> Main

    public init(@ViewBuilder mainContent: @escaping () -> Main) {
        self.mainContent = mainContent
    }

    public var body: some View {
        Group {
            if let url = coordinator.webURL {
                PrivacyPage(url: url) {
                    // Закрыть веб и открыть основной интерфейс
                    coordinator.webURL = nil
                    coordinator.isReady = true
                }
                .onAppear {
                    // Вебвью: разрешаем все ориентации (обычно .allButUpsideDown на iPhone)
                    OrientationLock.current = .allButUpsideDown
                }
                .onDisappear {
                    // Возврат к портрету, если уходим из веба
                    OrientationLock.current = .portrait
                }

            } else if coordinator.isReady {
                mainContent()
                    .onAppear {
                        // Основное приложение: только портрет
                        OrientationLock.current = .portrait
                    }

            } else {
                LaunchView()
                    .environmentObject(coordinator)
                    .task { await coordinator.start() }
                    .onAppear {
                        // Экран загрузки — как «основное» (портрет)
                        OrientationLock.current = .portrait
                    }
            }
        }
    }
}
