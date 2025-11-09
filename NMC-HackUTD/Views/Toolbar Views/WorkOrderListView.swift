//
//  WorkOrderView.swift
//  NMC-HackUTD
//
//  Created by Keven Diaz on 11/8/25.
//

import SwiftUI

// MARK: - Color Theme

extension Color {
    // Background (deep navy / indigo like your screenshot)
    static let dashboardBackgroundTop    = Color(red: 10/255, green: 15/255, blue: 32/255)
    static let dashboardBackgroundBottom = Color(red: 3/255,  green: 7/255,  blue: 18/255)
    
    // Card
    static let dashboardCardBackground   = Color(red: 15/255, green: 23/255, blue: 42/255) // slate-ish
    static let dashboardCardBorder       = Color.white.opacity(0.06)
    
    // Text
    static let dashboardTextPrimary      = Color.white.opacity(0.95)
    static let dashboardTextSecondary    = Color.white.opacity(0.65)
    
    // Accent / chips
    static let dashboardAccentBlue       = Color(red: 59/255,  green: 130/255, blue: 246/255) // electric blue
    static let dashboardAccentMutedBlue  = Color.white.opacity(0.06)
}

// MARK: - List View

struct WorkOrderListView: View {
    @StateObject private var viewModel = WorkOrderViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundBlue")
                    .overlay(CrossHatchBackground(lineColor: .white.opacity(0.02), lineWidth: 0.3, spacing: 30))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Active Work Orders")
                            .font(.headline)
                            .foregroundColor(.dashboardTextSecondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            ForEach(viewModel.activeWorkOrders) { workOrder in
                                NavigationLink {
                                    WorkOrderDetailView(
                                        workOrder: workOrder,
                                        viewModel: viewModel
                                    )
                                } label: {
                                    WorkOrderRowView(workOrder: workOrder)
                                }
                                .buttonStyle(.plain)
                                .overlay(
                                    CrossHatchBackground(
                                        lineColor: .white.opacity(0.01),
                                        lineWidth: 0.8,
                                        spacing: 10
                                    )
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
            }

            .navigationTitle("Work Orders")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .tint(.dashboardAccentBlue)
    }
}

// MARK: - Row View

struct WorkOrderRowView: View {
    let workOrder: WorkOrder
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.dashboardCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.dashboardCardBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 12)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(workOrder.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.dashboardTextPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(workOrder.priorityText)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(workOrder.priorityColor.opacity(0.16))
                        .foregroundColor(workOrder.priorityColor)
                        .clipShape(Capsule())
                }
                
                Text(workOrder.location)
                    .font(.subheadline)
                    .foregroundColor(.dashboardTextSecondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(workOrder.statusText, systemImage: workOrder.statusIconName)
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                    
                    Spacer()
                    
                    if let assignee = workOrder.assignedTo {
                        Text("👷‍♂️ \(assignee)")
                            .font(.caption)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.dashboardTextSecondary.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail View

struct WorkOrderDetailView: View {
    let workOrder: WorkOrder
    @ObservedObject var viewModel: WorkOrderViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header card
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.dashboardCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.dashboardCardBorder, lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(workOrder.title)
                                    .font(.system(.title3, design: .rounded).bold())
                                    .foregroundColor(.dashboardTextPrimary)
                                
                                Text(workOrder.location)
                                    .font(.subheadline)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                            Spacer()
                        }
                        
                        HStack(spacing: 10) {
                            Text(workOrder.priorityText)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(workOrder.priorityColor.opacity(0.16))
                                .foregroundColor(workOrder.priorityColor)
                                .clipShape(Capsule())
                            
                            Text(workOrder.statusText)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.dashboardAccentMutedBlue)
                                .foregroundColor(.dashboardTextSecondary)
                                .clipShape(Capsule())
                            
                            Spacer()
                        }
                    }
                    .padding(18)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    Text(workOrder.description)
                        .font(.body)
                        .foregroundColor(.dashboardTextSecondary)
                }
                
                // Checklist
                if !workOrder.checklist.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Checklist")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        ForEach(workOrder.checklist) { item in
                            HStack {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isDone ? .green : .dashboardTextSecondary)
                                
                                Text(item.text)
                                    .foregroundColor(item.isDone ? .dashboardTextSecondary : .dashboardTextPrimary)
                                    .strikethrough(item.isDone, color: .dashboardTextSecondary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Notes
                if !workOrder.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        ForEach(workOrder.notes.sorted(by: { $0.createdAt < $1.createdAt })) { note in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.author)
                                    .font(.caption)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                Text(note.message)
                                    .font(.body)
                                    .foregroundColor(.dashboardTextPrimary)
                            }
                            .padding(10)
                            .background(Color.dashboardCardBackground.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.dashboardCardBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [.dashboardBackgroundTop, .dashboardBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Work Order")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helpers

private extension WorkOrder {
    var priorityText: String {
        switch priority {
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }
    
    var priorityColor: Color {
        switch priority {
        case .low:    return Color.green
        case .medium: return Color.yellow
        case .high:   return Color.red
        }
    }
    
    var statusText: String {
        switch status {
        case .new:        return "New"
        case .inProgress: return "In Progress"
        case .blocked:    return "Blocked"
        case .done:       return "Done"
        }
    }
    
    var statusIconName: String {
        switch status {
        case .new:        return "tray"
        case .inProgress: return "clock"
        case .blocked:    return "exclamationmark.triangle"
        case .done:       return "checkmark.circle"
        }
    }
}

// MARK: - Previews

struct WorkOrderListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkOrderListView()
                .preferredColorScheme(.dark)
            
            NavigationStack {
                WorkOrderDetailView(
                    workOrder: WorkOrder.mock1,
                    viewModel: WorkOrderViewModel()
                )
            }
            .preferredColorScheme(.dark)
        }
    }
}
