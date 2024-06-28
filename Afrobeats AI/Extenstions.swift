//
//  Extenstions.swift
//  AfroBeats AI
//
//  Created by Alex Paul on 5/20/24.
//

import Foundation
import SwiftUI
extension LyricsViewModel {
    struct RecentSearch: Hashable, Identifiable {
        var id = UUID()
        let artist: String
        let title: String
    }
}


extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff

        self.init(
            red: Double(r) / 0xff,
            green: Double(g) / 0xff,
            blue: Double(b) / 0xff
        )
    }
}
import Foundation

struct Configuration {
    static func value(for key: String) -> Any? {
        guard let path = Bundle.main.path(forResource: "Configuration", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) else {
            return nil
        }
        return config[key]
    }
}
