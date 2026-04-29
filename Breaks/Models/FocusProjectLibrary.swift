//
//  FocusProjectLibrary.swift
//  Breaks
//
//  User-defined projects that tag focus blocks. Persisted as JSON.
//

import Foundation
import Combine
import SwiftUI

struct FocusProject: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String?
    var archived: Bool

    init(id: UUID = UUID(), name: String, colorHex: String? = nil, archived: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.archived = archived
    }

    var color: Color? {
        guard let colorHex else { return nil }
        return Color(hex: colorHex)
    }
}

@MainActor
final class FocusProjectLibrary: ObservableObject {
    @Published var projects: [FocusProject] { didSet { save() } }

    private let ud = UserDefaults.shared
    private let key = "focusProjectLibrary"

    init() {
        if let data = ud.data(forKey: key),
           let decoded = try? JSONDecoder().decode([FocusProject].self, from: data) {
            projects = decoded
        } else {
            projects = []
        }
    }

    var activeProjects: [FocusProject] {
        projects.filter { !$0.archived }
    }

    func project(for id: UUID?) -> FocusProject? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    func add(name: String, colorHex: String? = nil) -> FocusProject {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let project = FocusProject(name: clean.isEmpty ? "Untitled" : clean, colorHex: colorHex)
        projects.append(project)
        return project
    }

    func update(_ project: FocusProject) {
        guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[idx] = project
    }

    func rename(_ id: UUID, to name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[idx].name = clean
    }

    func setArchived(_ id: UUID, archived: Bool) {
        guard let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[idx].archived = archived
    }

    func setColor(_ id: UUID, colorHex: String?) {
        guard let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[idx].colorHex = colorHex
    }

    func remove(_ id: UUID) {
        projects.removeAll { $0.id == id }
    }

    func move(from offsets: IndexSet, to destination: Int) {
        projects.move(fromOffsets: offsets, toOffset: destination)
    }

    func duplicate(_ id: UUID) {
        guard let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        var copy = projects[idx]
        copy.id = UUID()
        copy.name = "\(copy.name) Copy"
        projects.insert(copy, at: idx + 1)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(projects) {
            ud.set(data, forKey: key)
        }
    }
}
