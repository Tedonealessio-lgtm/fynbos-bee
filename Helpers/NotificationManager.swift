import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            print(granted ? "✅ Notifiche autorizzate" : "❌ Notifiche negate")
        }
    }

    func scheduleInspectionReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🔍 Fynbos Bee"
        content.body = "I tuoi alveari hanno bisogno di ispezione! Torna a Grootbos. 🐝"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 86400, // 24 ore
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "inspection",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleQueenWarning(hiveName: String) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Regina in pericolo!"
        content.body = "\(hiveName): la regina sta invecchiando. Sostituiscila prima che sia tardi!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3600, // 1 ora
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "queen_\(hiveName)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleWinterWarning() {
        let content = UNMutableNotificationContent()
        content.title = "❄️ Inverno a Grootbos"
        content.body = "Le tue api soffrono il freddo! Compra sciroppo di zucchero nello shop."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 43200, // 12 ore
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "winter",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
