//
//  main.swift
//  xctwdiff
//
//  Created by Juri Pakaste on 24/06/2018.
//  Copyright © 2018 Juri Pakaste. All rights reserved.
//

import Foundation

class StandardErrorOutputStream: TextOutputStream {
    func write(_ string: String) {
        let stderr = FileHandle.standardError
        stderr.write(string.data(using: String.Encoding.utf8)!)
    }
}

var stderr = StandardErrorOutputStream()

func readAllInput() -> String {
    guard let firstLine = readLine(strippingNewline: true) else { return "" }
    let inputLines = sequence(first: firstLine) { _ in
        readLine(strippingNewline: true)
    }
    return inputLines.joined()
}

func withTemporaryDirectory(_ block: (URL) throws -> Void) throws {
    let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
    func cleanUp() throws {
        try FileManager.default.removeItem(at: directoryURL)
    }
    do {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        try block(directoryURL)
        try cleanUp()
    } catch {
        try cleanUp()
        throw error
    }
}

struct EqualityParts {
    let input: String
    let expected: String
}

func splitFailure(_ failure: String) -> EqualityParts? {
    let prefix = "XCTAssertEqual failed: (\""
    let middle = "\") is not equal to (\""
    let suffix = "\") - "

    guard failure.hasPrefix(prefix) else {
        print("Wrong failure format: expected prefix not found", to: &stderr)
        return nil
    }

    guard failure.contains(middle) else {
        print("Wrong failure format: expected middle not found", to: &stderr)
        return nil
    }

    guard failure.hasSuffix(suffix) else {
        print("Wrong failure format: expected suffix not found", to: &stderr)
        return nil
    }

    let sansPrefix = failure.dropFirst(prefix.count)
    let sansSuffix = sansPrefix.dropLast(suffix.count)
    let components = sansSuffix.components(separatedBy: middle)
    guard components.count == 2 else {
        print("Found \(components.count) components when split, expected 2", to: &stderr)
        return nil
    }

    return EqualityParts(input: components[0], expected: components[1])
}

struct DataEncodingError: Error {}

func createFiles(for parts: EqualityParts, in directory: URL) throws -> (URL, URL) {
    let inputFile = directory.appendingPathComponent("input", isDirectory: false)
    let expectedFile = directory.appendingPathComponent("expected", isDirectory: false)

    guard let inputData = parts.input.data(using: .utf8) else {
        print("Failed to encode data as UTF-8", to: &stderr)
        throw DataEncodingError()
    }

    guard let expectedData = parts.expected.data(using: .utf8) else {
        print("Failed to encode data as UTF-8", to: &stderr)
        throw DataEncodingError()
    }

    try inputData.write(to: inputFile)
    try expectedData.write(to: expectedFile)

    return (inputFile, expectedFile)
}

@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

func diffParts(_ parts: EqualityParts) throws {
    try withTemporaryDirectory { directory in
        let files = try createFiles(for: parts, in: directory)
        shell("/bin/sh", "-c", "wdiff '\(files.0.path)' '\(files.1.path)' | colordiff")
    }
}

func run() throws {
    let input = readAllInput()
    guard let parts = splitFailure(input) else {
        print("Failed to read input", to: &stderr)
        return
    }
    try diffParts(parts)
}

try run()

