//
//  WorkOrderViewModel.swift
//  NMC2DataCenter
//

import Foundation
import Combine

// MARK: - Models

enum WorkOrderStatus: String, Codable, CaseIterable {
    case new
    case inProgress = "in_progress"
    case blocked
    case done
}

enum WorkOrderPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
}

struct WorkOrder: Identifiable, Hashable, Codable {
    let id: String

    let ownerID: String
    var ownerName: String

    var title: String
    var description: String
    var status: WorkOrderStatus
    var priority: WorkOrderPriority
    var location: String
    var assignedTo: String?
    var checklist: [ChecklistItem]
    var notes: [Note]
    var createdAt: Date
    var updatedAt: Date
}

struct ChecklistItem: Identifiable, Codable, Hashable {
    let id: String
    var text: String
    var isDone: Bool
}

struct Note: Identifiable, Codable, Hashable {
    let id: String
    var author: String
    var message: String
    var createdAt: Date
}

// MARK: - Dummy Data

extension WorkOrder {
    static let mock1 = WorkOrder(
        id: "WO-001",
        ownerID: "demo-owner",
         ownerName: "Demo User",
        title: "Replace PSU in GPU server",
        description: """
        Engineer notes: Intermittent power failures on node gpu-23.
        Replace PSU in rack R12, U20. Verify cabling and run POST checks.
        """,
        status: .inProgress,
        priority: .high,
        location: "DC1 – Hall A – Rack R12 – U20",
        assignedTo: "Alex T.",
        checklist: [
            ChecklistItem(id: "c1", text: "Verify server is in maintenance window", isDone: true),
            ChecklistItem(id: "c2", text: "Power down server and confirm LEDs off", isDone: false),
            ChecklistItem(id: "c3", text: "Remove server from rack (if required)", isDone: false),
            ChecklistItem(id: "c4", text: "Swap faulty PSU with spare", isDone: false),
            ChecklistItem(id: "c5", text: "Re-seat server and reconnect power/network", isDone: false),
            ChecklistItem(id: "c6", text: "Power on and verify POST passes", isDone: false)
        ],
        notes: [
            Note(
                id: "n1",
                author: "Jamie (Engineer)",
                message: "PSU reported multiple overcurrent events. Spare is in DC1 cage bin B-12.",
                createdAt: Date().addingTimeInterval(-3600)
            ),
            Note(
                id: "n2",
                author: "Alex (Tech)",
                message: "On site, walking to Hall A.",
                createdAt: Date().addingTimeInterval(-900)
            )
        ],
        createdAt: Date().addingTimeInterval(-7200),
        updatedAt: Date().addingTimeInterval(-600)
    )
    
    static let mock2 = WorkOrder(
        id: "WO-002",
        ownerID: "demo-owner",
         ownerName: "Demo User",
        title: "Install new compute node",
        description: """
        Install new 1U server in Rack R25, U10.
        Connect dual power, mgmt network, and production network.
        Label according to NMC² standards.
        """,
        status: .new,
        priority: .medium,
        location: "DC1 – Hall B – Rack R25 – U10",
        assignedTo: nil,
        checklist: [
            ChecklistItem(id: "c1", text: "Pick up server and rails from staging", isDone: false),
            ChecklistItem(id: "c2", text: "Install rails and slide in server", isDone: false),
            ChecklistItem(id: "c3", text: "Connect power (A/B feeds)", isDone: false),
            ChecklistItem(id: "c4", text: "Connect mgmt and production network", isDone: false),
            ChecklistItem(id: "c5", text: "Apply asset and hostname labels", isDone: false)
        ],
        notes: [],
        createdAt: Date().addingTimeInterval(-3600 * 4),
        updatedAt: Date().addingTimeInterval(-3600 * 4)
    )
    
