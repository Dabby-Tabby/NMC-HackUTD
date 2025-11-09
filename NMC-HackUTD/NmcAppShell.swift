//
//  NmcAppShell.swift
//  NMC-HackUTD
//
//  Created by Keven Diaz on 11/9/25.
//


import SwiftUI

enum AppTab: Hashable {
    case dashboard
    case workOrders
    case nomi
}

struct NmcAppShell: View {
    @EnvironmentObject var session: PhoneSessionManager
    @EnvironmentObject var workOrderViewModel: WorkOrderViewModel
    
    @State private var selectedTab: AppTab = .dashboard
    @State private var hasCompletedOnboarding = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if hasCompletedOnboarding {
                    mainTabContent
                } else {
                    OnboardingFlowView {
                        withAnimation(.easeInOut) {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
            .toolbar {
                if hasCompletedOnboarding {
                    ToolbarItemGroup(placement: .bottomBar) {
                        HStack(spacing: 16) {
                            // DASHBOARD
                            Button {
                                selectedTab = .dashboard
                            } label: {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(
                                        selectedTab == .dashboard
                                        ? .white
                                        : .white.opacity(0.6)
                                    )
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
                                    .foregroundColor(
                                        selectedTab == .workOrders
                                        ? .white
                                        : .white.opacity(0.6)
                                    )
                            }

                            Divider()
                                .frame(height: 20)
                                .background(Color.white.opacity(0.3))

                            // NOMI
                            Button {
                                selectedTab = .nomi
                            } label: {
                                Image(systemName: "cpu.fill")
                                    .foregroundColor(
                                        selectedTab == .nomi
                                        ? .white
                                        : .white.opacity(0.6)
                                    )
                            }
                            .padding(.trailing, 12)
                        }
                    }
                }
            }
            .toolbarBackground(Color("BoxBlue"), for: .bottomBar)
            .toolbarBackground(
                hasCompletedOnboarding ? .visible : .hidden,
                for: .bottomBar
            )
        }
    }
    
    // MARK: - Main Tab Content
    
    @ViewBuilder
    private var mainTabContent: some View {
        ZStack {
            switch selectedTab {
            case .dashboard:
                DashboardView()
                    .environmentObject(session)
                
            case .workOrders:
                WorkOrderListView()
                    .environmentObject(session)
                    .environmentObject(workOrderViewModel)
                
            case .nomi:
                NomiAssistantView(session: session, workOrderViewModel: workOrderViewModel)
                    .environmentObject(session)
                    .environmentObject(workOrderViewModel)
            }
        }
    }
}
