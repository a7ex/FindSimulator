//
//  findsimulatorTests.swift
//  
//
//  Created by Alex da Franca on 02.08.24.
//

import XCTest
@testable import findsimulator

final class findsimulatorTests: XCTestCase {
    private let decoder = JSONDecoder()
    private var mockShell = MockShell()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFindSimulatorNoType() throws {
        mockShell.returnedData = mockCLIOutputDevices
        let sut = SimulatorControl(
            osFilter: "",
            majorVersionFilter: "all",
            minorVersionFilter: "all",
            nameFilter: "",
            regexPattern: "",
            shell: mockShell
        )
        let osVersions = try sut.filterSimulators()
        XCTAssertEqual(0, osVersions.count)
    }

    func testFindSimulatorNoMajorVersion() throws {
        mockShell.returnedData = mockCLIOutputDevices
        let sut = SimulatorControl(
            osFilter: "ios",
            majorVersionFilter: "",
            minorVersionFilter: "all",
            nameFilter: "",
            regexPattern: "",
            shell: mockShell
        )
        let osVersions = try sut.filterSimulators()
        XCTAssertEqual(3, osVersions.count)
    }

    func testFindSimulatorLatestMajorVersion() throws {
        mockShell.returnedData = mockCLIOutputDevices
        let sut = SimulatorControl(
            osFilter: "ios",
            majorVersionFilter: "latest",
            minorVersionFilter: "all",
            nameFilter: "",
            regexPattern: "",
            shell: mockShell
        )
        let osVersions = try sut.filterSimulators()
        XCTAssertEqual(2, osVersions.count)
    }

    func testFindSimulatorNoMinorVersion() throws {
        mockShell.returnedData = mockCLIOutputDevices
        let sut = SimulatorControl(
            osFilter: "ios",
            majorVersionFilter: "all",
            minorVersionFilter: "",
            nameFilter: "",
            regexPattern: "",
            shell: mockShell
        )
        let osVersions = try sut.filterSimulators()
        XCTAssertEqual(3, osVersions.count)
    }

    func testFindSimulatorLatestMinorVersion() throws {
        mockShell.returnedData = mockCLIOutputDevices
        let sut = SimulatorControl(
            osFilter: "ios",
            majorVersionFilter: "latest",
            minorVersionFilter: "latest",
            nameFilter: "",
            regexPattern: "",
            shell: mockShell
        )
        let osVersions = try sut.filterSimulators()
        XCTAssertEqual(1, osVersions.count)
    }

    func testFindSimulator() throws {
        mockShell.returnedData = mockCLIOutputDevices
        let sut = SimulatorControl(
            osFilter: "ios",
            majorVersionFilter: "all",
            minorVersionFilter: "all",
            nameFilter: "",
            regexPattern: "",
            shell: mockShell
        )
        let osVersions = try sut.filterSimulators()
        XCTAssertEqual(3, osVersions.count)
        let sortedVersions = osVersions.sorted { version1, version2 in
            return "\(version1.name)\(version1.majorVersion)\(version1.minorVersion)" >
            "\(version2.name)\(version2.majorVersion)\(version2.minorVersion)"
        }
        XCTAssertEqual(12, sortedVersions.first?.simulators.count)
    }

    func testFindSimulatorFilteredByContains() throws {
        mockShell.returnedData = mockCLIOutputDevices
        let sut = SimulatorControl(
            osFilter: "ios",
            majorVersionFilter: "all",
            minorVersionFilter: "all",
            nameFilter: "",
            regexPattern: "^iPhone\\s15$",
            shell: mockShell
        )
        let osVersions = try sut.filterSimulators()
        XCTAssertEqual(2, osVersions.count)
        let sortedVersions = osVersions.sorted { version1, version2 in
            return "\(version1.name)\(version1.majorVersion)\(version1.minorVersion)" >
            "\(version2.name)\(version2.majorVersion)\(version2.minorVersion)"
        }
        XCTAssertEqual(1, sortedVersions.first?.simulators.count)
    }

