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

/**
Question subclass representing a scale with start, end and step values
*/
@objc(LJPollScaleQuestion) final class PollScaleQuestion: LJPollQuestion, NSCoding {
	var start: Int
	var end: Int
	var step: Int
	
	/// Returns a scale question with the given start, end and step values
	/// and a default question string
	init(start aStart: Int, end anEnd: Int, step aStep: Int) {
		start = aStart
		end = anEnd
		step = aStep
		
		super.init()
	}
	
	convenience init(range: Range<Int>, step aStep: Int) {
		self.init(start: range.startIndex, end: range.endIndex, step: aStep)
	}
	
	convenience init(range: NSRange, step aStep: Int) {
		self.init(start: range.location, end: range.max, step: aStep)
	}
	
	convenience override init() {
		self.init(start: 1, end: 100, step: 10)
	}
	
	override var htmlRepresentation: String {
		return "<lj-pq type=\"scale\" from=\"\(start)\" to=\"\(end)\" by=\"\(step)\">\(question)</lj-pq>"
	}
	
	//MARK: - memento
	override var memento: [String: AnyObject] {
		return [kLJPollQuestionKey: question,
			kPollScaleStart: start,
			kPollScaleEnd: end,
			kPollScaleStep: step]
	}
	
	override func restoreFromMemento(amemento: [String: AnyObject]) {
		question = amemento[question] as String
		start = amemento[kPollScaleStart] as Int
		end = amemento[kPollScaleEnd] as Int
		step = amemento[kPollScaleStep] as Int
	}
	
	//MARK: - NSCoding
	override func encodeWithCoder(aCoder: NSCoder) {
		super.encodeWithCoder(aCoder)
		
		aCoder.encodeInteger(start, forKey: kPollScaleStart)
		aCoder.encodeInteger(end, forKey: kPollScaleEnd)
		aCoder.encodeInteger(step, forKey: kPollScaleStep)
	}
	
	required init(coder aDecoder: NSCoder) {
		start = aDecoder.decodeIntegerForKey(kPollScaleStart)
		end = aDecoder.decodeIntegerForKey(kPollScaleEnd)
		step = aDecoder.decodeIntegerForKey(kPollScaleStep)
		
		super.init(coder: aDecoder)
	}
}
