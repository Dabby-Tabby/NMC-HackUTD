import SwiftUI

@main
struct NMC_HackUTDApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "waveform.path.ecg") }

                VoiceChatView()
                    .tabItem { Label("Assistant", systemImage: "mic") }
            }
        }
    }
}
