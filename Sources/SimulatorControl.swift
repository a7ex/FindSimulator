//
//  SimulatorControl.swift
//  findsimulator
//
//  Created by Alex da Franca on 23.06.21.
//

import Foundation

/// Interface to the simctl command line tool, which is part of the Xcode tools suite

struct SimulatorControl {
    /// The os type. It can be either 'ios', 'watchos' or 'tvos'.
    /// Note: Does only apply to filterSimulators().
    let osFilter: String

    /// The major OS version. Can be something like '12' or '14', 'all' or 'latest', which is the latest installed major version.
    /// Note: Does only apply to filterSimulators().
    let majorVersionFilter: String

    /// The minor OS version. Can be something like '2' or '4', 'all' or 'latest', which is the latest installed minor version of a given major version.
    /// Note,: If 'majorOSVersion' is set to 'latest', then minor version will also be 'latest'. Does only apply to filterSimulators().
    let minorVersionFilter: String

    /// A more flexible regex check on the name of the simulator.
    let regexPattern: String

    /// A simple "string.contains" check on the name of the simulator.
    let nameFilter: String

    private let shell: Shell
    private let decoder = JSONDecoder()

    // MARK: - Public interface

    init(
        osFilter: String,
        majorVersionFilter: String,
        minorVersionFilter: String,
        nameFilter: String,
        regexPattern: String,
        shell: Shell = ShellCommand()
    ) {
        self.osFilter = osFilter
        self.majorVersionFilter = majorVersionFilter
        self.minorVersionFilter = minorVersionFilter
        self.nameFilter = nameFilter
        self.regexPattern = regexPattern
        self.shell = shell
    }

    /// Find simulators
    /// - Returns: Array of OsVersions objects containing available simulators, which match the specified filters.
    func filterSimulators() throws -> [OsVersion] {
        let rslt = simulatorList(pattern: nameFilter)
        switch rslt {
        case .success(let pairs):
            let (majorVersion, subVersion) = computeVersions(in: pairs, os: osFilter)
           return pairs
                .enabledOSVersions
                .filteredByRegex(pattern: regexPattern)
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
        let rslt = shell.execute(program: "/usr/bin/xcrun", with: arguments)
        return rslt.flatMap { data in
            let rslt = Result { try decoder.decode(T.self, from: data) }
            return rslt
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

extension Array where Element == OsVersion {
    func filteredByRegex(pattern regexPattern: String) -> [OsVersion] {
        guard let regex = try? Regex(regexPattern) else {
            return self
        }
        return compactMap { osversion in
            let filteredSimulators = osversion.simulators.filter { simulator in
                return !simulator.name.ranges(of: regex).isEmpty
            }
            if !filteredSimulators.isEmpty {
                return OsVersion(
                    name: osversion.name,
                    majorVersion: osversion.majorVersion,
                    minorVersion: osversion.minorVersion,
                    simulators: filteredSimulators
                )
            }
            return nil
        }
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
