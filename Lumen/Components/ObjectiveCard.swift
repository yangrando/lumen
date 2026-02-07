//
//  ObjectiveCard.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 29/12/25.
//

import SwiftUI

struct ObjectiveCard: View {
    
    let objective: LearningObjective
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action){
            VStack(spacing: 8) {
                            // Objective icon
                            Image(systemName: objective.icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(isSelected ? .white : LumenColors.textSecondary)
                            
                            // Objective name
                            Text(objective.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isSelected ? .white : LumenColors.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(
                            isSelected ?
                            LinearGradient.primaryGradient :
                            LinearGradient(gradient: Gradient(colors: [
                                LumenColors.navyLight,
                                LumenColors.navyLight
                            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ?
                                    LinearGradient.primaryGradient :
                                    LinearGradient(gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.1)
                                    ]), startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
    
}
