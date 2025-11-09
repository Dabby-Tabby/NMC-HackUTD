import SwiftUI

@main
struct NMC_HackUTDApp: App {
    @StateObject private var session = PhoneSessionManager()
    
    var body: some Scene {
        WindowGroup {
            NmcAppShell()
                .environmentObject(session)
        }
    }
}
