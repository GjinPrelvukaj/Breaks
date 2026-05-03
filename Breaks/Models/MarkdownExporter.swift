import Foundation
import AppKit
import UniformTypeIdentifiers

enum MarkdownExporter {
    @MainActor
    static func exportFocusJournal(_ journal: FocusJournal, projects: FocusProjectLibrary) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "md") ?? .plainText]
        panel.nameFieldStringValue = defaultFilename()
        panel.title = "Export Focus Journal"
        panel.message = "Choose where to save your focus journal as Markdown."

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let markdown = render(journal: journal, projects: projects)
        do {
            try markdown.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't save export"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    private static func defaultFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "breaks-focus-journal-\(formatter.string(from: Date())).md"
    }

    @MainActor
    private static func render(journal: FocusJournal, projects: FocusProjectLibrary) -> String {
        let calendar = Calendar.current
        let logs = journal.blockLogs.sorted { $0.date > $1.date }
        let exportDateFormatter = DateFormatter()
        exportDateFormatter.dateStyle = .full
        exportDateFormatter.timeStyle = .short

        var out: [String] = []
        out.append("# Breaks – Focus Journal")
        out.append("")
        out.append("_Exported \(exportDateFormatter.string(from: Date()))_")
        out.append("")

        if let focus = journal.priorities.first(where: { !$0.isEmpty }) {
            out.append("**Today's focus:** \(focus)")
            out.append("")
        }

        if logs.isEmpty {
            out.append("_No focus blocks recorded yet._")
            return out.joined(separator: "\n")
        }

        var byDay: [Date: [FocusBlockLog]] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            byDay[day, default: []].append(log)
        }

        let dayHeader = DateFormatter()
        dayHeader.dateFormat = "EEEE, MMM d, yyyy"

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"

        for day in byDay.keys.sorted(by: >) {
            let dayLogs = byDay[day] ?? []
            let total = dayLogs.filter { $0.outcome != .skipped }.reduce(0) { $0 + $1.minutes }
            out.append("## \(dayHeader.string(from: day))")
            out.append("")
            out.append("\(dayLogs.count) blocks · \(total) focused minutes")
            out.append("")
            for log in dayLogs.sorted(by: { $0.date < $1.date }) {
                let icon: String
                switch log.outcome {
                case .good: icon = "✓"
                case .messy: icon = "≈"
                case .skipped: icon = "✗"
                }
                let project = log.projectName.flatMap { $0.isEmpty ? nil : " · \($0)" } ?? ""
                out.append("- \(icon) **\(timeFmt.string(from: log.date))** — \(log.label) (\(log.minutes)m\(project))")
            }
            out.append("")
        }

        let activeProjects = projects.activeProjects
        if !activeProjects.isEmpty {
            out.append("## Projects")
            out.append("")
            for p in activeProjects {
                out.append("- \(p.name)")
            }
        }

        return out.joined(separator: "\n")
    }
}
