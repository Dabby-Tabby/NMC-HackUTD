//
//  FakeHealthDataManager.swift
//  Watch-NMC-HackUTD Watch App
//
//  Created by Nick Watts on 11/8/25.
//

import Foundation
import WatchConnectivity
import SwiftUI
import Combine

class FakeHealthDataManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var heartRate: Double = 72
    @Published var oxygen: Double = 98
    @Published var energy: Double = 10
    
    private var timer: Timer?
    private var session: WCSession?
    
    override init() {
        super.init()
        setupSession()
        startFakeUpdates()
    }
    
    private func setupSession() {
        if WCSession.isSupported() {
            let s = WCSession.default
            s.delegate = self
            s.activate()
            session = s
        }
    }
    
    private func startFakeUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.generateFakeData()
            self?.sendToPhone()
        }
    }
    
    private func generateFakeData() {
        // Small random walk around a base value so it looks "alive"
        heartRate = Double(Int.random(in: 65...110))
        oxygen = Double(Int.random(in: 92...100))
        energy += Double(Int.random(in: 1...5))
    }
    
     func sendToPhone() {
        guard let session = session, session.isReachable else { return }
        
        let payload: [String: Any] = [
            "heartRate": heartRate,
            "oxygen": oxygen,
            "energy": energy,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(payload, replyHandler: nil) { error in
            print("Failed to send: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WCSessionDelegate stubs
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("WCSession activation error: \(error.localizedDescription)")
        }
    }
    
    // In FakeHealthDataManager.swift (watch target)
    func sendPing(to peerName: String, senderName: String) {
        guard let session = session else {
            print("⌚ No WCSession set up")
            return
        }
        guard session.isReachable else {
            print("⌚ iPhone not reachable right now")
            return
        }

        let payload: [String: Any] = [
            "type": "ping",
            "to": peerName,       // optional target field if you support multi-peer/team
            "from": senderName,
            "timestamp": Date().timeIntervalSince1970
        ]
        session.sendMessage(payload, replyHandler: nil) { error in
            print("⌚ send ping failed: \(error.localizedDescription)")
        }
    }

}
