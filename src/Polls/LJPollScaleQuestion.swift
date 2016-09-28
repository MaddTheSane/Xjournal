//
//  LJPollScaleQuestion.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/24/15.
//
//

import Foundation
import SwiftAdditions

private let kPollScaleStart = "LJPollScaleStart"
private let kPollScaleEnd = "LJPollScaleEnd"
private let kPollScaleStep = "LJPollScaleStep"

/// Question subclass representing a scale with start, end and step values
@objc(LJPollScaleQuestion) final class PollScaleQuestion: PollQuestion {
	dynamic var start: Int
	dynamic var end: Int
	dynamic var step: Int
	
	/// Returns a scale question with the given start, end and step values
	/// and a default question string
	init(start aStart: Int, end anEnd: Int, step aStep: Int) {
		start = aStart
		end = anEnd
		step = aStep
		
		super.init()
	}
	
	/// Returns a scale question within the given range, step values
	/// and a default question string
	convenience init(range: Range<Int>, step aStep: Int) {
		self.init(start: range.lowerBound, end: range.upperBound, step: aStep)
	}
	
	/// Returns a scale question within the given range, step values
	/// and a default question string
	convenience init(range: NSRange, step aStep: Int) {
		self.init(start: range.location, end: range.max, step: aStep)
	}
	
	/// Returns a scale question with a start of 1, an end of 100, a step of 10,
	/// and a default question string
	convenience override init() {
		self.init(start: 1, end: 100, step: 10)
	}
	
	/// Get the HTML representation
	override var htmlRepresentation: String {
		return "<lj-pq type=\"scale\" from=\"\(start)\" to=\"\(end)\" by=\"\(step)\">\(question)</lj-pq>"
	}
	
	// MARK: - memento
	override var memento: [String: Any] {
		return [kLJPollQuestionKey: question,
			kPollScaleStart: start,
			kPollScaleEnd: end,
			kPollScaleStep: step]
	}
	
	override func restore(fromMemento amemento: [String: Any]) {
		question = amemento[question] as! String
		start = amemento[kPollScaleStart] as! Int
		end = amemento[kPollScaleEnd] as! Int
		step = amemento[kPollScaleStep] as! Int
	}
	
	// MARK: - NSCoding
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		
		aCoder.encode(start, forKey: kPollScaleStart)
		aCoder.encode(end, forKey: kPollScaleEnd)
		aCoder.encode(step, forKey: kPollScaleStep)
	}
	
	required init?(coder aDecoder: NSCoder) {
		start = aDecoder.decodeInteger(forKey: kPollScaleStart)
		end = aDecoder.decodeInteger(forKey: kPollScaleEnd)
		step = aDecoder.decodeInteger(forKey: kPollScaleStep)
		
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	
	class var keyPathsForValuesAffectingHtmlRepresentation: Set<String> {
		return Set(["start", "end", "step", "question"])
	}
}
