//
//  PhoneSessionManager.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import Foundation
import MultipeerConnectivity
import WatchConnectivity
import UserNotifications
import UIKit
import Combine
import SwiftUI

class PhoneSessionManager: NSObject, ObservableObject {
    // MARK: - Published Data
    @Published var heartRate: Double = 0
    @Published var oxygen: Double = 0
    @Published var energy: Double = 0
    @Published var lastPingFrom: String? = nil
    @Published var connectedPeers: [MCPeerID] = []
    @Published var myDisplayName: String = "Unknown"
    
    // MARK: - Multipeer Connectivity
    private let serviceType = "pulselink-peer" // must match on both devices
    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // Watch session
    private var wcSession: WCSession?
    
    // Prevent double invites
    private var isConnecting: Set<MCPeerID> = []
    
    // MARK: - Init
    override init() {
        super.init()
        requestNotificationPermission()
        
        // ✅ Activate WCSession if supported
        if WCSession.isSupported() {
            let wcSession = WCSession.default
            wcSession.delegate = self
            self.wcSession = wcSession
            wcSession.activate()
            print("📡 iPhone: activating WCSession...")
        } else {
            print("❌ WCSession not supported")
        }
    }
    
    // MARK: - Name / Display Updates
    func updateDisplayName(_ name: String) {
        myDisplayName = name
        print("🪪 Updated display name to \(name)")
    }
    
    // MARK: - Multipeer Setup
    func startAdvertising() {
        guard advertiser == nil, browser == nil else {
            print("⚠️ Already advertising/browsing.")
            return
        }
        
        peerID = MCPeerID(displayName: myDisplayName)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        print("📣 Started advertising/browsing as \(myDisplayName)")
    }
    
    func resetConnection() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        connectedPeers.removeAll()
        print("♻️ Reset connection state.")
        startAdvertising()
    }
    
    // MARK: - Ping peers
    func sendPing(to peer: MCPeerID) {
        guard let session = session else { return }
        let message: [String: Any] = [
            "type": "ping",
            "from": myDisplayName
        ]
        if session.connectedPeers.contains(peer) {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: message, requiringSecureCoding: false)
                try session.send(data, toPeers: [peer], with: .reliable)
                print("📤 Ping sent to \(peer.displayName)")
            } catch {
                print("❌ Failed to send ping: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let e = error { print("Notif auth error: \(e.localizedDescription)") }
            print("🔔 Notification permission granted: \(granted)")
        }
    }
    
    private func postLocalNotification(from sender: String) {
        let content = UNMutableNotificationContent()
        content.title = "PulseLink Ping"
        content.body = "You've been pinged by \(sender)"
        content.sound = .default
        
        let req = UNNotificationRequest(identifier: "PulseLinkPing_\(UUID().uuidString)",
                                        content: content,
                                        trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}

//
// MARK: - MCSessionDelegate
//
extension PhoneSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ Connected to \(peerID.displayName)")
                withAnimation(.spring()) {
                    if !self.connectedPeers.contains(peerID) {
                        self.connectedPeers.append(peerID)
                    }
                }
                // Add filler vitals for demo
                self.heartRate = Double.random(in: 65...95)
                self.oxygen = Double.random(in: 96...100)
                self.energy = Double.random(in: 120...160)
                
            case .notConnected:
                print("❌ Disconnected from \(peerID.displayName)")
                withAnimation(.easeOut) {
                    self.connectedPeers.removeAll { $0 == peerID }
                }
                self.isConnecting.remove(peerID)
                
            case .connecting:
                print("🔄 Connecting to \(peerID.displayName)")
                self.isConnecting.insert(peerID)
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: Any] else { return }
        
        if let type = message["type"] as? String, type == "ping",
           let from = message["from"] as? String {
            print("📩 Received ping from \(from)")
            DispatchQueue.main.async {
                self.lastPingFrom = from
                self.postLocalNotification(from: from)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.lastPingFrom = nil
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

//
// MARK: - MCNearbyServiceAdvertiserDelegate + MCNearbyServiceBrowserDelegate
//
extension PhoneSessionManager: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Failed to advertise: \(error.localizedDescription)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Failed to browse: \(error.localizedDescription)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        guard peerID.displayName != myDisplayName,
              !connectedPeers.contains(peerID),
              !isConnecting.contains(peerID) else { return }

        print("👀 Found peer: \(peerID.displayName)")

        // Invite only if my display name sorts before theirs
        if self.peerID.displayName < peerID.displayName {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
            print("📨 Sent invite to \(peerID.displayName)")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("👋 Lost peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            withAnimation(.easeOut) {
                self.connectedPeers.removeAll { $0 == peerID }
            }
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📩 Received connection invite from \(peerID.displayName)")
        invitationHandler(true, session)
    }
}

//
// MARK: - WCSessionDelegate
//
extension PhoneSessionManager: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("📡 WCSession activation: \(activationState.rawValue) error: \(String(describing: error))")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("⌚️ Watch session state changed: \(session.activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}
