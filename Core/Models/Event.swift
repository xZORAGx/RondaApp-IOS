
import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var roomId: String // New property to link event to a room
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var participants: [String] // Array of User IDs
    var customColor: String // Hex color string, e.g., "#RRGGBB"
    var drinksConsumed: [EventDrinkEntry] = [] // Drinks specific to this event

    // Computed property to check if the event is currently active
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    // Equatable conformance
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
}

struct EventDrinkEntry: Codable, Identifiable, Equatable {
    let id = UUID().uuidString // Unique ID for each drink entry
    let userId: String
    let drinkId: String
    let timestamp: Date

    static func == (lhs: EventDrinkEntry, rhs: EventDrinkEntry) -> Bool {
        lhs.id == rhs.id
    }

    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "InvalidCasting", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot cast to [String: Any]"])
        }
        return dictionary
    }
}
