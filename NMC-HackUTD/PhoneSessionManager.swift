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
import CoreHaptics

final class PhoneSessionManager: NSObject, ObservableObject {
    // MARK: - Published Data
    @Published var heartRate: Double = 0
    @Published var oxygen: Double = 0
    @Published var energy: Double = 0
    @Published var lastPingFrom: String?
    @Published var connectedPeers: [MCPeerID] = []
    @Published var myDisplayName: String = "Unknown"
    
    @AppStorage("localOwnerID") private var storedOwnerID: String = UUID().uuidString

    /// ID you should use for things like WorkOrder.ownerID
    var ownerID: String {
        storedOwnerID
    }

    /// Human-readable name to show in the UI
    var ownerName: String {
        myDisplayName
    }
    
    @Published var isWatchSessionActive: Bool = false

    /// Per-peer vitals dictionary
    @Published var peerVitals: [String: (heart: Double, oxygen: Double, energy: Double)] = [:]

    /// Per-peer work orders (decoded from MC messages)
    @Published var peerWorkOrders: [String: [WorkOrder]] = [:]

    // MARK: - Multipeer Connectivity
    private let serviceType = "pulselink-peer"
    private var peerID: MCPeerID!
    private var mcSession: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var isConnecting: Set<MCPeerID> = []

    // MARK: - WatchConnectivity
    private var wcSession: WCSession?

    // MARK: - Core Haptics
    private var hapticEngine: CHHapticEngine?

    // MARK: - Init
    override init() {
        super.init()
        requestNotificationPermission()
        prepareHaptics()

        if WCSession.isSupported() {
            let wc = WCSession.default
            wc.delegate = self
            self.wcSession = wc
            wc.activate()
            print("📡 iPhone: activating WCSession…")
        } else {
            print("❌ WCSession not supported")
        }
    }

    // MARK: - Display Name & Setup
    func updateDisplayName(_ name: String) {
        myDisplayName = name
        print("🪪 Updating display name to \(name)")

        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil
        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
        mcSession?.disconnect()

        peerID = MCPeerID(displayName: myDisplayName)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.advertiser = MCNearbyServiceAdvertiser(peer: self.peerID,
                                                        discoveryInfo: nil,
                                                        serviceType: self.serviceType)
            self.advertiser?.delegate = self
            self.advertiser?.startAdvertisingPeer()

            self.browser = MCNearbyServiceBrowser(peer: self.peerID,
                                                  serviceType: self.serviceType)
            self.browser?.delegate = self
            self.browser?.startBrowsingForPeers()

            print("📣 Restarted advertising & browsing as \(self.myDisplayName)")
        }
    }

    func startAdvertising() {
        guard advertiser == nil, browser == nil else {
            print("⚠️ Already advertising/browsing.")
            return
        }
        peerID = MCPeerID(displayName: myDisplayName)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self

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

    // MARK: - Ping Peers
    func sendPing(to peer: MCPeerID) {
        guard let session = mcSession else { return }
        let msg: [String: Any] = ["type": "ping", "from": myDisplayName]
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: msg, requiringSecureCoding: false)
            try session.send(data, toPeers: [peer], with: .reliable)
            print("📤 Ping sent to \(peer.displayName)")
        } catch {
            print("❌ Ping send error: \(error.localizedDescription)")
        }
    }

    // MARK: - Work Orders over MC

    /// Request work orders from a specific peer
    func requestWorkOrders(from peer: MCPeerID) {
        guard let session = mcSession else { return }
        let msg: [String: Any] = [
            "type": "requestWorkOrders",
            "from": myDisplayName
        ]
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: msg, requiringSecureCoding: false)
            try session.send(data, toPeers: [peer], with: .reliable)
            print("📤 Requested work orders from \(peer.displayName)")
        } catch {
            print("❌ requestWorkOrders send error: \(error.localizedDescription)")
        }
    }

    /// Send our current work orders to a specific peer
    func sendWorkOrders(to peer: MCPeerID, orders: [WorkOrder]) {
        guard let session = mcSession else { return }
        do {
            let payload = try JSONEncoder().encode(orders)
            let msg: [String: Any] = [
                "type": "workOrders",
                "from": myDisplayName,
                "payload": payload
            ]
            let data = try NSKeyedArchiver.archivedData(withRootObject: msg, requiringSecureCoding: false)
            try session.send(data, toPeers: [peer], with: .reliable)
            print("📤 Sent \(orders.count) work orders to \(peer.displayName)")
        } catch {
            print("❌ workOrders encode/send error: \(error.localizedDescription)")
        }
    }

    /// Broadcast our current work orders to all connected peers
    func broadcastWorkOrders(_ orders: [WorkOrder]) {
        guard let session = mcSession, !session.connectedPeers.isEmpty else { return }
        do {
            let payload = try JSONEncoder().encode(orders)
            let msg: [String: Any] = [
                "type": "workOrders",
                "from": myDisplayName,
                "payload": payload
            ]
            let data = try NSKeyedArchiver.archivedData(withRootObject: msg, requiringSecureCoding: false)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("📤 Broadcasted \(orders.count) work orders to \(session.connectedPeers.count) peers")
        } catch {
            print("⚠️ workOrders broadcast error: \(error.localizedDescription)")
        }
    }

    // MARK: - Local Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { ok, err in
            if let e = err { print("Notif auth error: \(e.localizedDescription)") }
            print("🔔 Notification permission granted: \(ok)")
        }
    }

    private func postLocalNotification(from sender: String) {
        let content = UNMutableNotificationContent()
        content.title = "PulseLink Ping"
        content.body = "You've been pinged by \(sender)"
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    // MARK: - Haptics
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ Device does not support haptics.")
            return
        }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            print("🎧 Haptic engine ready.")
        } catch {
            print("⚠️ Haptic engine error: \(error.localizedDescription)")
        }
    }

    private func playLongHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            let event = CHHapticEvent(eventType: .hapticContinuous,
                                      parameters: [intensity, sharpness],
                                      relativeTime: 0,
                                      duration: 0.6)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
            print("🔊 Played long haptic buzz.")
        } catch {
            print("⚠️ Failed to play haptic: \(error.localizedDescription)")
        }
    }

    // MARK: - Ping Watch
    private func sendPingToWatch() {
        guard let wcSession = wcSession, wcSession.isReachable else {
            print("⌚️ Watch not reachable, playing local haptic instead.")
            self.playLongHaptic()
            return
        }
        wcSession.sendMessage(["type": "ping"], replyHandler: nil) { error in
            print("⚠️ Failed to ping watch: \(error.localizedDescription)")
        }
        print("📲 Sent ping message to watch.")
    }
}

