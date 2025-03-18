//
//  JsonParserFacade.swift
//  JsonParserCore
//
//  Created by Yasin Akbas on 1.01.2025.
//

import Foundation

public class JsonParserFacade {
  private let extractor = JsonExtractor()
  private let beautifier = JsonBeautifier()
  private let generator = ModelGenerator()
  
  public init() {}
  
  public func parseAndGenerateSwiftModel(from content: String, rootName: String) -> String? {
    let (jsonString, nonJsonContent) = extractor.extractJSON(from: content)
    
    guard let jsonString = jsonString else {
      print("🛑 No JSON detected.")
      return nil
    }
    
    guard let beautifiedJSON = beautifier.beautifyJSON(jsonString) else {
      print("🛑 JSON beautification failed.")
      return nil
    }
    
    print("✅ Beautified JSON:\n\(beautifiedJSON)")
    
    guard let jsonData = beautifiedJSON.data(using: .utf8) else {
      print("🛑 JSON data conversion failed.")
      return nil
    }
    let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: [.fragmentsAllowed, .mutableContainers])
    
    guard var dict = jsonObject as? [String: Any] else {
      print("🛑 JSON parsing returned unexpected type: \(type(of: jsonObject))")
      return nil
    }
    
    dict = fixBooleanTypes(in: dict, originalJson: beautifiedJSON)  // ensure booleans remain booleans due to objc/swift parsing issue
    let generatedModel = generator.generate(from: dict, rootName: rootName)
    
    // reconstruct the file with original non json content
    let finalOutput = nonJsonContent + generatedModel
    return finalOutput
  }
  
  private func fixBooleanTypes(in dictionary: [String: Any], originalJson: String) -> [String: Any] {
    var fixedDict = dictionary
    
    for (key, value) in fixedDict {
      let keyPattern = "\"\(key)\"\\s*:\\s*(true|false|[0-9]+)"  // looking for key and value
      if let match = originalJson.range(of: keyPattern, options: .regularExpression) {
        let rawValue = String(originalJson[match]).components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
        
        if let rawValue = rawValue, rawValue == "true" || rawValue == "false" {
          fixedDict[key] = (rawValue == "true")
        }
      }
      
      // recursivly fix nested dicts
      if let nestedDict = value as? [String: Any] {
        fixedDict[key] = fixBooleanTypes(in: nestedDict, originalJson: originalJson)
      } else if let nestedArray = value as? [[String: Any]] {
        fixedDict[key] = nestedArray.map { fixBooleanTypes(in: $0, originalJson: originalJson) }
      }
    }
    
    return fixedDict
  }
}
