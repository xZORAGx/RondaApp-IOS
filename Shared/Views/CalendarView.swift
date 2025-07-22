
//
//  CalendarView.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import SwiftUI

struct CalendarView: View {
    let events: [Event]

    @State private var currentDate = Date()

    var body: some View {
        VStack {
            Text(monthYearFormatter.string(from: currentDate))
                .font(.headline)
                .padding(.bottom, 5)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                }

                ForEach(daysInMonth(), id: \.self) { day in
                    if day == 0 { // Placeholder for empty days at the beginning of the month
                        Color.clear
                            .frame(width: 30, height: 30)
                    } else {
                        ZStack {
                            Circle()
                                .fill(colorForDay(day))
                                .frame(width: 30, height: 30)

                            Text("\(day)")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var daysOfWeek: [String] {
        Calendar.current.shortWeekdaySymbols
    }

    private func daysInMonth() -> [Int] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: currentDate)! // Force unwrap for simplicity, handle in production
        let numDays = range.count

        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth) // 1 for Sunday, 7 for Saturday

        // Adjust for starting day of the week (e.g., if week starts on Monday, and first day is Sunday)
        let offset = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7

        var days: [Int] = Array(repeating: 0, count: offset) // Add leading empty days
        days.append(contentsOf: Array(1...numDays))
        return days
    }

    private func colorForDay(_ day: Int) -> Color {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: day - 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!) else {
            return .clear
        }

        // Check if any event falls on this date
        for event in events {
            if calendar.isDate(date, inSameDayAs: event.startDate) || calendar.isDate(date, inSameDayAs: event.endDate) || (date >= event.startDate && date <= event.endDate) {
                return Color(hex: event.customColor) ?? .blue // Use event color
            }
        }
        return .clear // No event on this day
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}
