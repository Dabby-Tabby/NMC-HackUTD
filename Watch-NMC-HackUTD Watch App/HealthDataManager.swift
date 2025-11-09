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

class HealthDataManager: NSObject, ObservableObject, WCSessionDelegate {
    private let healthStore = HKHealthStore()
    private var session: WCSession?
    
    @Published var heartRate: Double = 0
    @Published var oxygen: Double = 0
    @Published var energy: Double = 0
    
    private var cancellable: AnyCancellable?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        requestHealthAuthorization()
        startAutoSendLoop()
    }
    
    func requestHealthAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let types: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        healthStore.requestAuthorization(toShare: [], read: types) { success, _ in
            if success {
                self.enableBackgroundDelivery(for: types)
                self.startAllQueries()
            }
        }
    }
    
    private func enableBackgroundDelivery(for types: Set<HKSampleType>) {
        for type in types {
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                if let error = error {
                    print("Background delivery error: \(error.localizedDescription)")
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
    }
    
    private func handle(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let last = samples.last else { return }
        switch last.quantityType.identifier {
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            heartRate = last.quantity.doubleValue(for: .init(from: "count/min"))
        case HKQuantityTypeIdentifier.oxygenSaturation.rawValue:
            oxygen = last.quantity.doubleValue(for: .percent()) * 100
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            energy = last.quantity.doubleValue(for: .kilocalorie())
        default: break
        }
    }
    
    // Send updates every few seconds
    private func startAutoSendLoop() {
        cancellable = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.sendToPhone()
            }
    }
    
    private func sendToPhone() {
        guard let session = session, session.isReachable else { return }
        let payload: [String: Any] = [
            "heartRate": heartRate,
            "oxygen": oxygen,
            "energy": energy,
            "timestamp": Date().timeIntervalSince1970
        ]
        session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }
    
    // WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
