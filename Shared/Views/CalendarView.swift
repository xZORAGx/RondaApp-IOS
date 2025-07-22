// Fichero: RondaApp/Features/Events/Views/CalendarView.swift (Rediseñado)

import SwiftUI

struct CalendarView: View {
    let events: [Event]

    @State private var currentDate = Date()

    var body: some View {
        VStack {
            // 1. Cabecera interactiva para cambiar de mes
            calendarHeader
            
            // 2. La parrilla del calendario con el nuevo estilo
            calendarGrid
        }
        .padding()
        .background(.white.opacity(0.05))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
    
    // MARK: - Subvistas
    
    /// La cabecera con el nombre del mes y los botones de navegación.
    private var calendarHeader: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left.circle.fill")
            }
            
            Spacer()
            
            Text(monthYearFormatter.string(from: currentDate))
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right.circle.fill")
            }
        }
        .font(.title2)
        .tint(.purple)
        .padding(.bottom, 10)
    }
    
    /// La parrilla que muestra los días de la semana y los números del mes.
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }

            ForEach(daysInMonth(), id: \.self) { day in
                if day == 0 {
                    Rectangle().fill(Color.clear)
                } else {
                    dayCell(for: day)
                }
            }
        }
    }
    
    /// La celda individual para cada día, con su número e indicador de evento.
    @ViewBuilder
    private func dayCell(for day: Int) -> some View {
        let date = dateFor(day: day)
        let eventOnDay = event(for: date)
        let isToday = Calendar.current.isDateInToday(date)
        
        ZStack {
            if isToday {
                Circle()
                    .fill(Color.purple.opacity(0.6))
                    .frame(width: 35, height: 35)
            }
            
            Text("\(day)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if let event = eventOnDay {
                Circle()
                    .fill(Color(hex: event.customColor) ?? .purple)
                    .frame(width: 6, height: 6)
                    .offset(y: 16)
                    .shadow(color: Color(hex: event.customColor) ?? .purple, radius: 3)
            }
        }
        .frame(height: 35)
    }

    // MARK: - Lógica y Helpers
    
    private var daysOfWeek: [String] {
        return Calendar.current.veryShortWeekdaySymbols
    }
    
    private func daysInMonth() -> [Int] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))
        else { return [] }
        
        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
        let offset = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7

        var days: [Int] = Array(repeating: 0, count: offset)
        days.append(contentsOf: range)
        return days
    }
    
    private func event(for date: Date) -> Event? {
        return events.first { event in
            guard let eventInterval = Calendar.current.dateInterval(of: .day, for: date) else { return false }
            return eventInterval.intersects(event.dateInterval)
        }
    }
    
    private func dateFor(day: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month], from: currentDate)
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

    private func changeMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }
}

// Extensión sobre el modelo Event para simplificar la lógica de fechas
extension Event {
    var dateInterval: DateInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate
        return DateInterval(start: startOfDay, end: endOfDay)
    }
}
