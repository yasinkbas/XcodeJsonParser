//
//  ModelGenerator.swift
//  JsonParserCore
//
//  Created by Yasin Akbas on 1.01.2025.
//

import Foundation

class ModelGenerator {
    private var structDefinitions = [String: String]()
    private var dependencies = [String: Set<String>]()
    private var rootStruct = ""

    init() {}

    public func generate(from jsonObject: Any, rootName: String) -> String {
        if let dict = jsonObject as? [String: Any] {
            _ = processObject(dict, name: rootName)
        } else if let array = jsonObject as? [[String: Any]], let firstItem = array.first {
            _ = processObject(firstItem, name: rootName)
        }

        let sortedStructs = topologicalSort()
        return rootStruct + "\n" + sortedStructs.joined(separator: "\n")
    }
    
    private func processObject(_ object: [String: Any], name: String, allObjects: [[String: Any]] = []) -> String {
        let structName = name.prefix(1).uppercased() + name.dropFirst()
        if structDefinitions[structName] != nil { return structName }

        var structString = "struct \(structName): Decodable {\n"
        var referencedStructs = Set<String>()

        let allKeys = allObjects.flatMap { $0.keys } + object.keys
        let uniqueKeys = Set(allKeys)

        for key in uniqueKeys {
            let propertyName = key.prefix(1).lowercased() + key.dropFirst()
            let isOptional = allObjects.contains { $0[key] == nil }
            
            let type = processValue(object[key] ?? NSNull(), key: key.capitalized, isOptional: isOptional)
            print("--> \(key) - \(object[key] ?? NSNull()) - \(isOptional) type: \(type)")
            structString += "    let \(propertyName): \(type)\n"

            if !["String", "Int", "Double", "Bool", "[Any]?"].contains(type) {
                referencedStructs.insert(type)
            }
        }

        structString += "}\n"

        if rootStruct.isEmpty {
            rootStruct = structString
        } else {
            structDefinitions[structName] = structString
        }
        dependencies[structName] = referencedStructs
        return structName
    }
    
    private func processValue(_ value: Any, key: String, isOptional: Bool = false) -> String {
        let optionalSuffix = isOptional ? "?" : ""

        switch value {
        case is String: return "String" + optionalSuffix
        case is Int: return "Int" + optionalSuffix
        case is Double, is Float: return "Double" + optionalSuffix
        case is Bool: return "Bool" + optionalSuffix
        case let array as [Any]:
            if let first = array.first {
                return "[\(processValue(first, key: key, isOptional: false))]" + optionalSuffix
            }
            return "[Any]?"
        case let dict as [String: Any]:
            return processObject(dict, name: key)
        case is NSNull:
            return "Any?"
        default:
            return "Any?"
        }
    }

    private func topologicalSort() -> [String] {
        var sorted = [String]()
        var visited = Set<String>()

        func visit(_ name: String) {
            if visited.contains(name) { return }
            visited.insert(name)
            dependencies[name]?.forEach { visit($0) }
            if let structDefinition = structDefinitions[name] {
                sorted.append(structDefinition)
            }
        }

        for structName in structDefinitions.keys.sorted(by: { dependencies[$0]?.count ?? 0 < dependencies[$1]?.count ?? 0 }) {
            visit(structName)
        }
        return sorted
    }
}
