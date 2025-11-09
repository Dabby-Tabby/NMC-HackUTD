//
//  NmcAppShell.swift
//  NMC-HackUTD
//
//  Created by Keven Diaz on 11/9/25.
//

import SwiftUI

enum AppTab {
    case dashboard
    case workOrders
    case nomi
}

struct NmcAppShell: View {
    @EnvironmentObject var session: PhoneSessionManager
    @State private var selectedTab: AppTab = .dashboard
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Show the current tab's content
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                        .environmentObject(session)
                case .workOrders:
                    WorkOrderListView()
                        .environmentObject(session)
                case .nomi:
                    NomiAssistantView()
                        .environmentObject(session)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack(spacing: 16) {
                        // HOME
                        Button {
                            selectedTab = .dashboard
                        } label: {
                            Image(systemName: "heart.text.clipboard.fill")
                                .foregroundColor(selectedTab == .dashboard
                                                 ? .white
                                                 : .white.opacity(0.6))
                        }
                        .padding(.leading, 12)

                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.3))

                        // WORK ORDERS
                        Button {
                            selectedTab = .workOrders
                        } label: {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundColor(selectedTab == .workOrders
                                                 ? .white
                                                 : .white.opacity(0.6))
                        }

                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.3))

                        // NOMI
                        Button {
                            selectedTab = .nomi
                        } label: {
                            Image(systemName: "cpu.fill")
                                .foregroundColor(selectedTab == .nomi
                                                 ? .white
                                                 : .white.opacity(0.6))
                        }
                        .padding(.trailing, 12)
                    }
                }
            }
            .toolbarBackground(Color("BoxBlue"), for: .bottomBar)
            .toolbarBackground(.visible, for: .bottomBar)
        }
    }
}
