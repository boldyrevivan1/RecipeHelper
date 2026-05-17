import UserNotifications

final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized
        }
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleNotifications(for products: [FSProduct]) async {
        let center = UNUserNotificationCenter.current()

        let pending = await center.pendingNotificationRequests()
        let ids = pending
            .filter { $0.identifier.hasPrefix("product-expiry-") }
            .map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        let now = Date()
        for product in products {
            guard let expDate = product.expirationDate,
                  expDate > now,
                  let docId = product.id else { continue }

            if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: expDate) {
                await schedule(
                    id: "product-expiry-\(docId)-1d",
                    title: "⚠️ Expiring Tomorrow",
                    body: "\(product.name) expires tomorrow. Use it or add to Shopping List.",
                    date: notifyDate(from: dayBefore, hour: 9)
                )
            }

            await schedule(
                id: "product-expiry-\(docId)-0d",
                title: "🔴 Expires Today",
                body: "\(product.name) expires today!",
                date: notifyDate(from: expDate, hour: 9)
            )
        }
    }

    private func schedule(id: String, title: String, body: String, date: Date?) async {
        guard let date, date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title    = title
        content.body     = body
        content.sound    = .default
        content.badge    = 1

        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        comps.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    private func notifyDate(from date: Date, hour: Int) -> Date {
        var comps       = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour      = hour
        comps.minute    = 0
        return Calendar.current.date(from: comps) ?? date
    }

    func resetBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }
}
