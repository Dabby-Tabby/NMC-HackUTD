//
//  OnboardingFlowView.swift
//  NMC-HackUTD
//
//  Created by Keven Diaz on 11/9/25.
//

import SwiftUI

struct OnboardingFlowView: View {
    /// Called when onboarding has finished and we should enter the main app
    let onFinished: () -> Void
    
    /// Shared coordinator across all onboarding screens
    @StateObject private var onboarding = OnboardingCoordinator()
    
    var body: some View {
        NavigationStack {
            Group {
                switch onboarding.step {
                case .launch:
                    LaunchView()
                        .environmentObject(onboarding)
                    
                case .permissions:
                    PermissionsPage()
                        .environmentObject(onboarding)
                    
                case .nameSetup:
                    NameSetupView()
                        .environmentObject(onboarding)
                    
                case .completed:
                    // We immediately notify the shell and this view goes away
                    Color.clear
                        .onAppear {
                            onFinished()
                        }
                }
            }
        }
    }
}
