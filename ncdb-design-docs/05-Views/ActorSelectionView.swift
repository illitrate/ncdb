// ActorSelectionView.swift
// NCDB - Actor Selection
// Choose which actors to follow

import SwiftUI

struct ActorSelectionView: View {
    let onContinue: () -> Void
    @State private var selectedActors: Set<Int> = [2963] // Nic Cage ID
    @State private var showingSearch = false
    
    let suggestedActors = [
        ActorOption(id: 2963, name: "Nicolas Cage", isDefault: true),
        ActorOption(id: 8891, name: "John Travolta", isDefault: false),
        ActorOption(id: 500, name: "Tom Cruise", isDefault: false),
        ActorOption(id: 3489, name: "Keanu Reeves", isDefault: false)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                Text("Choose Actors to Follow")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 40)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(suggestedActors) { actor in
                            ActorRow(
                                actor: actor,
                                isSelected: selectedActors.contains(actor.id),
                                onToggle: {
                                    if actor.isDefault {
                                        return // Can't deselect default
                                    }
                                    if selectedActors.contains(actor.id) {
                                        selectedActors.remove(actor.id)
                                    } else {
                                        selectedActors.insert(actor.id)
                                    }
                                }
                            )
                        }
                        
                        // Add Actor Button
                        Button {
                            showingSearch = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color(hex: "FFD700"))
                                Text("Add Another Actor")
                                    .foregroundStyle(.white)
                            }
                            .font(.system(size: 17, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Info Text
                Text("You can always add more actors later in Settings.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 24)
                
                // Continue Button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "FFD700"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingSearch) {
            // TODO: Implement ActorSearchView
            Text("Actor Search - Coming Soon")
        }
    }
}

struct ActorRow: View {
    let actor: ActorOption
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color(hex: "FFD700") : .white.opacity(0.3))
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(actor.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    if actor.isDefault {
                        Text("Default actor")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color(hex: "FFD700"))
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(actor.isDefault) // Can't deselect Nic Cage
    }
}

struct ActorOption: Identifiable {
    let id: Int
    let name: String
    let isDefault: Bool
}

#Preview {
    ActorSelectionView(onContinue: {})
}
