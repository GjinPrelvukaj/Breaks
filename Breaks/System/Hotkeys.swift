import SwiftUI
import Combine
import Carbon

enum HotkeyAction: CaseIterable, Identifiable {
    case startPause
    case skip
    case resetCycle

    var id: Self { self }

    var title: String {
        switch self {
        case .startPause: return "Start / pause"
        case .skip: return "Skip"
        case .resetCycle: return "Reset cycle"
        }
    }

    var systemImage: String {
        switch self {
        case .startPause: return "playpause"
        case .skip: return "forward"
        case .resetCycle: return "arrow.counterclockwise"
        }
    }
}

struct HotkeyKeyOption: Identifiable {
    let keyCode: Int
    let label: String
    var id: Int { keyCode }

    static let all: [HotkeyKeyOption] = [
        HotkeyKeyOption(keyCode: Int(kVK_Space), label: "Space"),
        HotkeyKeyOption(keyCode: Int(kVK_ANSI_B), label: "B"),
        HotkeyKeyOption(keyCode: Int(kVK_ANSI_F), label: "F"),
        HotkeyKeyOption(keyCode: Int(kVK_ANSI_N), label: "N"),
        HotkeyKeyOption(keyCode: Int(kVK_ANSI_P), label: "P"),
        HotkeyKeyOption(keyCode: Int(kVK_ANSI_R), label: "R"),
        HotkeyKeyOption(keyCode: Int(kVK_ANSI_S), label: "S"),
        HotkeyKeyOption(keyCode: Int(kVK_ANSI_T), label: "T")
    ]
}

struct HotkeyModifierOption: Identifiable {
    let modifiers: Int
    let label: String
    var id: Int { modifiers }

    static let all: [HotkeyModifierOption] = [
        HotkeyModifierOption(modifiers: Int(cmdKey + optionKey), label: "⌘⌥"),
        HotkeyModifierOption(modifiers: Int(cmdKey + shiftKey), label: "⌘⇧"),
        HotkeyModifierOption(modifiers: Int(controlKey + optionKey), label: "⌃⌥"),
        HotkeyModifierOption(modifiers: Int(controlKey + shiftKey), label: "⌃⇧")
    ]
}

class HotkeyManager: NSObject, ObservableObject {
    private var hotkeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var handlers: [UInt32: () -> Void] = [:]
    private var eventHandlerRef: EventHandlerRef?

    func reloadHotkeys(settings: TimerSettings) {
        unregisterHotkeys()
        registerHotkey(key: UInt32(settings.startHotkeyKeyCode), modifiers: UInt32(settings.startHotkeyModifiers), id: 1)
        registerHotkey(key: UInt32(settings.skipHotkeyKeyCode), modifiers: UInt32(settings.skipHotkeyModifiers), id: 2)
        registerHotkey(key: UInt32(settings.resetHotkeyKeyCode), modifiers: UInt32(settings.resetHotkeyModifiers), id: 3)
    }

    private func registerHotkey(key: UInt32, modifiers: UInt32, id: UInt32) {
        var hotkeyRef: EventHotKeyRef?
        let hotkeyID = EventHotKeyID(signature: OSType("BrkH".utf8.reduce(0, { ($0 << 8) + OSType($1) })), id: id)
        let status = RegisterEventHotKey(key, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        guard status == noErr, let ref = hotkeyRef else { return }
        hotkeyRefs[id] = ref
    }

    func setHandler(for id: UInt32, action: @escaping () -> Void) {
        handlers[id] = action
        if eventHandlerRef == nil {
            installCarbonEventHandler()
        }
    }

    private func installCarbonEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let userData = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            let mySelf = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()
            var hotkeyID = EventHotKeyID()
            let err = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)
            if err == noErr {
                mySelf.handlers[hotkeyID.id]?()
            }
            return noErr
        }, 1, &eventType, userData, &eventHandlerRef)
        if status != noErr {
            print("Failed to install Carbon event handler")
        }
    }

    private func unregisterHotkeys() {
        for (_, ref) in hotkeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotkeyRefs.removeAll()
    }

    deinit {
        unregisterHotkeys()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }
}
