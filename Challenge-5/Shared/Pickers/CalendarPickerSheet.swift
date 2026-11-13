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
    public var showCardChrome: Bool = true
    public let onDismiss: () -> Void
    
    @State private var displayedMonth: Date = Date()
    @State private var isShowingMonthYearPicker: Bool = false
    
    private let calendar = Calendar.current
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    // MARK: - Initializer
    public init(
        selectedDate: Binding<Date>,
        minimumDate: Date? = Date(),
        showCardChrome: Bool = true,
        onDismiss: @escaping () -> Void
    ) {
        self._selectedDate = selectedDate
        self.minimumDate = minimumDate
        self.showCardChrome = showCardChrome
        self.onDismiss = onDismiss
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 16) {
            // Month navigation header
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingMonthYearPicker.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(monthYearString(from: displayedMonth))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppColors.primaryBlack)
                        
                        Image(systemName: isShowingMonthYearPicker ? "chevron.down" : "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.primaryBlue)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if !isShowingMonthYearPicker {
                    HStack(spacing: 22) {
                        Button {
                            changeMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(
                                    canGoToPreviousMonth
                                        ? AppColors.primaryBlack
                                        : Color(hex: "#C7C7CC")
                                )
                        }
                        .disabled(!canGoToPreviousMonth)
                        
                        Button {
                            changeMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppColors.primaryBlack)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            
            if isShowingMonthYearPicker {
                monthYearWheelPicker
            } else {
                // Weekdays header row
                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "#8E8E93"))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Days grid
                let days = generateDaysInMonth(for: displayedMonth)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, date in
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
                                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(
                                        isSelected
                                            ? .white
                                            : (isPast ? Color(hex: "#C7C7CC") : AppColors.primaryBlack)
                                    )
                                    .frame(width: 36, height: 36)
                                    .background {
                                        if isSelected {
                                            Circle().fill(AppColors.primaryBlack)
                                        } else if isToday {
                                            Circle().fill(Color(hex: "#E5E5EA"))
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .disabled(isPast)
                        } else {
                            Color.clear.frame(width: 36, height: 36)
                        }
                    }
                }
            }
        }
        .padding(AppDimensions.cardInternalPadding)
        .background {
            if showCardChrome {
                RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                            .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            } else {
                Color.white
            }
        }
        .environment(\.colorScheme, .light)
    }
    
    // MARK: - Helpers
    private var monthYearWheelPicker: some View {
        let minYear = minimumDate.map { calendar.component(.year, from: $0) } ?? 2000
        let currentYear = calendar.component(.year, from: displayedMonth)
        let startYear = min(minYear, currentYear)
        let years = Array(startYear...(max(startYear, currentYear) + 10))
        let monthSymbols = calendar.monthSymbols
        
        let selectedMonthBinding = Binding<Int>(
            get: { calendar.component(.month, from: displayedMonth) },
            set: { newMonth in
                updateDisplayedMonth(month: newMonth, year: calendar.component(.year, from: displayedMonth))
            }
        )
        
        let selectedYearBinding = Binding<Int>(
            get: { calendar.component(.year, from: displayedMonth) },
            set: { newYear in
                updateDisplayedMonth(month: calendar.component(.month, from: displayedMonth), year: newYear)
            }
        )
        
        return HStack(spacing: 0) {
            Picker("Month", selection: selectedMonthBinding) {
                ForEach(1...12, id: \.self) { month in
                    Text(monthSymbols[month - 1]).tag(month)
                }
            }
            .pickerStyle(.wheel)
            
            Picker("Year", selection: selectedYearBinding) {
                ForEach(years, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.wheel)
        }
        .frame(height: 180)
    }
    
    private func updateDisplayedMonth(month: Int, year: Int) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let targetDate = calendar.date(from: components) else { return }
        
        if let minimumDate,
           let minMonthStart = calendar.dateInterval(of: .month, for: minimumDate)?.start,
           targetDate < minMonthStart {
            displayedMonth = minMonthStart
        } else {
            displayedMonth = targetDate
        }
    }

    private var canGoToPreviousMonth: Bool {
        guard let minimumDate,
              let currentMonthStart = calendar.dateInterval(of: .month, for: displayedMonth)?.start,
              let minMonthStart = calendar.dateInterval(of: .month, for: minimumDate)?.start else {
            return true
        }
        return currentMonthStart > minMonthStart
    }
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
