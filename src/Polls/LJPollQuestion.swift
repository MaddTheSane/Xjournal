//
//  LJPollQuestion.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/23/15.
//
//

import Foundation

let kLJPollQuestionKey = "LJPollQuestion"


class PollQuestion: NSObject, NSSecureCoding {
	
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
		question = aDecoder.decodeObjectForKey(kLJPollQuestionKey) as? String ?? "Question"
		super.init()
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(question, forKey: kLJPollQuestionKey)
	}
}