    func testFindSimulatorPairs() throws {
        mockShell.returnedData = mockCLIOutputPairs
        let sut = SimulatorControl(
            osFilter: "ios",
            majorVersionFilter: "all",
            minorVersionFilter: "all",
            nameFilter: "",
            regexPattern: "^iPhone\\s15$",
            shell: mockShell
        )
        let simulators = try sut.filterSimulatorPairs()
        XCTAssertEqual(5, simulators.count)
        
    }

    // Simple check, whether the simctl Xcode tool still returns the expected result for "list devices"
    func testSimCTLFormatList() throws {
        let shell = ShellCommand()
        let arguments = ["simctl", "list", "devices", "-j"]
        let rslt = shell.execute(program: "/usr/bin/xcrun", with: arguments)
        let simulatorListResult = rslt.flatMap { data in
            let rslt = Result { try decoder.decode(SimulatorListResult.self, from: data) }
            return rslt
        }
        switch simulatorListResult {
        case .success(let simulatorList):
            XCTAssertFalse(simulatorList.devices.isEmpty)
            XCTAssert(simulatorList.devices.values.first?.first?.name.isEmpty == false)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // Simple check, whether the simctl Xcode tool still returns the expected result for "list pairs"
    func testSimCTLFormatPairs() throws {
        let shell = ShellCommand()
        let arguments = ["simctl", "list", "pairs", "-j"]
        let rslt = shell.execute(program: "/usr/bin/xcrun", with: arguments)
        let simulatorListResult = rslt.flatMap { data in
            let rslt = Result { try decoder.decode(PairResult.self, from: data) }
            return rslt
        }
        switch simulatorListResult {
        case .success(let simulatorList):
            if !simulatorList.pairs.isEmpty {
                XCTAssert(simulatorList.pairs.values.first?.phone.name.isEmpty == false)
                XCTAssert(simulatorList.pairs.values.first?.watch.name.isEmpty == false)
            } else {
                // No phone/watch pairs set up in simulator. Nothing to assert.
                // Being able to decode the json is actually the assert
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    private struct MockShell: Shell {
        var returnedData: Data?
        var returnedError: Error?

        func execute(program: String, with arguments: [String]) -> Result<Data, any Error> {
            if let data = returnedData {
                return .success(data)
            } else {
                return .failure(
                    returnedError ?? NSError(domain: "com.farbflash.findsimulatore.error.general", code: 17)
                )
            }
        }
    }

    // MARK: - Test Data

    private var mockCLIOutputDevices = """
{
  "devices" : {
    "com.apple.CoreSimulator.SimRuntime.iOS-17-4" : [
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/844FA4B6-7DD2-4AA4-9B0B-D539D3488815/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/844FA4B6-7DD2-4AA4-9B0B-D539D3488815",
        "udid" : "844FA4B6-7DD2-4AA4-9B0B-D539D3488815",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
        "state" : "Shutdown",
        "name" : "iPhone SE (3rd generation)"
      },
      {
        "lastBootedAt" : "2024-05-10T12:32:23Z",
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/13094867-A44C-4F41-8D5A-4C54E4365C82/data",
        "dataPathSize" : 2255896576,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/13094867-A44C-4F41-8D5A-4C54E4365C82",
        "udid" : "13094867-A44C-4F41-8D5A-4C54E4365C82",
        "isAvailable" : true,
        "logPathSize" : 188416,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
        "state" : "Shutdown",
        "name" : "iPhone 15"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/9A97D748-FABB-4CD0-9802-13C424808328/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/9A97D748-FABB-4CD0-9802-13C424808328",
        "udid" : "9A97D748-FABB-4CD0-9802-13C424808328",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Plus",
        "state" : "Shutdown",
        "name" : "iPhone 15 Plus"
      },
      {
        "lastBootedAt" : "2024-07-26T09:04:10Z",
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/D135ADE1-6924-4D28-86F7-E11D5C03D60B/data",
        "dataPathSize" : 6098202624,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/D135ADE1-6924-4D28-86F7-E11D5C03D60B",
        "udid" : "D135ADE1-6924-4D28-86F7-E11D5C03D60B",
        "isAvailable" : true,
        "logPathSize" : 1200128,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro",
        "state" : "Shutdown",
        "name" : "iPhone 15 Pro"
      },
      {
        "lastBootedAt" : "2024-07-14T12:46:46Z",
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/4E38E5D3-0795-47A0-B1FC-F84DE765A8A1/data",
        "dataPathSize" : 2824552448,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/4E38E5D3-0795-47A0-B1FC-F84DE765A8A1",
        "udid" : "4E38E5D3-0795-47A0-B1FC-F84DE765A8A1",
        "isAvailable" : true,
        "logPathSize" : 413696,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max",
        "state" : "Shutdown",
        "name" : "iPhone 15 Pro Max"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/CF83739C-D944-48E1-AFB5-07073C8DCAC2/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/CF83739C-D944-48E1-AFB5-07073C8DCAC2",
        "udid" : "CF83739C-D944-48E1-AFB5-07073C8DCAC2",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Air-5th-generation",
        "state" : "Shutdown",
        "name" : "iPad Air (5th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/BEC5AFEA-6562-4D9E-9857-47263D07E569/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/BEC5AFEA-6562-4D9E-9857-47263D07E569",
        "udid" : "BEC5AFEA-6562-4D9E-9857-47263D07E569",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-10th-generation",
        "state" : "Shutdown",
        "name" : "iPad (10th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/2C37B70A-EB76-47D8-B841-D138678FC7C1/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/2C37B70A-EB76-47D8-B841-D138678FC7C1",
        "udid" : "2C37B70A-EB76-47D8-B841-D138678FC7C1",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-mini-6th-generation",
        "state" : "Shutdown",
        "name" : "iPad mini (6th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/E32AB474-9E57-4314-B592-34AF7E1C7600/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/E32AB474-9E57-4314-B592-34AF7E1C7600",
        "udid" : "E32AB474-9E57-4314-B592-34AF7E1C7600",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-4th-generation-8GB",
        "state" : "Shutdown",
        "name" : "iPad Pro (11-inch) (4th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/4D963F07-89FA-403C-B8FF-A20B73BB44E2/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/4D963F07-89FA-403C-B8FF-A20B73BB44E2",
        "udid" : "4D963F07-89FA-403C-B8FF-A20B73BB44E2",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-12-9-inch-6th-generation-8GB",
        "state" : "Shutdown",
        "name" : "iPad Pro (12.9-inch) (6th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/30C472B0-F757-47C3-B8BA-488A5335F477/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/30C472B0-F757-47C3-B8BA-488A5335F477",
        "udid" : "30C472B0-F757-47C3-B8BA-488A5335F477",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Air-11-inch-M2",
        "state" : "Shutdown",
        "name" : "iPad Air 11-inch (M2)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/3C022A04-08C8-43EF-99C4-5B63EAB24AD6/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/3C022A04-08C8-43EF-99C4-5B63EAB24AD6",
        "udid" : "3C022A04-08C8-43EF-99C4-5B63EAB24AD6",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Air-13-inch-M2",
        "state" : "Shutdown",
        "name" : "iPad Air 13-inch (M2)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/127B2862-F2FD-4683-A20D-027A7546A1B6/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/127B2862-F2FD-4683-A20D-027A7546A1B6",
        "udid" : "127B2862-F2FD-4683-A20D-027A7546A1B6",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4-8GB",
        "state" : "Shutdown",
        "name" : "iPad Pro 11-inch (M4)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/A5438F17-9924-482A-8561-AAFF95DDF9D0/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/A5438F17-9924-482A-8561-AAFF95DDF9D0",
        "udid" : "A5438F17-9924-482A-8561-AAFF95DDF9D0",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4-8GB",
        "state" : "Shutdown",
        "name" : "iPad Pro 13-inch (M4)"
      }
    ],
    "com.apple.CoreSimulator.SimRuntime.iOS-17-5" : [
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/5C6FB658-1608-46C6-970F-5CBF6DF27B64/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/5C6FB658-1608-46C6-970F-5CBF6DF27B64",
        "udid" : "5C6FB658-1608-46C6-970F-5CBF6DF27B64",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
        "state" : "Shutdown",
        "name" : "iPhone SE (3rd generation)"
      },
      {
        "lastBootedAt" : "2024-07-26T18:39:30Z",
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/5C29B0CE-58B0-4273-A0F5-2A826D0AB379/data",
        "dataPathSize" : 1961287680,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/5C29B0CE-58B0-4273-A0F5-2A826D0AB379",
        "udid" : "5C29B0CE-58B0-4273-A0F5-2A826D0AB379",
        "isAvailable" : true,
        "logPathSize" : 471040,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-14",
        "state" : "Shutdown",
        "name" : "iPhone 14"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/129AA2C7-CEFA-4D2C-B232-B5C362630413/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/129AA2C7-CEFA-4D2C-B232-B5C362630413",
        "udid" : "129AA2C7-CEFA-4D2C-B232-B5C362630413",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-15",
        "state" : "Shutdown",
        "name" : "iPhone 15"
      },
      {
        "lastBootedAt" : "2024-07-19T12:30:06Z",
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/D543D2FF-C13D-46A6-A9B2-8FCC67A12F91/data",
        "dataPathSize" : 1881100288,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/D543D2FF-C13D-46A6-A9B2-8FCC67A12F91",
        "udid" : "D543D2FF-C13D-46A6-A9B2-8FCC67A12F91",
        "isAvailable" : true,
        "logPathSize" : 339968,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Plus",
        "state" : "Shutdown",
        "name" : "iPhone 15 Plus"
      },
      {
        "lastBootedAt" : "2024-08-01T13:46:10Z",
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/D2E4C979-FFEA-4236-9F57-64C3209975A0/data",
        "dataPathSize" : 9479585792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/D2E4C979-FFEA-4236-9F57-64C3209975A0",
        "udid" : "D2E4C979-FFEA-4236-9F57-64C3209975A0",
        "isAvailable" : true,
        "logPathSize" : 905216,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro",
        "state" : "Booted",
        "name" : "iPhone 15 Pro"
      },
      {
        "lastBootedAt" : "2024-07-31T12:07:49Z",
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/B8B2B50F-FF8F-455B-A54F-390833E57264/data",
        "dataPathSize" : 2032107520,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/B8B2B50F-FF8F-455B-A54F-390833E57264",
        "udid" : "B8B2B50F-FF8F-455B-A54F-390833E57264",
        "isAvailable" : true,
        "logPathSize" : 552960,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max",
        "state" : "Shutdown",
        "name" : "iPhone 15 Pro Max"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/2B423E52-5257-4F0F-B425-1A1E6C9598DA/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/2B423E52-5257-4F0F-B425-1A1E6C9598DA",
        "udid" : "2B423E52-5257-4F0F-B425-1A1E6C9598DA",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-10th-generation",
        "state" : "Shutdown",
        "name" : "iPad (10th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/E17550A0-03AC-47F3-B326-6DA569FAA98B/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/E17550A0-03AC-47F3-B326-6DA569FAA98B",
        "udid" : "E17550A0-03AC-47F3-B326-6DA569FAA98B",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-mini-6th-generation",
        "state" : "Shutdown",
        "name" : "iPad mini (6th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/C2A6851E-BC9E-4201-8BDA-777D8AEC52D2/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/C2A6851E-BC9E-4201-8BDA-777D8AEC52D2",
        "udid" : "C2A6851E-BC9E-4201-8BDA-777D8AEC52D2",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Air-11-inch-M2",
        "state" : "Shutdown",
        "name" : "iPad Air 11-inch (M2)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/6DC0B15E-A6BE-448E-81B7-3C6D24D27714/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/6DC0B15E-A6BE-448E-81B7-3C6D24D27714",
        "udid" : "6DC0B15E-A6BE-448E-81B7-3C6D24D27714",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Air-13-inch-M2",
        "state" : "Shutdown",
        "name" : "iPad Air 13-inch (M2)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/33E74B19-44BC-4C41-BE58-57642C3D35E1/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/33E74B19-44BC-4C41-BE58-57642C3D35E1",
        "udid" : "33E74B19-44BC-4C41-BE58-57642C3D35E1",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4-8GB",
        "state" : "Shutdown",
        "name" : "iPad Pro 11-inch (M4)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/26FC2F7B-C7C8-45BF-8657-576A8A5673E4/data",
        "dataPathSize" : 18337792,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/26FC2F7B-C7C8-45BF-8657-576A8A5673E4",
        "udid" : "26FC2F7B-C7C8-45BF-8657-576A8A5673E4",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4-8GB",
        "state" : "Shutdown",
        "name" : "iPad Pro 13-inch (M4)"
      }
    ],
    "com.apple.CoreSimulator.SimRuntime.iOS-15-5" : [
      {
        "lastBootedAt" : "2024-04-05T06:49:33Z",
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/E0A0D2BA-20F4-44BD-B0FA-3AD40499A31E/data",
        "dataPathSize" : 375873536,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/E0A0D2BA-20F4-44BD-B0FA-3AD40499A31E",
        "udid" : "E0A0D2BA-20F4-44BD-B0FA-3AD40499A31E",
        "isAvailable" : true,
        "logPathSize" : 331776,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-8",
        "state" : "Shutdown",
        "name" : "iPhone 8"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/3A259DB0-3824-4AD1-B883-3250FF134CE3/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/3A259DB0-3824-4AD1-B883-3250FF134CE3",
        "udid" : "3A259DB0-3824-4AD1-B883-3250FF134CE3",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-13-Pro",
        "state" : "Shutdown",
        "name" : "iPhone 13 Pro"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/AE599CE2-3222-4C8B-8B19-262898B84C10/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/AE599CE2-3222-4C8B-8B19-262898B84C10",
        "udid" : "AE599CE2-3222-4C8B-8B19-262898B84C10",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-13-Pro-Max",
        "state" : "Shutdown",
        "name" : "iPhone 13 Pro Max"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/1F194523-DCBC-44E3-A979-FAEF9A5A68F9/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/1F194523-DCBC-44E3-A979-FAEF9A5A68F9",
        "udid" : "1F194523-DCBC-44E3-A979-FAEF9A5A68F9",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-13-mini",
        "state" : "Shutdown",
        "name" : "iPhone 13 mini"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/681A36E6-FC7E-498A-B7E8-7D99C3F13084/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/681A36E6-FC7E-498A-B7E8-7D99C3F13084",
        "udid" : "681A36E6-FC7E-498A-B7E8-7D99C3F13084",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-13",
        "state" : "Shutdown",
        "name" : "iPhone 13"
      },
      {
        "lastBootedAt" : "2024-04-26T18:23:13Z",
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/B57F80B6-D50B-4EF2-B68B-2CFFCF585282/data",
        "dataPathSize" : 2656182272,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/B57F80B6-D50B-4EF2-B68B-2CFFCF585282",
        "udid" : "B57F80B6-D50B-4EF2-B68B-2CFFCF585282",
        "isAvailable" : true,
        "logPathSize" : 389120,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
        "state" : "Shutdown",
        "name" : "iPhone SE (3rd generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/7DBA932C-1A6E-4AD7-A01F-6C6F4961D6DA/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/7DBA932C-1A6E-4AD7-A01F-6C6F4961D6DA",
        "udid" : "7DBA932C-1A6E-4AD7-A01F-6C6F4961D6DA",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPod-touch--7th-generation-",
        "state" : "Shutdown",
        "name" : "iPod touch (7th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/8A8636CE-7164-4D15-9501-B8B459ADCE21/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/8A8636CE-7164-4D15-9501-B8B459ADCE21",
        "udid" : "8A8636CE-7164-4D15-9501-B8B459ADCE21",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro--9-7-inch-",
        "state" : "Shutdown",
        "name" : "iPad Pro (9.7-inch)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/86946061-8D99-4A8F-A1D0-B94C87BF8BEF/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/86946061-8D99-4A8F-A1D0-B94C87BF8BEF",
        "udid" : "86946061-8D99-4A8F-A1D0-B94C87BF8BEF",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-9th-generation",
        "state" : "Shutdown",
        "name" : "iPad (9th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/71921F86-A782-467B-ACFC-3D29E9097ECD/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/71921F86-A782-467B-ACFC-3D29E9097ECD",
        "udid" : "71921F86-A782-467B-ACFC-3D29E9097ECD",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-3rd-generation",
        "state" : "Shutdown",
        "name" : "iPad Pro (11-inch) (3rd generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/EAF96D88-4BC6-47E8-B616-1BF8A441310A/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/EAF96D88-4BC6-47E8-B616-1BF8A441310A",
        "udid" : "EAF96D88-4BC6-47E8-B616-1BF8A441310A",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-12-9-inch-5th-generation",
        "state" : "Shutdown",
        "name" : "iPad Pro (12.9-inch) (5th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/1E5659E6-3A11-4810-AC40-EEA59A342326/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/1E5659E6-3A11-4810-AC40-EEA59A342326",
        "udid" : "1E5659E6-3A11-4810-AC40-EEA59A342326",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Air-5th-generation",
        "state" : "Shutdown",
        "name" : "iPad Air (5th generation)"
      },
      {
        "dataPath" : "/Users/adf/Library/Developer/CoreSimulator/Devices/341F7BFE-1FAF-4585-8F5D-AE837B94F827/data",
        "dataPathSize" : 18341888,
        "logPath" : "/Users/adf/Library/Logs/CoreSimulator/341F7BFE-1FAF-4585-8F5D-AE837B94F827",
        "udid" : "341F7BFE-1FAF-4585-8F5D-AE837B94F827",
        "isAvailable" : true,
        "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-mini-6th-generation",
        "state" : "Shutdown",
        "name" : "iPad mini (6th generation)"
      }
    ]
  }
}
""".data(using: .utf8)

    private var mockCLIOutputPairs = """
{
  "pairs" : {
    "45C7FED8-A851-4106-9336-CC62E0EF4FB8" : {
      "watch" : {
        "name" : "Apple Watch Series 9",
        "udid" : "6DA9E3A5-5F65-4901-BA45-F364209C0105",
        "state" : "Shutdown"
      },
      "phone" : {
        "name" : "iPhone 15 Pro Watch",
        "udid" : "1EBBF0F7-7994-4CE4-9447-0770E3320D53",
        "state" : "Shutdown"
      },
      "state" : "(active, disconnected)"
    },
    "BC288B6B-437C-40F0-B80A-B66B20B0DB9B" : {
      "watch" : {
        "name" : "Apple Watch Series 9 (41mm)",
        "udid" : "27E15B91-E665-44BC-B688-2A1B5AC1AB41",
        "state" : "Shutdown"
      },
      "phone" : {
        "name" : "iPhone 15 Plus",
        "udid" : "D543D2FF-C13D-46A6-A9B2-8FCC67A12F91",
        "state" : "Shutdown"
      },
      "state" : "(active, disconnected)"
    },
    "6F8B1B06-7CE5-4695-9DB9-DD11CF92FB03" : {
      "watch" : {
        "name" : "Apple Watch Series 9 (45mm)",
        "udid" : "B57C9502-85DE-4C9D-B3C0-8F8FFEC50BCB",
        "state" : "Shutdown"
      },
      "phone" : {
        "name" : "iPhone 15 Pro",
        "udid" : "D2E4C979-FFEA-4236-9F57-64C3209975A0",
        "state" : "Booted"
      },
      "state" : "(active, disconnected)"
    },
    "1AFEDB11-2EE6-4427-90E7-C942E6596AB9" : {
      "watch" : {
        "name" : "Apple Watch Series 7 (45mm)",
        "udid" : "02B89F79-3D8C-4B8A-B169-3BC112B568DC",
        "state" : "Shutdown"
      },
      "phone" : {
        "name" : "iPhone 15",
        "udid" : "129AA2C7-CEFA-4D2C-B232-B5C362630413",
        "state" : "Shutdown"
      },
      "state" : "(active, disconnected)"
    },
    "9749A771-B98C-4526-ADA6-CE529A8261C3" : {
      "watch" : {
        "name" : "Apple Watch Ultra 2 (49mm)",
        "udid" : "62032428-77CA-4880-8BF3-262BCF3BFA1C",
        "state" : "Shutdown"
      },
      "phone" : {
        "name" : "iPhone 15 Pro Max",
        "udid" : "B8B2B50F-FF8F-455B-A54F-390833E57264",
        "state" : "Shutdown"
      },
      "state" : "(active, disconnected)"
    }
  }
}

""".data(using: .utf8)
}
