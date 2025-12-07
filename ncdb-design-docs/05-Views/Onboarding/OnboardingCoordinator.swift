// OnboardingCoordinator.swift
// NCDB - Onboarding Flow Coordinator
// Manages the complete onboarding experience

import SwiftUI

struct OnboardingCoordinator: View {
    @State private var currentStep: OnboardingStep = .splash
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .splash:
                OnboardingSplashView(onComplete: {
                    advanceToNextStep()
                })
                
            case .welcome:
                OnboardingWelcomeView(onContinue: {
                    advanceToNextStep()
                })
                .transition(.move(edge: .trailing))
                
            case .highlights:
                OnboardingHighlightsView(onComplete: {
                    advanceToNextStep()
                })
                .transition(.move(edge: .trailing))
                
            case .apiKey:
                TMDbSetupView(
                    onComplete: {
                        advanceToNextStep()
                    },
                    onSkip: {
                        // Handle skip - show warning
                        showSkipWarning()
                    }
                )
                .transition(.move(edge: .trailing))
                
            case .seeding:
                DataSeedingView(onComplete: {
                    advanceToNextStep()
                })
                .transition(.opacity)
                
            case .actors:
                ActorSelectionView(onContinue: {
                    advanceToNextStep()
                })
                .transition(.move(edge: .trailing))
                
            case .tutorial:
                RankingTutorialView(
                    onComplete: {
                        advanceToNextStep()
                    },
                    onSkip: {
                        advanceToNextStep()
                    }
                )
                .transition(.move(edge: .trailing))
                
            case .permissions:
                PermissionsView(onComplete: {
                    advanceToNextStep()
                })
                .transition(.move(edge: .trailing))
                
            case .ready:
                OnboardingReadyView(onEnter: {
                    completeOnboarding()
                })
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
    
    // MARK: - Navigation
    
    private func advanceToNextStep() {
        withAnimation {
            switch currentStep {
            case .splash:
                currentStep = .welcome
            case .welcome:
                currentStep = .highlights
            case .highlights:
                currentStep = .apiKey
            case .apiKey:
                currentStep = .seeding
            case .seeding:
                currentStep = .actors
            case .actors:
                currentStep = .tutorial
            case .tutorial:
                currentStep = .permissions
            case .permissions:
                currentStep = .ready
            case .ready:
                completeOnboarding()
            }
        }
    }
    
    private func showSkipWarning() {
        // Show alert about limited functionality
        // Then advance to next step
        advanceToNextStep()
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isOnboardingComplete = true
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep {
    case splash
    case welcome
    case highlights
    case apiKey
    case seeding
    case actors
    case tutorial
    case permissions
    case ready
}

// MARK: - Preview

#Preview {
    OnboardingCoordinator(isOnboardingComplete: .constant(false))
}
