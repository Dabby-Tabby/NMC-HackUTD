//
//  BuddyView.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/8/25.
//

import SwiftUI

// MARK: - Buddy View
struct BuddyView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundBlue").ignoresSafeArea()
                Text("🧠 Buddy AI Systems")
                    .foregroundColor(Color("TextWhite"))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: DashboardView()) {
                            Image(systemName: "heart.text.clipboard.fill")
                        }
                        .padding(.leading, 12)

                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.3))

                        NavigationLink(destination: WorkOrderListView()) {
                            Image(systemName: "list.clipboard.fill")
                        }

                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.3))

                        NavigationLink(destination: BuddyView()) {
                            Image(systemName: "cpu.fill")
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
