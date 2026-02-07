//
//  ObjectivesView.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 29/12/25.
//

import SwiftUI

struct ObjectivesView: View {
    
    // State to track selected objectives
    @State private var selectedObjectives: Set<LearningObjective> = []
    
    // Action to complete onboarding
    let onContinue: ([LearningObjective]) -> Void
    
    // Grid layout configuration
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            // Background
            LumenColors.navyDark
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("What are your goals?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Select what you want to achieve with English")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Grid of objectives
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(LearningObjective.allCases) { objective in
                            ObjectiveCard(
                                objective: objective,
                                isSelected: selectedObjectives.contains(objective),
                                action: {
                                    if selectedObjectives.contains(objective) {
                                        selectedObjectives.remove(objective)
                                    } else {
                                        selectedObjectives.insert(objective)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Continue button
                VStack(spacing: 12) {
                    Button(action: {
                        let selectedArray = Array(selectedObjectives).sorted { $0.rawValue < $1.rawValue }
                        onContinue(selectedArray)
                    }) {
                        Text("Complete Setup")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundStyle(.white)
                            .background(
                                !selectedObjectives.isEmpty ?
                                LinearGradient.primaryGradient :
                                    LinearGradient(gradient: Gradient(colors: [
                                        LumenColors.navyLight,
                                        LumenColors.navyLight
                                    ]), startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(selectedObjectives.isEmpty)
                    .opacity(selectedObjectives.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

