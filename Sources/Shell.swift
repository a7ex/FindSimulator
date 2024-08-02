//
//  File.swift
//  
//
//  Created by Alex da Franca on 02.08.24.
//

import Foundation

protocol Shell {
    func execute(program: String, with arguments: [String]) -> Result<Data, Error>
}

struct ErrorResponse: Codable {
    let message: String
    let status: Int
}

struct ShellCommand: Shell {
    private let decoder = JSONDecoder()
    
    func execute(program: String, with arguments: [String]) -> Result<Data, Error> {
        #if os(macOS)
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
        #else
        return .failure(NSError(message: "Works only on MacOS", status: -17))
        #endif
    }
}

private extension NSError {
    convenience init(message: String, status: Int = 1) {
        let domain = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? "com.farbflash"
        self.init(domain: "\(domain).error", code: status, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
