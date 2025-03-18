//
//  JsonExtractor.swift
//  JsonParserCore
//
//  Created by Yasin Akbas on 1.01.2025.
//

import Foundation

class JsonExtractor {
  init() {}
  
  public func extractJSON(from content: String) -> (json: String?, nonJson: String) {
    guard let jsonRange = findJSONRange(in: content) else {
      print("🛑 No JSON found")
      return (nil, content) // returns original content if no json found
    }
    
    let jsonString = String(content[jsonRange])
    let beforeJSON = content[..<jsonRange.lowerBound]
    let afterJSON = content[jsonRange.upperBound...]
    
    return (jsonString, String(beforeJSON) + afterJSON)
  }
  
  private func findJSONRange(in text: String) -> Range<String.Index>? {
    guard let firstBrace = text.firstIndex(where: { $0 == "{" || $0 == "[" }),
          let lastBrace = text.lastIndex(where: { $0 == "}" || $0 == "]" }) else {
      return nil
    }
    return firstBrace..<text.index(after: lastBrace)
  }
}
