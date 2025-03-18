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
    var existingKeys = [String: Bool]()
    
    if let dict = jsonObject as? [String: Any] {
      _ = processObject(dict, name: rootName, existingKeys: &existingKeys)
    } else if let array = jsonObject as? [[String: Any]] {
      var combinedKeys = [String: Bool]()
      
      for item in array {
        for key in item.keys {
          combinedKeys[key] = combinedKeys[key] ?? true
        }
        
        for key in combinedKeys.keys {
          if item[key] == nil {
            combinedKeys[key] = false
          }
        }
      }
      
      _ = processObject(array.first ?? [:], name: rootName, existingKeys: &combinedKeys)
    }
    
    let sortedStructs = topologicalSort()
    return rootStruct + "\n" + sortedStructs.joined(separator: "\n")
  }
  
  private func processObject(_ object: [String: Any], name: String, existingKeys: inout [String: Bool]) -> String {
    let structName = name.prefix(1).uppercased() + name.dropFirst()
    if structDefinitions[structName] != nil { return structName }
    
    var structString = "struct \(structName): Decodable {\n"
    var referencedStructs = Set<String>()
    
    for (key, value) in object {
      let propertyName = key.prefix(1).lowercased() + key.dropFirst()
      
      let isOptional = existingKeys[key] == false
      let type = processValue(value, key: key.capitalized, isOptional: isOptional, existingKeys: &existingKeys)
      
      structString += "    let \(propertyName): \(type)\n"
      
      if !["String", "Int", "Double", "Bool", "[Any]?"].contains(type) {
        referencedStructs.insert(type)
      }
      
      existingKeys[key] = true
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
  
  private func processValue(_ value: Any, key: String, isOptional: Bool = false, existingKeys: inout [String: Bool]) -> String {
    let optionalSuffix = isOptional ? "?" : ""
    
    switch value {
    case is String: return "String" + optionalSuffix
    case is Int: return "Int" + optionalSuffix
    case is Double, is Float: return "Double" + optionalSuffix
    case is Bool: return "Bool" + optionalSuffix
    case let array as [[String: Any]]:
      var combinedKeys = [String: Bool]()
      
      for item in array {
        for key in item.keys {
          combinedKeys[key] = combinedKeys[key] ?? true
        }
        
        for key in combinedKeys.keys where item[key] == nil {
          combinedKeys[key] = false
        }
      }
      
      let elementType = processObject(array.first ?? [:], name: key, existingKeys: &combinedKeys)
      return "[\(elementType)]" + optionalSuffix
    case let dict as [String: Any]:
      return processObject(dict, name: key, existingKeys: &existingKeys)
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
