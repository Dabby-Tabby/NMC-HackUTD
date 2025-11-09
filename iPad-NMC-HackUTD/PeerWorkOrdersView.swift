import SwiftUI

struct PeerWorkOrdersView: View {
    @EnvironmentObject var session: PhoneSessionManager
    let peerName: String
    
    var orders: [WorkOrder] {
        session.peerWorkOrders[peerName] ?? []
    }
    
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
                
                if orders.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Waiting for \(peerName)’s work orders…")
                            .foregroundColor(Color("TextWhite").opacity(0.7))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(orders) { workOrder in
                                NavigationLink {
                                    WorkOrderDetailView(workOrder: workOrder,
                                                        viewModel: WorkOrderViewModel(workOrders: orders))
                                } label: {
                                    WorkOrderRowView(workOrder: workOrder)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("\(peerName)’s Work Orders")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PeerWorkOrdersView(peerName: "Jacob")
        .environmentObject(PhoneSessionManager())
}
