//
//  MenuContentView.swift
//  sleeper
//
//  Created by Berkecan Özgür on 17.09.2025.
//

import SwiftUI

struct MenuContentView: View {
    @State private var selectedDate = DateUtilities.minimumSelectableDate()
    @State private var showingScheduleView = false
    
    let onSchedule: (Date) -> Void
    let onCancel: () -> Void
    let onQuit: () -> Void
    
    // Optional parameters for showing active schedule info
    let isScheduleActive: Bool
    let scheduleInfo: String?
    let canSchedule: Bool
    
    init(onSchedule: @escaping (Date) -> Void, 
         onCancel: @escaping () -> Void, 
         onQuit: @escaping () -> Void,
         isScheduleActive: Bool = false,
         scheduleInfo: String? = nil,
         canSchedule: Bool = true) {
        self.onSchedule = onSchedule
        self.onCancel = onCancel
        self.onQuit = onQuit
        self.isScheduleActive = isScheduleActive
        self.scheduleInfo = scheduleInfo
        self.canSchedule = canSchedule
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if showingScheduleView {
                scheduleView
            } else {
                mainMenuView
            }
        }
        .frame(width: 280)
    }
    
    private var mainMenuView: some View {
        VStack(spacing: 8) {
            // Title
            HStack {
                Image(systemName: isScheduleActive ? "clock.badge.checkmark" : "moon.zzz")
                    .foregroundColor(isScheduleActive ? .green : .primary)
                Text("Sleep Scheduler")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            Divider()
            
            // Active schedule info (if any)
            if isScheduleActive, let scheduleInfo = scheduleInfo {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text(scheduleInfo)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    
                    Button(action: onCancel) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Cancel Current Schedule")
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                
                Divider()
            }
            
            // Schedule button
            Button(action: {
                if canSchedule {
                    showingScheduleView = true
                }
            }) {
                HStack {
                    Image(systemName: isScheduleActive ? "clock.badge.plus" : "clock.badge.plus")
                    Text(isScheduleActive ? "Schedule Another Sleep..." : "Schedule New Sleep...")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canSchedule)
            .opacity(canSchedule ? 1.0 : 0.6)
            
            Divider()
            
            // Quit button
            Button(action: onQuit) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Sleep Scheduler")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.bottom, 8)
    }
    
    private var scheduleView: some View {
        VStack(spacing: 12) {
            // Header with back button
            HStack {
                Button(action: {
                    showingScheduleView = false
                }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Schedule Sleep")
                    .font(.headline)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            Divider()
            
            // Date picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Select sleep time:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                DatePicker(
                    "Sleep Time",
                    selection: $selectedDate,
                    in: DateUtilities.minimumSelectableDate()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                
                // Validation message
                if let validationError = DateUtilities.validateScheduleDate(selectedDate) {
                    Text(validationError)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            
            Divider()
            
            // Action buttons
            HStack(spacing: 8) {
                Button("Cancel") {
                    showingScheduleView = false
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Schedule") {
                    if DateUtilities.validateScheduleDate(selectedDate) == nil {
                        onSchedule(selectedDate)
                        showingScheduleView = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(DateUtilities.validateScheduleDate(selectedDate) != nil)
                .keyboardShortcut(.return)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
}

struct MenuContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MenuContentView(
                onSchedule: { _ in },
                onCancel: { },
                onQuit: { }
            )
            .previewDisplayName("Idle State")
            
            MenuContentView(
                onSchedule: { _ in },
                onCancel: { },
                onQuit: { },
                isScheduleActive: true,
                scheduleInfo: "Next sleep: Dec 25, 2024 at 23:30",
                canSchedule: true
            )
            .previewDisplayName("Active Schedule")
        }
    }
}