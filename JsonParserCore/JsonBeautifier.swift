//
//  JsonBeautifier.swift
//  JsonParserCore
//
//  Created by Yasin Akbas on 1.01.2025.
//

import Foundation

class JsonBeautifier {
    init() {}
    
    public func beautifyJSON(_ json: String) -> String? {
        guard let jsonData = json.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let beautifiedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
              let beautifiedJSON = String(data: beautifiedData, encoding: .utf8) else {
            return nil
        }
        return beautifiedJSON
    }
}
