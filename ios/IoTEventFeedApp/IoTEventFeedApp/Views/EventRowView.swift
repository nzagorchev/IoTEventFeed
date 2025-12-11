//
//  EventRowView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 11.12.25.
//

import SwiftUI

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(getSeverityColor(severity: event.severity))
                    .frame(width: 8, height: 8)
                
                Text(event.deviceName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(event.message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(event.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: event.timestamp, relativeTo: Date())
    }
}
