//
//  main.swift
//  findsimulator
//
//  Created by Alex da Franca on 23.06.21.
//

import Foundation
import ArgumentParser

private let marketingVersion = "0.3"

struct findsimulator: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Interface to simctl in order to get suitable strings for destinations for the xcodebuild command."
    )
    
    @Option(name: .shortAndLong, help: "The os type. It can be either 'ios', 'watchos' or 'tvos'. Does only apply without '--pairs' option.")
    var osType = "ios"

    @Option(name: .shortAndLong, help: "A regex pattern to match the device name. Does only apply without '--pairs' option.")
    var regexPattern = ""

    @Option(name: .shortAndLong, help: "The major OS version. Can be something like '12' or '14', 'all' or 'latest', which is the latest installed major version. Does only apply without '--pairs' option.")
    var majorOSVersion = "all"

    @Option(name: .shortAndLong, help: "The minor OS version. Can be something like '2' or '4', 'all' or 'latest', which is the latest installed minor version of a given major version. Note, if 'majorOSVersion' is set to 'latest', then minor version will also be 'latest'. Does only apply without '-pairs' option.")
    var subOSVersion = "all"
    
    @Flag(name: .shortAndLong, help: "Find iPhone Simulator in available iPhone/Watch Pairs.")
    var pairs: Int

    @Flag(name: .shortAndLong, help: "List all available and matching simulators.")
    var listAll: Int
    
    @Flag(name: .shortAndLong, help: "Print version of this tool.")
    var version: Int
    
    @Argument(help: "A simple 'string contains' check on the name of the simulator. Use the [-r | --regex-pattern] option for more finegrained searches instead.")
    var nameContains = ""
    
    mutating func run() throws {
        guard version != 1 else {
            printVersion()
            return
        }
        let controller = SimulatorControl(
            osFilter: osType,
            majorVersionFilter: majorOSVersion,
            minorVersionFilter: subOSVersion,
            nameFilter: nameContains,
            regexPattern: regexPattern
        )
        if pairs == 1 {
            let sims = (try controller.filterSimulatorPairs()).sorted(by: { $0.name > $1.name})
            if listAll == 1 {
                sims.forEach {
                    print("platform=iOS Simulator,id=\($0.udid),name=\($0.name)")
                }
            } else {
                if let first = sims.first {
                    print("platform=iOS Simulator,id=\(first.udid)")
                } else {
                    throw(NSError.noDeviceFound)
                }
            }
        } else {
            let versions = (try controller.filterSimulators()).sorted(by: { $0.versionString > $1.versionString})
            if listAll == 1 {
                versions.forEach { osVersion in
                    osVersion.simulators.sorted(by: { $0.name > $1.name}).forEach {
                        print("platform=\(osVersion.platform),OS=\(osVersion.versionString),id=\($0.udid),name=\($0.name)")
                    }
                }
            } else {

                if let firstVersion = versions.first,
                   let first = firstVersion.simulators.sorted(by: { $0.name > $1.name}).first {
                    print("platform=\(firstVersion.platform),id=\(first.udid)")
                } else {
                    throw(NSError.noDeviceFound)
                }
            }
        }
    }

    private func printVersion() {
        print(marketingVersion)
    }
}

private extension OsVersion {
    var versionString: String {
        return "\(majorVersion).\(minorVersion)"
    }
    var platform: String {
        return "\(name) Simulator"
    }
}

private extension NSError {
    static let noDeviceFound: NSError = {
        let domain = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? "com.farbflash"
        return NSError(domain: "\(domain).error", code: 1, userInfo: [NSLocalizedDescriptionKey: "No simulator found, wghich matches the query."])
    }()
}

findsimulator.main()
