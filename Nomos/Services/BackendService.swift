import Foundation
import Combine

/// Service for communicating with the anonymous backend
class BackendService: ObservableObject {
    static let shared = BackendService()
    
    private let baseURL: String
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Replace with your actual backend URL
        self.baseURL = "https://your-backend-url.com/api"
    }
    
    // MARK: - Event Submission
    
    /// Submits an anonymous event to the backend
    func submitEvent(_ eventType: AgoraEvent.EventType) async throws {
        let timezone = TimeZone.current.identifier
        let event = AnonymousEventRequest(eventType: eventType.rawValue, timezone: timezone)
        
        guard let url = URL(string: "\(baseURL)/event") else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(event)
            request.httpBody = jsonData
            
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                throw BackendError.serverError
            }
        } catch {
            throw BackendError.networkError(error)
        }
    }
    
    // MARK: - Event Fetching
    
    /// Fetches recent events from the backend
    func fetchEvents() async throws -> [AgoraEvent] {
        guard let url = URL(string: "\(baseURL)/events") else {
            throw BackendError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                throw BackendError.serverError
            }
            
            let eventsResponse = try JSONDecoder().decode(EventsResponse.self, from: data)
            return eventsResponse.events.map { serverEvent in
                AgoraEvent(
                    id: UUID(),
                    eventType: AgoraEvent.EventType(rawValue: serverEvent.eventType) ?? .committed,
                    timezone: serverEvent.timezone,
                    timestamp: ISO8601DateFormatter().date(from: serverEvent.timestamp) ?? Date()
                )
            }
        } catch {
            throw BackendError.networkError(error)
        }
    }
    
    // MARK: - Mock Data (for development)
    
    /// Generates mock events for development/testing
    func generateMockEvents() -> [AgoraEvent] {
        let timezones = ["Tokyo", "London", "New York", "Paris", "Sydney", "Berlin", "San Francisco", "Yerevan", "Cairo", "Mumbai"]
        let eventTypes: [AgoraEvent.EventType] = [.committed, .upheld, .forfeited]
        
        return (0..<20).map { index in
            let randomEventType = eventTypes.randomElement() ?? .committed
            let randomTimezone = timezones.randomElement() ?? "UTC"
            let randomTime = Date().addingTimeInterval(-Double.random(in: 0...(7*24*60*60))) // Last 7 days
            
            return AgoraEvent(
                id: UUID(),
                eventType: randomEventType,
                timezone: randomTimezone,
                timestamp: randomTime
            )
        }.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Request/Response Models

private struct AnonymousEventRequest: Codable {
    let eventType: String
    let timezone: String
}

private struct EventsResponse: Codable {
    let events: [ServerEvent]
}

private struct ServerEvent: Codable {
    let eventType: String
    let timezone: String
    let timestamp: String
}

// MARK: - Error Types

enum BackendError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError:
            return "Server error"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
