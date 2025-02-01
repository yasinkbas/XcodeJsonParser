//
//  JsonParserCommand.swift
//  JsonParser
//
//  Created by Yasin Akbas on 1.02.2025.
//

import Foundation
import XcodeKit
import JsonParserCore

class JsonParserCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        let content = invocation.buffer.completeBuffer
        let parser = JsonParserFacade()
        
        guard let result = parser.parseAndGenerateSwiftModel(from: content, rootName: "RootModel") else {
            completionHandler(nil)
            return
        }
        
        invocation.buffer.completeBuffer = result
        completionHandler(nil)
    }
}