    static let mock3 = WorkOrder(
        id: "WO-003",
        ownerID: "demo-owner",
         ownerName: "Demo User",
        title: "Visual inspection of hot aisle cabling",
        description: """
        Perform quick visual inspection of cabling in Rack R08 hot aisle.
        Look for loose or overstressed cables and report any issues.
        """,
        status: .blocked,
        priority: .low,
        location: "DC1 – Hall A – Rack R08 – Hot Aisle",
        assignedTo: "Morgan K.",
        checklist: [
            ChecklistItem(id: "c1", text: "Verify access window to hot aisle", isDone: true),
            ChecklistItem(id: "c2", text: "Inspect power cables for strain or damage", isDone: true),
            ChecklistItem(id: "c3", text: "Inspect network cables for proper dressing", isDone: false)
        ],
        notes: [
            Note(
                id: "n1",
                author: "Morgan (Tech)",
                message: "Blocked: hot aisle temporarily closed for maintenance.",
                createdAt: Date().addingTimeInterval(-1800)
            )
        ],
        createdAt: Date().addingTimeInterval(-3600 * 6),
        updatedAt: Date().addingTimeInterval(-1800)
    )
    
    static let mockData: [WorkOrder] = [mock1, mock2, mock3]
}

// MARK: - View Model

final class WorkOrderViewModel: ObservableObject {
    @Published var workOrders: [WorkOrder]
    
    init(workOrders: [WorkOrder] = WorkOrder.mockData) {
        self.workOrders = workOrders
    }
    
    // Work orders that are not done yet
    var activeWorkOrders: [WorkOrder] {
        workOrders.filter { $0.status != .done }
    }
    
    // MARK: - Intent methods (good for SwiftUI bindings)
    
    func updateStatus(workOrderID: String, to newStatus: WorkOrderStatus) {
        guard let index = workOrders.firstIndex(where: { $0.id == workOrderID }) else { return }
        workOrders[index].status = newStatus
        workOrders[index].updatedAt = Date()
    }
    
    func assignCurrentUser(to workOrderID: String, name: String) {
        guard let index = workOrders.firstIndex(where: { $0.id == workOrderID }) else { return }
        workOrders[index].assignedTo = name
        workOrders[index].updatedAt = Date()
    }
    
    // MARK: - Notes

    func addNote(to workOrderID: String, author: String, message: String) {
        guard let index = workOrders.firstIndex(where: { $0.id == workOrderID }) else { return }
        
        let newNote = Note(
            id: UUID().uuidString,
            author: author,
            message: message,
            createdAt: Date()
        )
        
        workOrders[index].notes.append(newNote)
        workOrders[index].updatedAt = Date()
    }

    // MARK: - Create

    func createWorkOrder(
        title: String,
        description: String,
        location: String,
        priority: WorkOrderPriority,
        assignedTo: String?,
        checklistTexts: [String] = [],
        ownerID: String,
        ownerName: String
    ) {
        let newID = "WO-\(Int(Date().timeIntervalSince1970))"

        let checklistItems = checklistTexts.map { text in
            ChecklistItem(
                id: UUID().uuidString,
                text: text,
                isDone: false
            )
        }

        let newWorkOrder = WorkOrder(
            id: newID,
            ownerID: ownerID,
            ownerName: ownerName,
            title: title,
            description: description,
            status: .new,
            priority: priority,
            location: location,
            assignedTo: assignedTo,
            checklist: checklistItems,
            notes: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        workOrders.insert(newWorkOrder, at: 0)
    }
    
    // MARK: - Checklist Helpers

    func addChecklistItem(to workOrderID: String, text: String) {
        guard let index = workOrders.firstIndex(where: { $0.id == workOrderID }) else { return }
        
        let newItem = ChecklistItem(
            id: UUID().uuidString,
            text: text,
            isDone: false
        )
        
        workOrders[index].checklist.append(newItem)
        workOrders[index].updatedAt = Date()
    }

    func toggleChecklistItem(workOrderID: String, itemID: String) {
        guard let workOrderIndex = workOrders.firstIndex(where: { $0.id == workOrderID }) else { return }
        guard let itemIndex = workOrders[workOrderIndex].checklist.firstIndex(where: { $0.id == itemID }) else { return }
        
        workOrders[workOrderIndex].checklist[itemIndex].isDone.toggle()
        workOrders[workOrderIndex].updatedAt = Date()
    }
    
    
}
