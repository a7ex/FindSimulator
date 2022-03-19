//
//  DevicePair.swift
//
//  Created by Alex da Franca on 19.03.22.
//

import Foundation

/// Codable response object of 'simctl -j' (JSON) output.
struct DevicePair: Codable {
    let phone: SimulatorInfo
    let watch: SimulatorInfo
    let state: String
}

extension DevicePair {
    var isAvailable: Bool {
        return !state.contains("unavailable")
    }
}
