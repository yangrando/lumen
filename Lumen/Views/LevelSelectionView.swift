//
//  LevelSelectionView.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 29/12/25.
//
import SwiftUI

struct LevelSelectionView: View {
    
    @State private var selectedLevel: EnglishLevel? = nil
    
    let onContinue: (EnglishLevel) -> Void
    
    var body: some View {
        ZStack {
            LumenColors.navyDark
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text(LocalizedStrings.levelSelectionTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(LocalizedStrings.levelSelectionDescription)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(EnglishLevel.allCases) { level in
                            LevelCard(
                                level: level,
                                isSelected: selectedLevel == level,
                                action: {
                                    selectedLevel = level
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        if let selected = selectedLevel {
                            onContinue(selected)
                        }
                    }) {
                        Text(LocalizedStrings.levelContinueButton)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundStyle(.white)
                            .background(
                                selectedLevel != nil ?
                                LinearGradient.primaryGradient :
                                LinearGradient(gradient: Gradient(colors: [
                                    LumenColors.navyLight,
                                    LumenColors.navyLight
                                ]), startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(selectedLevel == nil)
                    .opacity(selectedLevel != nil ? 1.0 : 0.5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

}
