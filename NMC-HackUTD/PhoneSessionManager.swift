//
//  PhoneSessionManager.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import Foundation
import WatchConnectivity
import UserNotifications
import UIKit
import Combine

class PhoneSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var heartRate: Double = 0
    @Published var oxygen: Double = 0
    @Published var energy: Double = 0
    
    // ping UI state
    @Published var lastPingFrom: String? = nil
    
    private var session: WCSession?
    
    override init() {
        super.init()
        requestNotificationPermission()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            self.session = session
            session.activate()
            print("📡 iPhone: activating WCSession...")
        } else {
            print("❌ WCSession not supported")
        }
    }
    
    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let e = error { print("Notif auth error: \(e.localizedDescription)") }
            print("Notif permission granted: \(granted)")
        }
    }
    
    private func postLocalNotification(from sender: String) {
        let content = UNMutableNotificationContent()
        content.title = "PulseLink Ping"
        content.body = "You've been pinged by \(sender)"
        content.sound = .default
        
        let req = UNNotificationRequest(identifier: "PulseLinkPing_\(UUID().uuidString)",
                                        content: content,
                                        trigger: nil) // deliver immediately
        UNUserNotificationCenter.current().add(req) { error in
            if let e = error { print("Failed to schedule notification: \(e.localizedDescription)") }
        }
    }
    
    private func performHaptic() {
        // Use a notification-style haptic on iPhone
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("📡 iPhone WCSession activation: \(activationState.rawValue) error: \(String(describing: error))")
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // Handle health updates as before
            if let hr = message["heartRate"] as? Double {
                self.heartRate = hr
            }
            if let ox = message["oxygen"] as? Double {
                self.oxygen = ox
            }
            if let en = message["energy"] as? Double {
                self.energy = en
            }
            
            // Handle ping message
            if let type = message["type"] as? String, type == "ping",
               let from = message["from"] as? String {
                print("📩 Received ping from \(from)")
                
                // Update UI state (shows banner)
                self.lastPingFrom = from
                
                // Haptic feedback if app is active/in foreground
                self.performHaptic()
                
                // If app is backgrounded, post a local notification anyway
                let state = UIApplication.shared.applicationState
                if state != .active {
                    self.postLocalNotification(from: from)
                }
                
                // Auto-clear the banner after 5s
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.lastPingFrom = nil
                }
            }
        }
    }
}
