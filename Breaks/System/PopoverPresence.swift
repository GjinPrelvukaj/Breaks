//
//  PopoverPresence.swift
//  Breaks
//
//  Tracks whether the menu-bar popover is currently visible. Used by the
//  notification delegate to suppress banners while the user is already
//  looking at the timer.
//

import Foundation

@MainActor
enum PopoverPresence {
    static var isOpen: Bool = false
}
