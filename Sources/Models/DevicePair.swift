//
//  File.swift
//  
//
//  Created by Alex da Franca on 19.03.22.
//

import Foundation

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
