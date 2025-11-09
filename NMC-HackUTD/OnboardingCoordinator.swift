//
//  OnboardingFlowView.swift
//  NMC-HackUTD
//
//  Created by Keven Diaz on 11/9/25.
//

import SwiftUI
import Combine

enum OnboardingStep {
    case launch
    case permissions
    case nameSetup
    case completed
}

final class OnboardingCoordinator: ObservableObject {
    @Published var step: OnboardingStep = .launch
}

