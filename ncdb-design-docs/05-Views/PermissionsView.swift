// PermissionsView.swift
// NCDB - Notification Permissions
// Request notification permissions from user

import SwiftUI
import UserNotifications

struct PermissionsView: View {
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color(hex: "FFD700"))
                
                // Title
                Text("Stay Updated with Notifications")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                // Benefits
                VStack(alignment: .leading, spacing: 16) {
                    NotificationBenefit(text: "New Cage films announced")
                    NotificationBenefit(text: "Important news breaks")
                    NotificationBenefit(text: "You hit milestones")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                
                Text("You can change this anytime in Settings.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    Button {
                        requestNotificationPermission()
                    } label: {
                        Text("Enable Notifications")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "FFD700"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Button {
                        onComplete()
                    } label: {
                        Text("Not Now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                // Save permission status if needed
                UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                onComplete()
            }
        }
    }
}

struct NotificationBenefit: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "FFD700"))
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
}

#Preview {
    PermissionsView(onComplete: {})
}
