import SwiftUI

@main
struct NMC_HackUTDApp: App {
    @StateObject private var session = PhoneSessionManager()
    @StateObject private var workOrderViewModel = WorkOrderViewModel()
    
    var body: some Scene {
        WindowGroup {
            NmcAppShell()
                .environmentObject(session)
                .environmentObject(workOrderViewModel)
        }
    }
}
