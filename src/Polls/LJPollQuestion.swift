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
	
	required init?(coder aDecoder: NSCoder) {
		if let aQues = aDecoder.decodeObjectForKey(kLJPollQuestionKey) as? String {
			question = aQues
			super.init()
		} else {
			question = ""
			super.init()
			return nil
		}
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(question, forKey: kLJPollQuestionKey)
	}
}
