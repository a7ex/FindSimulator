//
//  main.swift
//  findsimulator
//
//  Created by Alex da Franca on 23.06.21.
//

import Foundation
import ArgumentParser

private let marketingVersion = "0.2"

struct findsimulator: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Interface to simctl in order to get suitable strings for destinations for the xcodebuild command."
    )
    
    @Option(name: .shortAndLong, help: "The os type. It can be either 'ios', 'watchos' or 'tvos'. Defaults to 'ios'. Does only apply without '-pairs' option.")
    var osType = "ios"

    @Option(name: .shortAndLong, help: "The major OS version. Can be something like '12' or '14' or 'latest', which is the latest installed major version. Does only apply without '-pairs' option.")
    var majorOSVersion = "latest"

    @Option(name: .shortAndLong, help: "The minor OS version. Can be something like '2' or '4' or 'latest', which is the latest installed minor version of a given major version. Note, if 'majorOSVersion' is set to 'latest', then minor version will also be 'latest'. Does only apply without '-pairs' option.")
    var subOSVersion = "latest"
    
    @Flag(name: .shortAndLong, help: "Find and iPhone in available iPhone/Watch Pairs.")
    var pairs: Int

    @Flag(name: .shortAndLong, help: "List all available and mathcing simulators.")
    var listAll: Int
    
    @Flag(name: .shortAndLong, help: "Print version of this tool.")
    var version: Int
    
    @Argument(help: "A string contains check on the name to constrain results.")
    var name_contains = ""
    
    mutating func run() throws {
        guard version != 1 else {
            printVersion()
            return
        }
        let controller = SimulatorControl()
        if pairs == 1 {
            let rslt = controller.pairId()
            switch rslt {
            case .success(let pairs):
                var success = false
                for (_, pair) in pairs.pairs {
                    if pair.isAvailable,
                       (name_contains.isEmpty || pair.phone.name.contains(name_contains)) {
                        success = true
                        if listAll == 1 {
                            print("\(pair.phone.udid): \(pair.phone.name)")
                        } else {
                            print(pair.phone.udid)
                            break
                        }
                    }
                }
                if !success {
                    throw(NSError.noDeviceFound)
                }
            case .failure(let error):
                throw(error)
            }
        } else {
            let rslt = controller.simulatorId(pattern: name_contains)
            switch rslt {
            case .success(let pairs):
                let targetMajorVersion: Int
                let targetSubVersion: Int
                if majorOSVersion.lowercased() == "latest" {
                    targetMajorVersion = pairs.enabledOSVersions
                        .filter { osType.lowercased() == $0.name.lowercased() }
                        .sorted(by: { $0.majorVersion > $1.majorVersion }).first?.majorVersion ?? 0
                    targetSubVersion = 0

                } else {
                    targetMajorVersion = Int(majorOSVersion) ?? 0
                    if subOSVersion.lowercased() == "latest" {
                        guard targetMajorVersion > 0 else {
                            throw(NSError.noMajorVersionProvided)
                        }
                        targetSubVersion = pairs.enabledOSVersions
                            .filter { osType.lowercased() == $0.name.lowercased() }
                            .filter { $0.majorVersion == targetMajorVersion }
                            .sorted(by: { $0.minorVersion > $1.minorVersion }).first?.minorVersion ?? 0
                    } else {
                        targetSubVersion = Int(subOSVersion) ?? 0
                    }
                }
                var success = false
                for (os, group) in pairs.devices {
                    if let osVersion = OsVersion(string: os) {
                        if (osType.lowercased() == osVersion.name.lowercased()),
                        (targetMajorVersion < 1 || osVersion.majorVersion == targetMajorVersion),
                           (targetSubVersion < 1 || osVersion.minorVersion == targetSubVersion){
                            for device in group {
                                if device.isAvailable == true {
                                    if listAll == 1 {
                                        print("\(device.udid): \(device.name)")
                                    } else {
                                        print(device.udid)
                                        success = true
                                        break
                                    }
                                }
                            }
                            if success {
                                break
                            }
                        }
                    }
                }
                if listAll != 1,
                   !success {
                    throw(NSError.noDeviceFound)
                }
            case .failure(let error):
                throw(error)
            }
        }
    }
    
    private func printVersion() {
        print(marketingVersion)
    }
}
private extension NSError {
    static let noDeviceFound: NSError = {
        let domain = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? "com.farbflash"
        return NSError(domain: "\(domain).error", code: 1, userInfo: [NSLocalizedDescriptionKey: "- No device found -"])
    }()

    static let noMajorVersionProvided: NSError = {
        let domain = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? "com.farbflash"
        return NSError(domain: "\(domain).error", code: 2, userInfo: [NSLocalizedDescriptionKey: "When specifying 'latest' for the minor OS version, you must provide a majorVersion."])
    }()
}

findsimulator.main()

