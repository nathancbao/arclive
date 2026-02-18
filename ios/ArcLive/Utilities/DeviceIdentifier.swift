import Foundation

/// Generates and persists a stable UUID for this app installation.
///
/// On first launch a new UUID is created and saved to UserDefaults.
/// Every subsequent launch reads the same UUID back.
/// This UUID is sent with every API request as the device's identity.
enum DeviceIdentifier {
    static var id: UUID {
        let key = "arclive.device_uuid"
        if let stored = UserDefaults.standard.string(forKey: key),
           let uuid = UUID(uuidString: stored) {
            return uuid
        }
        let new = UUID()
        UserDefaults.standard.set(new.uuidString, forKey: key)
        return new
    }
}
