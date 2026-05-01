import SwiftUI
import WidgetKit

@main
struct PlantCareApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                } else {
                    Group {
                        if hasCompletedOnboarding {
                            MainTabView()
                                .transition(.opacity)
                        } else {
                            OnboardingView {
                                hasCompletedOnboarding = true
                            }
                            .transition(.opacity)
                        }
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                    // App启动时刷新Widget数据
                    PlantCareService.shared.refreshWidgetData()
                }
            }
        }
    }
}
