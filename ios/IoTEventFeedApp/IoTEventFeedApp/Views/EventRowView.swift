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
                    .frame(width: 12, height: 12)
                
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
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: event.timestamp, relativeTo: Date())
    }
}

#Preview {
    let event1 = Event(
        id: "71cae9cc-2bb3-4648-bf28-8c2e08a3265a",
        deviceID: "DEVICE-001",
        deviceName: "Device - Main Entrance",
        type: "facial_authentication",
        severity: "info",
        message: "Facial authentication successful",
        timestamp: Date().addingTimeInterval(-30),
        location: "Main Entrance, Building A",
        downloadURL: nil
    )
    
    let event2 = Event(
        id: "842cc9b7-8e03-4ed6-b33d-caf6d2e5769d",
        deviceID: "DEVICE-002",
        deviceName: "Device - Server Room Access",
        type: "access_denied",
        severity: "warning",
        message: "Access denied - Authentication failure after 3 attempts",
        timestamp: Date().addingTimeInterval(-5*60),
        location: "Server Room, Floor 3",
        downloadURL: nil
    )
    
    let events = [event1, event2]
    
    VStack(spacing: 12) {
        ForEach(events) { event in
            EventRowView(event: event)
        }
    }
    .padding(.horizontal)
    
}
