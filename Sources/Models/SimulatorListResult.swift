//
//  File.swift
//  
//
//  Created by Alex da Franca on 19.03.22.
//

import Foundation

struct SimulatorListResult: Codable {
    let devices: [String: [SimulatorInfo]]
}