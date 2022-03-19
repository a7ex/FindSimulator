//
//  SimulatorListResult.swift
//
//  Created by Alex da Franca on 19.03.22.
//

import Foundation

/// Codable response object of 'simctl -j' (JSON) output.
struct SimulatorListResult: Codable {
    let devices: [String: [SimulatorInfo]]
}
