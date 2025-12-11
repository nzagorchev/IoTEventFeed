//
//  BannerView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import SwiftUI

struct BannerView: View {
    let message: String
    let type: BannerType
    @Binding var isPresented: Bool
    
    enum BannerType {
        case error
        case warning
        case info
        
        var backgroundColor: Color {
            switch self {
            case .error:
                return .red
            case .warning:
                return .orange
            case .info:
                return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .error:
                return "exclamationmark.triangle.fill"
            case .warning:
                return "exclamationmark.circle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        if isPresented {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            .background(type.backgroundColor)
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    VStack {
        BannerView(
            message: "You are currently offline",
            type: .warning,
            isPresented: .constant(true)
        )
        
        BannerView(
            message: "Failed to load events",
            type: .error,
            isPresented: .constant(true)
        )
        
        Spacer()
    }
}

