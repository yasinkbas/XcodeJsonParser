//
//  SourceEditorCommand.swift
//  JsonParser
//
//  Created by Yasin Akbas on 1.02.2025.
//

import Foundation
import XcodeKit

class JsonParserCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        completionHandler(nil)
    }
    
}
