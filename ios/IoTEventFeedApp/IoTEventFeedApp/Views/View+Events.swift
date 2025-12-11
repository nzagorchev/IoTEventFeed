//
//  View+Events.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 11.12.25.
//

import SwiftUI

extension View {
    func getSeverityColor(severity: String) -> Color {
        switch severity.lowercased() {
        case "critical":
            return .red
        case "error":
            return .orange
        case "warning":
            return .yellow
        case "info":
            return .blue
        default:
            return .gray
        }
    }
    
    func OfflineBanner(isPresented: Binding<Bool>) -> BannerView {
        return BannerView(
            message: "You are currently offline",
            type: .warning,
            isPresented: isPresented
        )
    }
    
    func ErrorBanner(_ errorMessage: String, isPresented: Binding<Bool>) -> BannerView {
        BannerView(
            message: errorMessage,
            type: .error,
            isPresented: isPresented
        )
    }
}
