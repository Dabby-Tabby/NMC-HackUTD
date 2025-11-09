//
//  WorkOrderView.swift
//  NMC-HackUTD
//
//  Created by Keven Diaz on 11/8/25.
//

import SwiftUI

// MARK: - Global UI Constants
private let textOpacityPrimary: Double = 0.95
private let textOpacitySecondary: Double = 0.65


// MARK: - List View
struct WorkOrderListView: View {
    @EnvironmentObject var session: PhoneSessionManager
    @StateObject private var viewModel = WorkOrderViewModel()
    @State private var isPresentingNewWorkOrder = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundBlue").ignoresSafeArea()
                CrossHatchBackground(
                    lineColor: .white.opacity(0.02),
                    lineWidth: 0.3,
                    spacing: 30
                )
                .ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        Label("Work Orders", systemImage: "waveform.path.ecg.rectangle")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("TextWhite").opacity(textOpacityPrimary))
                            .padding(.top, 10)
                            .shadow(color: Color("TextWhite").opacity(0.4), radius: 3)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .overlay(alignment: .trailing) {
                                Button {
                                    isPresentingNewWorkOrder = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                                .tint(.primary)
                                .padding(8)
                                .glassEffect(in: Circle())
                                .accessibilityLabel("Add Work Order")
                                .padding(.trailing)
                            }
                        
                        HStack {
                            Text("Active Work Orders")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("TextWhite").opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        
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
                                    .allowsHitTesting(false)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .sheet(isPresented: $isPresentingNewWorkOrder) {
            NewWorkOrderSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Row View

struct WorkOrderRowView: View {
    let workOrder: WorkOrder
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color("BoxBlue"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color("BoxBlue"), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 12)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(workOrder.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(Color("TextWhite").opacity(textOpacityPrimary))
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
                    .foregroundColor(Color("TextWhite").opacity(textOpacitySecondary))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(workOrder.statusText, systemImage: workOrder.statusIconName)
                        .font(.caption)
                        .foregroundColor(Color("TextWhite").opacity(textOpacitySecondary))
                    
                    Spacer()
                    
                    if let assignee = workOrder.assignedTo {
                        Text("👷‍♂️ \(assignee)")
                            .font(.caption)
                            .foregroundColor(Color("TextWhite").opacity(textOpacitySecondary))
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.65).opacity(0.7))
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
    @EnvironmentObject var session: PhoneSessionManager
    
    @State private var newTaskText: String = ""
    @State private var newNoteText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header card
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color("BoxBlue"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color("BoxBlue"), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(workOrder.title)
                                    .font(.system(.title3, design: .rounded).bold())
                                    .foregroundColor(Color("TextWhite").opacity(textOpacityPrimary))
                                
                                Text(workOrder.location)
                                    .font(.subheadline)
                                    .foregroundColor(Color("TextWhite").opacity(textOpacitySecondary))
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
                                .background(Color.white.opacity(0.06))
                                .foregroundColor(Color.white.opacity(textOpacityPrimary))
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            let assingedToText: String = workOrder.assignedTo ?? "Unassigned"
                            Text("👷‍♂️\(assingedToText)")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.06))
                                .foregroundColor(Color.white.opacity(textOpacityPrimary))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(18)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(Color.white.opacity(textOpacityPrimary))
                    Text(workOrder.description)
                        .font(.body)
                        .foregroundColor(Color.white.opacity(textOpacitySecondary))
                }
                
                // Checklist
                if let updatedWorkOrder = viewModel.workOrders.first(where: { $0.id == workOrder.id }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Checklist")
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(textOpacityPrimary))
                        
                        if updatedWorkOrder.checklist.isEmpty {
                            // Placeholder/template view when there are no tasks
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No tasks added yet.")
                                    .font(.subheadline)
                                    .foregroundColor(Color.white.opacity(0.5))
                                
                                Text("Suggested steps:")
                                    .font(.caption)
                                    .foregroundColor(Color.white.opacity(0.4))
                                
                                Text("• Verify server is safe to work on")
                                    .font(.caption)
                                    .foregroundColor(Color.white.opacity(0.35))
                                
                                Text("• Document part removal / replacement")
                                    .font(.caption)
                                    .foregroundColor(Color.white.opacity(0.35))
                                
                                Text("• Run post-maintenance checks")
                                    .font(.caption)
                                    .foregroundColor(Color.white.opacity(0.35))
                            }
                            .padding(.vertical, 4)
                        } else {
                            ForEach(updatedWorkOrder.checklist) { item in
                                Button {
                                    viewModel.toggleChecklistItem(workOrderID: workOrder.id, itemID: item.id)
                                } label: {
                                    HStack {
                                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.isDone ? .green : Color.white.opacity(textOpacityPrimary))
                                        
                                        Text(item.text)
                                            .foregroundColor(
                                                item.isDone
                                                ? Color.white.opacity(textOpacitySecondary)
                                                : Color.white.opacity(textOpacityPrimary)
                                            )
                                            .strikethrough(item.isDone, color: Color.white.opacity(textOpacitySecondary))
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // New Task input
                        HStack {
                            TextField("New task...", text: $newTaskText)
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.sentences)
                                .submitLabel(.done)
                                .onSubmit(addNewTask)
                            
                            Button {
                                addNewTask()
                            } label: {
                                Label("Add", systemImage: "plus.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .imageScale(.large)
                            }
                            .disabled(newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.top, 4)
                    }
                }
                
                // Notes
                if let updatedWorkOrder = viewModel.workOrders.first(where: { $0.id == workOrder.id }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(textOpacityPrimary))
                        
                        if updatedWorkOrder.notes.isEmpty {
                            Text("No notes yet. Be the first to leave an update.")
                                .font(.subheadline)
                                .foregroundColor(Color.white.opacity(textOpacitySecondary))
                                .padding(.vertical, 4)
                        } else {
                            ForEach(
                                updatedWorkOrder.notes.sorted(by: { $0.createdAt < $1.createdAt })
                            ) { note in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(note.author)
                                        .font(.caption)
                                        .foregroundColor(Color.white.opacity(textOpacitySecondary))
                                    
                                    Text(note.message)
                                        .font(.body)
                                        .foregroundColor(Color.white.opacity(textOpacityPrimary))
                                }
                                .padding(10)
                                .background(Color("RoyalBlue").opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color("BabyBlue"), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .background(
            LinearGradient(
                colors: [Color("BackgroundBlue"), Color("BoxBlue")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Work Order")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            noteInputBar
        }
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .frame(height: 50)
            .allowsHitTesting(false)
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    
    private func addNewTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.addChecklistItem(to: workOrder.id, text: trimmed)
        newTaskText = ""
    }
    
    private func submitNote() {
        let trimmed = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Use session name if available, else a fallback
        let authorName = session.myDisplayName.isEmpty ? "You" : session.myDisplayName
        
        viewModel.addNote(
            to: workOrder.id,
            author: authorName,
            message: trimmed
        )
        
        newNoteText = ""
    }
    
    // MARK: - Note Input Bar

    private var noteInputBar: some View {
        ZStack {
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "long.text.page.and.pencil.fill")
                        .foregroundColor(.white.opacity(0.7))
                    
                    TextField("Add a note...", text: $newNoteText, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .foregroundColor(.white.opacity(2))
                        .lineLimit(1...3)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .glassEffect()
                
                Button {
                    submitNote()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                         ? .white.opacity(0.3)
                                         : Color("BabyBlue"))
                }
                .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
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

// MARK: - New Work Order Sheet

struct NewWorkOrderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkOrderViewModel
    
    @EnvironmentObject var session: PhoneSessionManager
    
    @State private var title: String = ""
    @State private var location: String = ""
    @State private var description: String = ""
    @State private var assignedTo: String = ""
    @State private var priority: WorkOrderPriority = .medium
    
    @State private var checklistDraft: [String] = []
    @State private var newChecklistText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Location", text: $location)
                    TextField("Assigned to (optional)", text: $assignedTo)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(WorkOrderPriority.allCases, id: \.self) { level in
                            Text(label(for: level))
                                .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                }
                
                Section("Checklist") {
                    if checklistDraft.isEmpty {
                        // Placeholder/template when user hasn't added any items
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No tasks yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Example:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Verify server is powered down safely")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                            Text("• Remove and label faulty component")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(Array(checklistDraft.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Image(systemName: "square.dashed")
                                    .foregroundColor(.secondary)
                                Text(item)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(role: .destructive) {
                                    checklistDraft.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    
                    HStack {
                        TextField("New checklist item", text: $newChecklistText)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.done)
                            .onSubmit(addChecklistItem)
                        
                        Button {
                            addChecklistItem()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.large)
                        }
                        .disabled(newChecklistText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle("New Work Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline)
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addChecklistItem() {
        let trimmed = newChecklistText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        checklistDraft.append(trimmed)
        newChecklistText = ""
    }
    
    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAssignee = assignedTo.trimmingCharacters(in: .whitespacesAndNewlines)

        // Derive owner identity from the session (no direct peerID access)
        let ownerID = session.ownerID
        let ownerName = session.ownerName.isEmpty ? "Unknown Tech" : session.ownerName

        viewModel.createWorkOrder(
            title: trimmedTitle,
            description: trimmedDescription,
            location: trimmedLocation,
            priority: priority,
            assignedTo: trimmedAssignee.isEmpty ? nil : trimmedAssignee,
            checklistTexts: checklistDraft,
            ownerID: ownerID,
            ownerName: ownerName
        )

        dismiss()
    }
    
    private func label(for priority: WorkOrderPriority) -> String {
        switch priority {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
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

