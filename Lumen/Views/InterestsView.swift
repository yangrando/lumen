//
//  InterestsView.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 29/12/25.
//

import SwiftUI

struct InterestsView: View {
    
    // State to track selected interests (using Set for multiple selection)
    @State private var selectedInterests: Set<UserInterest> = []
    
    // Action to continue (will be passed by OnboardingView)
    let onContinue: ([UserInterest]) -> Void
    
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
                    Text(LocalizedStrings.interestsTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(LocalizedStrings.interestsDescription)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Grid of interests
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(UserInterest.allCases) { interest in
                            InterestCard(
                                interest: interest,
                                isSelected: selectedInterests.contains(interest),
                                action: {
                                    if selectedInterests.contains(interest) {
                                        selectedInterests.remove(interest)
                                    } else {
                                        selectedInterests.insert(interest)
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
                        let selectedArray = Array(selectedInterests).sorted { $0.rawValue < $1.rawValue }
                        onContinue(selectedArray)
                    }) {
                        Text(LocalizedStrings.interestsContinueButton)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundStyle(.white)
                            .background(
                                !selectedInterests.isEmpty ?
                                LinearGradient.primaryGradient :
                                    LinearGradient(gradient: Gradient(colors: [
                                        LumenColors.navyLight,
                                        LumenColors.navyLight
                                    ]), startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(selectedInterests.isEmpty)
                    .opacity(selectedInterests.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

