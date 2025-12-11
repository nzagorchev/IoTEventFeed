//
//  NewEventsBannerView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import SwiftUI

struct NewEventsBannerView: View {
    let totalCount: Int
    let criticalCount: Int
    let onRefresh: () -> Void
    @Binding var isPresented: Bool
    
    var body: some View {
        if isPresented {
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    if criticalCount > 0 {
                        Text("\(totalCountText) (\(criticalCount) critical)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    } else {
                        Text(totalCountText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    onRefresh()
                }) {
                    Text("Refresh")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(6)
                }
                
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
            .background(criticalCount > 0 ? Color.red : Color.blue)
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    private var totalCountText: String {
        "\(totalCount) new event\(totalCount == 1 ? "" : "s")"
    }
}

#Preview {
    VStack {
        NewEventsBannerView(
            totalCount: 5,
            criticalCount: 2,
            onRefresh: {},
            isPresented: .constant(true)
        )
        
        NewEventsBannerView(
            totalCount: 3,
            criticalCount: 0,
            onRefresh: {},
            isPresented: .constant(true)
        )
        
        Spacer()
    }
}

