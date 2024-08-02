//
//  OsVersion.swift
//
//  Created by Alex da Franca on 18.03.22.
//

import Foundation

/// Data for a specific OS version
///
/// Can only be initialized successfully with a string in the format:
/// xxxxxx.xxxxxxx.xxxxxx.os-major-minor
///
/// Example:
/// com.apple.CoreSimulator.SimRuntime.iOS-15-2
/// or:
/// com.apple.CoreSimulator.SimRuntime.tvOS-15-4
///
struct OsVersion {
    let name: String
    let majorVersion: Int
    let minorVersion: Int
    let simulators: [SimulatorInfo]
}

extension OsVersion {
    init?(string identifier: String, simulators: [SimulatorInfo]) {
        guard let ident = identifier.split(separator: ".").last else { return nil }
        let parts = ident.split(separator: "-")
        guard parts.count > 2 else { return nil }
        name = String(parts[0])
        majorVersion = Int(parts[1]) ?? 0
        minorVersion = Int(parts[2]) ?? 0
        self.simulators = simulators
    }
}
