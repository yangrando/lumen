//
//  LevelCard.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 29/12/25.
//

import SwiftUI

struct LevelCard: View {
    
    let level: EnglishLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Emoji
                Text(level.emoji)
                    .font(.system(size: 40))
                
                // Nome do nível
                Text(level.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                
                // Descrição
                Text(level.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(LumenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .padding(16)
            .background(
                // Se selecionado, mostra gradiente; senão, vidro fosco
                isSelected ?
                LinearGradient.primaryGradient :
                    LinearGradient(gradient: Gradient(colors: [
                        LumenColors.navyLight,
                        LumenColors.navyLight
                    ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(20)
            .overlay(
                // Borda animada quando selecionado
                RoundedRectangle(cornerRadius: 20)
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

