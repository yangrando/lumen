//
//  InterestCard.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 29/12/25.
//

import SwiftUI


struct InterestCard: View {
    
    let interest: UserInterest
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Interest icon
                Image(systemName: interest.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : LumenColors.textSecondary)
                
                // Interest name
                Text(interest.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : LumenColors.textSecondary)
                    .lineLimit(1)
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
