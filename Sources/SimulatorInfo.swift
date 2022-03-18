//
//  SimulatorInfo.swift
//  findsimulator
//
//  Created by Alex da Franca on 23.06.21.
//

import Foundation

struct SimulatorInfo: Codable {
    let udid: String // "60D88D7C-7E8D-4F9F-8CB7-51C0D6CA77A3",
    let name: String // "iPhone 12 Pro"
    let state: String // "Shutdown",
    
    let dataPath: String? // "\/Users\/miniagent-05\/Library\/Developer\/CoreSimulator\/Devices\/60D88D7C-7E8D-4F9F-8CB7-51C0D6CA77A3\/data",
    let logPath: String? // "\/Users\/miniagent-05\/Library\/Logs\/CoreSimulator\/60D88D7C-7E8D-4F9F-8CB7-51C0D6CA77A3",
    let isAvailable: Bool? // true,
    let deviceTypeIdentifier: String? // "com.apple.CoreSimulator.SimDeviceType.iPhone-12-Pro",
}

struct ListResult: Codable {
    let devices: [String: [SimulatorInfo]]

    var osversions: [OsVersion] {
        return devices.keys.compactMap { OsVersion(string: $0) }
    }
    var enabledOSVersions: [OsVersion] {
        var enabledVersions = [OsVersion]()
        for (os, infos) in devices {
            if !infos.filter({ $0.isAvailable == true }).isEmpty,
               let osVersion = OsVersion(string: os) {
                enabledVersions.append(osVersion)
            }
        }
        return enabledVersions
    }
}

struct PairResult: Codable {
    let pairs: [String: DevicePair]
}

struct DevicePair: Codable {
    let phone: SimulatorInfo
    let watch: SimulatorInfo
    let state: String

    var isAvailable: Bool {
        return !state.contains("unavailable")
    }
}


struct OsVersion {
    let name: String
    let majorVersion: Int
    let minorVersion: Int

    init?(string identifier: String) {
        guard let ident = identifier.split(separator: ".").last else { return nil }
        let parts = ident.split(separator: "-")
        guard parts.count > 2 else { return nil }
        name = String(parts[0])
        majorVersion = Int(parts[1]) ?? 0
        minorVersion = Int(parts[2]) ?? 0
    }
}
