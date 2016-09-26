//
//  LJPollTextEntryQuestion.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/24/15.
//
//

import Foundation

private let kPollTextSize = "LJPollTextSize"
private let kPollTextLength = "LJPollTextLength"

///This is a subclass representing a text box question
@objc(LJPollTextEntryQuestion) final class PollTextEntryQuestion: PollQuestion {
	/// Get and set the size property
	var size: Int
	/// Get and set the length
	var maxLength: Int
	
	/// Returns a text question with the given size and length
	/// and a default question
	init(size theSize: Int, maxLength theLength: Int) {
		size = theSize
		maxLength = theLength
		
		super.init()
		question = "New Text Question"
	}
	
	/// Returns a text question a size of 10, a length of 10,
	/// and a default question
	override convenience init() {
		self.init(size: 10, maxLength: 10)
	}
	
	/// Get the HTML representation
	override var htmlRepresentation: String {
		return "<lj-pq type=\"text\" size=\"\(size)\" maxlength=\"\(maxLength)\">\(question)</lj-pq>"
	}
	
	// MARK: - memento
	override var memento: [String: Any] {
		return [kLJPollQuestionKey: question,
			kPollTextSize: size,
			kPollTextLength: maxLength]
	}
	
	override func restore(fromMemento amemento: [String: Any]) {
		question = amemento[question] as! String
		size = amemento[kPollTextSize] as! Int
		maxLength = amemento[kPollTextLength] as! Int
	}

	// MARK: - NSCoding
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(size, forKey: kPollTextSize)
		aCoder.encode(maxLength, forKey: kPollTextLength)
	}
	
	required init?(coder aDecoder: NSCoder) {
		size = aDecoder.decodeInteger(forKey: kPollTextSize)
		maxLength = aDecoder.decodeInteger(forKey: kPollTextLength)
		
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	class var keyPathsForValuesAffectingHtmlRepresentation: Set<String> {
		return Set(["size", "maxLength", "question"])
	}
}
