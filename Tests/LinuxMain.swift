//
//  LinuxMain.swift
//
//  Created by Alex da Franca on 26.12.21.
//

import findsimulatorTests
import XCTest

var tests = [XCTestCaseEntry]()
tests += findsimulatorTests.allTests()
XCTMain(tests)
