//
//  LJPollQuestion.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/23/15.
//
//

import Cocoa

let kLJPollQuestionKey = "LJPollQuestion"


class LJPollQuestion: NSObject, NSSecureCoding {
	
	/// The question name
	var question: String
	
	override init() {
		question = "New Question"
		super.init()
	}
	
	var memento: [String: AnyObject] {
		return [String: AnyObject]()
	}
	
	func restoreFromMemento(amemento: [String: AnyObject]) {
		
	}
	
	/// Get the HTML representation
	var htmlRepresentation: String {
		return ""
	}
	
	// MARK: NSCoding
	final class func supportsSecureCoding() -> Bool {
		return true
	}
	
	required init(coder aDecoder: NSCoder) {
		question = aDecoder.decodeObjectForKey(kLJPollQuestionKey) as NSString
		super.init()
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(question, forKey: kLJPollQuestionKey)
	}
}
