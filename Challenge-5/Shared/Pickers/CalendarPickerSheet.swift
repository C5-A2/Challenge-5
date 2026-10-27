//
//  CalendarPickerSheet.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Custom monthly calendar picker popover matching the Occasion Form Date input flow in the design specs.
public struct CalendarPickerSheet: View {
    
    // MARK: - Bindings & Properties
    @Binding public var selectedDate: Date
    public var minimumDate: Date? = Date()
    public let onDismiss: () -> Void
    
    @State private var displayedMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    // MARK: - Initializer
    public init(
        selectedDate: Binding<Date>,
        minimumDate: Date? = Date(),
        onDismiss: @escaping () -> Void
    ) {
        self._selectedDate = selectedDate
        self.minimumDate = minimumDate
        self.onDismiss = onDismiss
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 16) {
            // Month navigation header
            HStack {
                Text(monthYearString(from: displayedMonth))
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.espressoTitle)
                    }
                    
                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.espressoTitle)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // Weekdays header row
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.mutedCaption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid
            let days = generateDaysInMonth(for: displayedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date {
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isToday = calendar.isDateInToday(date)
                        let isPast = minimumDate != nil && date < calendar.startOfDay(for: minimumDate!)
                        
                        Button {
                            if !isPast {
                                selectedDate = date
                                onDismiss()
                            }
                        } label: {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(
                                    isSelected ? .white : (isPast ? AppColors.mutedCaption.opacity(0.35) : AppColors.bodyText)
                                )
                                .frame(width: 32, height: 32)
                                .background {
                                    if isSelected {
                                        Circle().fill(AppColors.primaryDark)
                                    } else if isToday {
                                        Circle().strokeBorder(AppColors.primaryDark, lineWidth: 1)
                                    }
                                }
                        }
                        .disabled(isPast)
                    } else {
                        Color.clear.frame(width: 32, height: 32)
                    }
                }
            }
        }
        .padding(AppDimensions.cardInternalPadding)
        .background(
            RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                        .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        )
    }
    
    // MARK: - Helpers
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
    
    private func generateDaysInMonth(for monthDate: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate),
              let firstDayOfWeek = calendar.dateComponents([.weekday], from: monthInterval.start).weekday,
              let numberOfDays = calendar.range(of: .day, in: .month, for: monthDate)?.count else {
            return []
        }
        
        var days: [Date?] = []
        // Fill offset from Sunday (1) to start
        for _ in 1..<firstDayOfWeek {
            days.append(nil)
        }
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        return days
    }
}

// MARK: - Preview
#Preview {
    CalendarPickerSheet(selectedDate: .constant(Date())) { }
        .padding()
}
