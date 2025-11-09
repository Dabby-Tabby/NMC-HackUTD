//
//  HealthDataManager.swift
//  Watch-NMC-HackUTD Watch App
//
//  Created by Nick Watts on 11/8/25.
//

import Foundation
import HealthKit
import WatchConnectivity
import Combine
import SwiftUI
import WatchKit

class HealthDataManager: NSObject, ObservableObject, WCSessionDelegate {
    // MARK: - Properties
    private let healthStore = HKHealthStore()
    private var session: WCSession?
    private var cancellable: AnyCancellable?
    
    // MARK: - Published Health Metrics
    @Published var heartRate: Double = 0
    @Published var oxygen: Double = 0
    @Published var energy: Double = 0
    @Published var showPingBanner: Bool = false

    // MARK: - Init
    override init() {
        super.init()
        
        // ✅ Setup WatchConnectivity
        if WCSession.isSupported() {
            let wcSession = WCSession.default
            wcSession.delegate = self
            wcSession.activate()
            self.session = wcSession
            print("⌚️ WCSession activated on Watch")
        } else {
            print("❌ WCSession not supported on this watch")
        }
        
        requestHealthAuthorization()
        startAutoSendLoop()
    }
    
    // MARK: - HealthKit Authorization
    func requestHealthAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ Health data unavailable on this device.")
            return
        }
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            if let error = error {
                print("⚠️ Health authorization error: \(error.localizedDescription)")
            }
            if success {
                print("✅ Health authorization granted")
                self.enableBackgroundDelivery(for: typesToRead)
                self.startAllQueries()
            } else {
                print("❌ Health authorization denied")
            }
        }
    }
    
    private func enableBackgroundDelivery(for types: Set<HKSampleType>) {
        for type in types {
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                if let error = error {
                    print("⚠️ Background delivery error for \(type): \(error.localizedDescription)")
                } else {
                    print("📦 Background delivery enabled for \(type)")
                }
            }
        }
    }
    
    private func startAllQueries() {
        startQuery(for: .heartRate)
        startQuery(for: .oxygenSaturation)
        startQuery(for: .activeEnergyBurned)
    }
    
    private func startQuery(for identifier: HKQuantityTypeIdentifier) {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        
        let query = HKAnchoredObjectQuery(type: type, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { _, samples, _, _, _ in
            self.handle(samples)
        }
        query.updateHandler = { _, samples, _, _, _ in
            self.handle(samples)
        }
        healthStore.execute(query)
        print("📈 Started query for \(identifier.rawValue)")
    }
    
    private func handle(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample],
              let last = samples.last else { return }
        
        DispatchQueue.main.async {
            switch last.quantityType.identifier {
            case HKQuantityTypeIdentifier.heartRate.rawValue:
                self.heartRate = last.quantity.doubleValue(for: HKUnit(from: "count/min"))
            case HKQuantityTypeIdentifier.oxygenSaturation.rawValue:
                self.oxygen = last.quantity.doubleValue(for: .percent()) * 100
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                self.energy = last.quantity.doubleValue(for: .kilocalorie())
            default: break
            }
        }
    }
    
    // MARK: - Auto Send Loop
    private func startAutoSendLoop() {
        cancellable = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.sendToPhone()
            }
    }
    
    private func sendToPhone() {
        guard let session = session, session.isReachable else {
            print("📵 Phone not reachable, skipping send.")
            return
        }
        
        let payload: [String: Any] = [
            "heartRate": heartRate,
            "oxygen": oxygen,
            "energy": energy,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(payload, replyHandler: nil) { error in
            print("⚠️ Send error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("⌚️ WCSession activation state: \(activationState.rawValue), error: \(String(describing: error))")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("📶 Reachability changed: \(session.isReachable)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📩 Received message from phone: \(message)")
        if message["type"] as? String == "ping" {
            WKInterfaceDevice.current().play(.notification)
            DispatchQueue.main.async {
                withAnimation(.spring()) {
                    self.showPingBanner = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut) {
                        self.showPingBanner = false
                    }
                }
            }
        }
    }
}

// MARK: - Ping Banner View
struct PingBanner: View {
    var body: some View {
        VStack {
            Spacer()
            Text("📡 Ping received!")
                .font(.headline)
                .padding()
                .background(Color.blue.opacity(0.8))
                .cornerRadius(12)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
