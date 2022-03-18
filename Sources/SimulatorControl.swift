//
//  SimulatorControl.swift
//  findsimulator
//
//  Created by Alex da Franca on 23.06.21.
//

import Foundation

struct SimulatorControl {
    private let decoder = JSONDecoder()
    
    func simulatorId(pattern: String) -> Result<ListResult, Error> {
        var arguments = ["simctl", "list", "devices", "-j"]
        if !pattern.isEmpty {
            arguments += [pattern]
        }
        return executeJSONTask(with: arguments)
    }
    func pairId() -> Result<PairResult, Error> {
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

private extension NSError {
    convenience init(message: String, status: Int = 1) {
        let domain = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? "com.farbflash"
        self.init(domain: "\(domain).error", code: status, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

struct ErrorResponse: Codable {
    let message: String
    let status: Int
}
