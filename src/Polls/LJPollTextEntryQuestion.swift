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
@objc(LJPollTextEntryQuestion) final class PollTextEntryQuestion: PollQuestion, NSCoding {
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
	override var memento: [String: AnyObject] {
		return [kLJPollQuestionKey: question,
			kPollTextSize: size,
			kPollTextLength: maxLength]
	}
	
	override func restoreFromMemento(amemento: [String: AnyObject]) {
		question = amemento[question] as! String
		size = amemento[kPollTextSize] as! Int
		maxLength = amemento[kPollTextLength] as! Int
	}

	// MARK: - NSCoding
	override func encodeWithCoder(aCoder: NSCoder) {
		super.encodeWithCoder(aCoder)
		aCoder.encodeInteger(size, forKey: kPollTextSize)
		aCoder.encodeInteger(maxLength, forKey: kPollTextLength)
	}
	
	required init(coder aDecoder: NSCoder) {
		size = aDecoder.decodeIntegerForKey(kPollTextSize)
		maxLength = aDecoder.decodeIntegerForKey(kPollTextLength)
		
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	class var keyPathsForValuesAffectingHtmlRepresentation: NSSet {
		return NSSet(objects: "size", "maxLength", "question")
	}
}
