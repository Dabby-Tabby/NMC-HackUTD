//
//  workOrderModel.swift
//  NMC-HackUTD
//
//  Created by Keven Diaz on 11/8/25.
//

import Foundation

enum WorkOrderStatus: String, Codable, CaseIterable {
    case new
    case inProgress = "in_progress"
    case blocked
    case done
}

enum WorkOrderPriority: String, Codable, CaseIterable {
    case low, medium, high
}

struct WorkOrder: Identifiable, Codable, Hashable {
    let id: UUID
    
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