// MARK: - MCSessionDelegate
extension PhoneSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ Connected to \(peerID.displayName)")
                withAnimation(.spring()) {
                    if !self.connectedPeers.contains(peerID) { self.connectedPeers.append(peerID) }
                }
            case .notConnected:
                print("❌ Disconnected from \(peerID.displayName)")
                withAnimation(.easeOut) { self.connectedPeers.removeAll { $0 == peerID } }
                self.isConnecting.remove(peerID)
            case .connecting:
                print("🔄 Connecting to \(peerID.displayName)")
                self.isConnecting.insert(peerID)
            @unknown default: break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: Any],
              let type = message["type"] as? String else { return }

        switch type {
        case "ping":
            if let from = message["from"] as? String {
                print("📩 Received ping from \(from)")
                DispatchQueue.main.async {
                    self.lastPingFrom = from
                    self.postLocalNotification(from: from)
                    self.sendPingToWatch()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.lastPingFrom = nil
                    }
                }
            }

        case "vitals":
            guard
                let sender = message["from"] as? String,
                let hr = message["heartRate"] as? Double,
                let ox = message["oxygen"] as? Double,
                let en = message["energy"] as? Double
            else { return }
            DispatchQueue.main.async {
                self.peerVitals[sender] = (hr, ox, en)
                print("📥 Updated vitals for \(sender): HR \(Int(hr)), O₂ \(Int(ox)), Energy \(Int(en))")
            }

        case "requestWorkOrders":
            // Reply with our current work orders (using mock data here)
            // Replace WorkOrder.mockData with your real source if available.
            let orders = WorkOrder.mockData
            print("📨 requestWorkOrders from \(peerID.displayName). Replying with \(orders.count) orders.")
            self.sendWorkOrders(to: peerID, orders: orders)

        case "workOrders":
            guard
                let sender = message["from"] as? String,
                let payload = message["payload"] as? Data
            else { return }
            do {
                let orders = try JSONDecoder().decode([WorkOrder].self, from: payload)
                DispatchQueue.main.async {
                    self.peerWorkOrders[sender] = orders
                    print("📥 Stored \(orders.count) work orders for \(sender)")
                }
            } catch {
                print("❌ Failed to decode work orders: \(error.localizedDescription)")
            }

        default: break
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream,
                 withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiser / Browser
extension PhoneSessionManager: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Failed to advertise: \(error.localizedDescription)")
    }
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Failed to browse: \(error.localizedDescription)")
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard peerID.displayName != myDisplayName,
              !connectedPeers.contains(peerID),
              !isConnecting.contains(peerID) else { return }
        print("👀 Found peer: \(peerID.displayName)")
        if self.peerID.displayName < peerID.displayName {
            browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
            print("📨 Sent invite to \(peerID.displayName)")
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("👋 Lost peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            withAnimation(.easeOut) { self.connectedPeers.removeAll { $0 == peerID } }
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📩 Received connection invite from \(peerID.displayName)")
        invitationHandler(true, mcSession)
    }
}

// MARK: - WatchConnectivity
extension PhoneSessionManager: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("📡 WCSession activation: \(activationState.rawValue) \(error?.localizedDescription ?? "")")
    }
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("⌚️ Watch session state changed: \(session.activationState.rawValue)")
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}

    // ✅ Health data from watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            guard
                let hr = message["heartRate"] as? Double,
                let ox = message["oxygen"] as? Double,
                let en = message["energy"] as? Double
            else { return }

            self.heartRate = hr
            self.oxygen = ox
            self.energy = en
            self.isWatchSessionActive = true
            self.peerVitals[self.myDisplayName] = (hr, ox, en)
            print("📥 Received health from watch → HR \(Int(hr)), O₂ \(Int(ox)), Energy \(Int(en)) kcal")
            self.broadcastVitals()
        }
    }

    private func broadcastVitals() {
        guard let session = mcSession, !session.connectedPeers.isEmpty else { return }
        let payload: [String: Any] = [
            "type": "vitals",
            "from": myDisplayName,
            "heartRate": heartRate,
            "oxygen": oxygen,
            "energy": energy
        ]
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: payload, requiringSecureCoding: false)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("📤 Broadcasted vitals from \(myDisplayName) to \(session.connectedPeers.count) peers")
        } catch {
            print("⚠️ Vitals send error: \(error.localizedDescription)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("📶 Reachability changed: \(session.isReachable)")
    }
}

