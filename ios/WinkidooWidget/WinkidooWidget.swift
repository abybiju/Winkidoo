import WidgetKit
import SwiftUI

private let appGroupId = "group.com.winkidoo.app"

struct WinkidooEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let pending: Int
    let prompt: String
}

struct WinkidooProvider: TimelineProvider {
    func placeholder(in context: Context) -> WinkidooEntry {
        WinkidooEntry(date: Date(), streak: 7, pending: 2,
                      prompt: "💝 Create a surprise for your partner today!")
    }

    func getSnapshot(in context: Context, completion: @escaping (WinkidooEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WinkidooEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .atEnd))
    }

    private func entry() -> WinkidooEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let streak  = defaults?.integer(forKey: "streak")  ?? 0
        let pending = defaults?.integer(forKey: "pending") ?? 0
        let prompt  = defaults?.string(forKey: "prompt")
                      ?? "💝 Create a surprise for your partner today!"
        return WinkidooEntry(date: Date(), streak: streak, pending: pending, prompt: prompt)
    }
}

struct WinkidooWidgetEntryView: View {
    var entry: WinkidooEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.14),
                         Color(red: 0.11, green: 0.06, blue: 0.19)],
                startPoint: .top, endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    Label("\(entry.streak)", systemImage: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 13, weight: .bold))
                    Label("\(entry.pending)", systemImage: "envelope.fill")
                        .foregroundColor(Color(red: 1, green: 0.4, blue: 0.6))
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                }
                Text(entry.prompt)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)
                    .italic()
            }
            .padding(12)
        }
        .containerBackground(for: .widget) {
            Color(red: 0.06, green: 0.06, blue: 0.14)
        }
        .widgetURL(URL(string: "winkidoo://shell/vault"))
    }
}

@main
struct WinkidooWidget: Widget {
    let kind = "WinkidooWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WinkidooProvider()) { entry in
            WinkidooWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Winkidoo")
        .description("Your streak, pending surprises, and a daily love prompt.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    WinkidooWidget()
} timeline: {
    WinkidooEntry(date: .now, streak: 7, pending: 2, prompt: "💝 Surprise your partner today!")
}
