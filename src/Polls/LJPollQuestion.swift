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
	
	var memento: [String: Any] {
		return [String: Any]()
	}
	
	@objc(restoreFromMemento:) func restore(fromMemento amemento: [String: Any]) {
		
	}
	
	/// Get the HTML representation
	var htmlRepresentation: String {
		return ""
	}
	
	// MARK: NSCoding
	final class var supportsSecureCoding: Bool {
		return true
	}
	
	required init?(coder aDecoder: NSCoder) {
		if let aQues = aDecoder.decodeObject(forKey: kLJPollQuestionKey) as? String {
			question = aQues
			super.init()
		} else {
			return nil
		}
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(question, forKey: kLJPollQuestionKey)
	}
}

extension PollQuestion {
	
	@available(*, unavailable, renamed: "restore(fromMemento:)")
	@nonobjc func restoreFromMemento(_ amemento: [String: AnyObject]) {
	
	}
}
