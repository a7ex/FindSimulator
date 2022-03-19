//
//  SimulatorControl.swift
//  findsimulator
//
//  Created by Alex da Franca on 23.06.21.
//

import Foundation

/// Interface to the simctl command line tool, which is part of the Xcode tools suite

struct SimulatorControl {
    struct ErrorResponse: Codable {
        let message: String
        let status: Int
    }

    /// The os type. It can be either 'ios', 'watchos' or 'tvos'.
    /// Note: Does only apply to filterSimulators().
    let osFilter: String

    /// The major OS version. Can be something like '12' or '14', 'all' or 'latest', which is the latest installed major version.
    /// Note: Does only apply to filterSimulators().
    let majorVersionFilter: String

    /// The minor OS version. Can be something like '2' or '4', 'all' or 'latest', which is the latest installed minor version of a given major version.
    /// Note,: If 'majorOSVersion' is set to 'latest', then minor version will also be 'latest'. Does only apply to filterSimulators().
    let minorVersionFilter: String

    /// A string contains check on the name of the simulator.
    let nameFilter: String

    private let decoder = JSONDecoder()

    // MARK: - Public interface

    /// Find simulators
    /// - Returns: Array of OsVersions objects containing available simulators, which match the specified filters.
    func filterSimulators() throws -> [OsVersion] {
        let rslt = simulatorList(pattern: nameFilter)
        switch rslt {
        case .success(let pairs):
            let (majorVersion, subVersion) = computeVersions(in: pairs, os: osFilter)
           return pairs.enabledOSVersions
                .filter { $0.isEligible(for: osFilter, major: majorVersion, minor: subVersion)}

        case .failure(let error):
            throw(error)
        }
    }

    /// Find iPhone simulators with paired AppleWatch simulators
    /// - Returns: Array of SimulatorInfo objects containing available iPhone simulators, which have paired AppleWatch simulators.
    func filterSimulatorPairs() throws -> [SimulatorInfo] {
        var simulators = [SimulatorInfo]()
        let rslt = phonesPairedWithWatch()
        switch rslt {
        case .success(let pairs):
            for (_, pair) in pairs.pairs where pair.isAvailable {
                if nameFilter.isEmpty || pair.phone.name.contains(nameFilter) {
                    simulators.append(pair.phone)
                }
            }
        case .failure(let error):
            throw(error)
        }
        return simulators
    }

    // MARK: - Private interface

    private func computeVersions(in simlist: SimulatorListResult, os: String) -> (majorVersion: Int, minorVersion: Int) {
        let majorVersion: Int
        let subVersion: Int
        if majorVersionFilter.lowercased() == "latest" {
            majorVersion = simlist.latestEnabledVersion(for: os)
            if minorVersionFilter.lowercased() == "latest" {
                subVersion = simlist.latestEnabledSubVersion(for: os, and: majorVersion)
            } else {
                subVersion = Int(minorVersionFilter) ?? 0
            }
        } else {
            majorVersion = Int(majorVersionFilter) ?? 0
            if minorVersionFilter.lowercased() == "latest",
               majorVersion > 0 {
                subVersion = simlist.latestEnabledSubVersion(for: os, and: majorVersion)
            } else {
                subVersion = Int(minorVersionFilter) ?? 0
            }
        }
        return (majorVersion: majorVersion, minorVersion: subVersion)
    }

    // MARK: - Interface to simctl command line tool
    
    private func simulatorList(pattern: String) -> Result<SimulatorListResult, Error> {
        var arguments = ["simctl", "list", "devices", "-j"]
        if !pattern.isEmpty {
            arguments += [pattern]
        }
        return executeJSONTask(with: arguments)
    }

    private func phonesPairedWithWatch() -> Result<PairResult, Error> {
        let arguments = ["simctl", "list", "pairs", "-j"]
        return executeJSONTask(with: arguments)
    }
    
    private func executeJSONTask<T: Decodable>(with arguments: [String]) -> Result<T, Error> {
        let rslt = execute(program: "/usr/bin/xcrun", with: arguments)
        return rslt.flatMap { data in
            let rslt = Result { try decoder.decode(T.self, from: data) }
            return rslt
        }
    }
    
    private func execute(program: String, with arguments: [String]) -> Result<Data, Error> {
        let task = Process()
        task.launchPath = program
        task.arguments = arguments
        
        // // comment out for debugging purposes:
        // print("executing now:\n\(program) \(arguments.joined(separator: " "))")
        
        let outPipe = Pipe()
        task.standardOutput = outPipe // to capture standard error, use task.standardError = outPipe
        let errorPipe = Pipe()
        task.standardError = errorPipe
        task.launch()
        let fileHandle = outPipe.fileHandleForReading
        let data = fileHandle.readDataToEndOfFile()
        let errorHandle = errorPipe.fileHandleForReading
        let errorData = errorHandle.readDataToEndOfFile()
        task.waitUntilExit()
        let status = task.terminationStatus
        if status != 0 {
            return .failure(NSError(message: String(data: errorData, encoding: .utf8) ?? "", status: Int(status)))
        } else {
            if let error = try? decoder.decode(ErrorResponse.self, from: data) {
                return .failure(NSError(message: error.message, status: error.status))
            }
            // print(String(decoding: data, as: UTF8.self))
            return .success(data)
        }
    }
}

/// Map result from simctl call
private extension SimulatorListResult {
    var enabledOSVersions: [OsVersion] {
        return osversions.filter { $0.containsEnabledSimulators }
    }
    func latestEnabledVersion(for platform: String) -> Int {
        return enabledOSVersions
            .filter { platform.lowercased() == $0.name.lowercased() }
            .sorted(by: { $0.majorVersion > $1.majorVersion }).first?.majorVersion ?? 0
    }
    func latestEnabledSubVersion(for platform: String, and majorVersion: Int) -> Int {
        return enabledOSVersions
            .filter { platform.lowercased() == $0.name.lowercased() }
            .filter { $0.majorVersion == majorVersion }
            .sorted(by: { $0.minorVersion > $1.minorVersion }).first?.minorVersion ?? 0
    }
    private var osversions: [OsVersion] {
        return devices
            .enumerated()
            .compactMap { OsVersion(string: $0.element.key, simulators: $0.element.value) }
    }
}

private extension OsVersion {
    var containsEnabledSimulators: Bool {
        return !simulators.filter({ $0.isAvailable == true }).isEmpty
    }
    func isEligible(for osType: String, major: Int, minor: Int) -> Bool {
        return (osType.lowercased() == name.lowercased()) &&
        (major < 1 || majorVersion == major) &&
        (minor < 1 || minorVersion == minor)
    }
}

private extension NSError {
    convenience init(message: String, status: Int = 1) {
        let domain = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? "com.farbflash"
        self.init(domain: "\(domain).error", code: status, userInfo: [NSLocalizedDescriptionKey: message])
    }
    static let noMajorVersionProvided: NSError = {
        let domain = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? "com.farbflash"
        return NSError(domain: "\(domain).error", code: 2, userInfo: [NSLocalizedDescriptionKey: "When specifying 'latest' for the minor OS version, you must provide a majorVersion."])
    }()
}
