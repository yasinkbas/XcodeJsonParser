//
//  JsonParserCoreTests.swift
//  JsonParserCoreTests
//
//  Created by Yasin Akbas on 1.02.2025.
//

import XCTest
@testable import JsonParserCore

final class JsonParserCoreTests: XCTestCase {
  var extractor: JsonExtractor!
  var beautifier: JsonBeautifier!
  var generator: ModelGenerator!
  var parser: JsonParserFacade!
  
  override func setUp() {
    super.setUp()
    extractor = JsonExtractor()
    beautifier = JsonBeautifier()
    generator = ModelGenerator()
    parser = JsonParserFacade()
  }
  
  override func tearDown() {
    extractor = nil
    beautifier = nil
    generator = nil
    parser = nil
    super.tearDown()
  }
  
  func testExtractJsonWithComments() {
    let input = """
        //  JsonBeautifier.swift
        //  JsonParserCore
        /* Multi-line comment */
        {
            "key": "value"
        }
        """
    
    let (json, nonJson) = extractor.extractJSON(from: input)
    
    XCTAssertEqual(json, """
        {
            "key": "value"
        }
        """)
    XCTAssertEqual(nonJson.trimmingCharacters(in: .whitespacesAndNewlines), """
        //  JsonBeautifier.swift
        //  JsonParserCore
        /* Multi-line comment */
        """.trimmingCharacters(in: .whitespacesAndNewlines))
  }
  
  func testExtractJsonWithoutJson() {
    let input = """
        // Just a comment
        Some text here.
        """
    
    let (json, nonJson) = extractor.extractJSON(from: input)
    
    XCTAssertNil(json)
    XCTAssertEqual(nonJson, input)
  }
  
  func testBeautifyValidJson() {
    let input = "{\"key\":\"value\"}"
    let expectedOutput = """
        {
          "key" : "value"
        }
        """
    
    XCTAssertEqual(beautifier.beautifyJSON(input), expectedOutput)
  }
  
  func testBeautifyInvalidJson() {
    let input = "{key: value}" // Invalid JSON
    XCTAssertNil(beautifier.beautifyJSON(input))
  }
  
  func testBoolAndIntHandling() {
    let input = """
        {
            "success": true,
            "message": null,
            "count": 5
        }
        """
    
    guard let beautified = beautifier.beautifyJSON(input),
          let jsonData = beautified.data(using: .utf8),
          let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
      XCTFail("JSON parsing failed")
      return
    }
    
    XCTAssertEqual(jsonObject["success"] as? Bool, true)
    XCTAssertTrue(jsonObject["message"] is NSNull)
    XCTAssertEqual(jsonObject["count"] as? Int, 5)
  }
  
  func testArrayWithOptionalProperties() {
    let input = """
        [
            { "title": "some", "content": "some"},
            { "title": "some"}
        ]
        """
    
    let model = generator.generate(from: try! JSONSerialization.jsonObject(with: input.data(using: .utf8)!, options: []), rootName: "RootModel")
    
    XCTAssertTrue(model.contains("let title: String"))
    XCTAssertTrue(model.contains("let content: String?"))
  }
  
  func testJsonParserFacadeFullFlow() {
    let input = """
        // Some comment
        {
            "success": true,
            "data": [
                { "id": 1, "name": "Test" },
                { "id": 2 }
            ]
        }
        """
    
    guard let result = parser.parseAndGenerateSwiftModel(from: input, rootName: "RootModel") else {
      XCTFail("Parser failed")
      return
    }
    
    XCTAssertTrue(result.contains("struct RootModel"))
    XCTAssertTrue(result.contains("let success: Bool"))
    XCTAssertTrue(result.contains("let name: String?"))
  }
  
  func testInvalidJsonInFacade() {
    let input = "This is not JSON"
    
    let result = parser.parseAndGenerateSwiftModel(from: input, rootName: "RootModel")
    XCTAssertNil(result)
  }
  
  func testJsonWithNullValues() {
    let input = """
        {
            "title": "Hello",
            "content": null
        }
        """
    
    let model = generator.generate(from: try! JSONSerialization.jsonObject(with: input.data(using: .utf8)!, options: []), rootName: "RootModel")
    
    XCTAssertTrue(model.contains("let content: Any?"))
  }
}
