//
//  LJPollMultipleOptionQuestion.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/23/15.
//
//

import Foundation
import SwiftAdditions

private let kMultipleOptionType = "LJMultipleOptionType"
private let kMultipleOptionAnswerArray = "LJMultipleOptionAnswerArray"

///This subclass encapsulates the Radio, Checkbox and Drop-down question types.
@objc(LJPollMultipleOptionQuestion) final class PollMultipleOptionQuestion: PollQuestion, NSCoding {
	
	enum MultipleOption: Int {
		case Radio = 1
		case CheckBox = 2
		case DropDown = 3
		
		private var stringRepresentation: String {
			switch self {
			case .Radio:
				return "radio"
				
			case .CheckBox:
				return "check"
				
			case .DropDown:
				return "drop"
			}
		}
	}
	
	private var answers = [String]()
	
	var type: MultipleOption
	
	/// Returns a multiple-option radio question type with
	/// a default question
	convenience override init() {
		self.init(type: .Radio)
	}
	
	/// Returns a multiple-option question of the given type with
	/// a default question
	init(type: MultipleOption) {
		self.type = type
		super.init()
	}
	
	/// Returns the number of answers to this question
	var numberOfAnswers: Int {
		return answers.count
	}
	
	/// Adds an answer to this question
	func addAnswer(answer: String) {
		answers.append(answer)
	}
	
	/// Insert the question at the given index
	func insertAnswer(answer: String, atIndex idx: Int) {
		answers.insert(answer, atIndex: idx)
	}
	
	/// Returns the answer at idx
	func answerAtIndex(idx: Int) -> String {
		return answers[idx]
	}
	
	/// Modifies the answer at idx to reflect the given string
	func setAnswer(answer: String, atIndex idx: Int) {
		answers[idx] = answer
	}
	
	/// Removes the answer at idx from the question
	func deleteAnswerAtIndex(idx: Int) {
		answers.removeAtIndex(idx)
	}
	
	/// Removes answers at idx from the question
	func deleteAnswersAtIndexes(idx: NSIndexSet) {
		removeObjects(inArray: &answers, atIndexes: idx)
	}
	
	/// Deletes all the answers
	func deleteAllAnswers() {
		answers.removeAll(keepCapacity: false)
	}
	
	/// Moves the answer at oldIdx to newIdx
	func moveAnswerAtIndex(idx: Int, toIndex newIdx: Int) {
		if newIdx == idx {
			return
		}
		if (newIdx < 0 || newIdx >= answers.count) {
			return
		}
		
		let obj = answers[idx]
		answers.removeAtIndex(idx)
		answers.insert(obj, atIndex: newIdx)
	}

	/// Get the HTML representation
	override var htmlRepresentation: String {
		var buf = "<lj-pq type=\"\(type.stringRepresentation)\">\n"
		buf += question + "\n"
		
		for ans in answers {
			buf += "<lj-pi>\(ans)</lj-pi>\n"
		}
		buf += "</lj-pq>"
		
		return buf
	}

	// MARK: - Memento
	override var memento: [String: AnyObject] {
		let dict: [String: AnyObject] = [kLJPollQuestionKey: question,
			kMultipleOptionType: type.rawValue,
			kMultipleOptionAnswerArray: answers]
		
		return dict
	}
	
	override func restoreFromMemento(amemento: [String: AnyObject]) {
		question = memento[kLJPollQuestionKey] as! String
		type = MultipleOption(rawValue: memento[kMultipleOptionType] as! Int) ?? .Radio
		
		deleteAllAnswers()
		
		for object in memento[kMultipleOptionAnswerArray] as! [String] {
			addAnswer(object)
		}
	}
	
	// MARK: - NSCoding
	required init(coder aDecoder: NSCoder) {
		answers = aDecoder.decodeObjectForKey(kMultipleOptionAnswerArray) as? [String] ?? []
		type = MultipleOption(rawValue: aDecoder.decodeIntegerForKey(kMultipleOptionType)) ?? .Radio
		
		super.init(coder: aDecoder)
	}
	
	override func encodeWithCoder(aCoder: NSCoder) {
		super.encodeWithCoder(aCoder)
		aCoder.encodeObject(answers, forKey: kMultipleOptionAnswerArray)
		aCoder.encodeInteger(type.rawValue, forKey: kMultipleOptionType)
	}
	
	// MARK: -
	class var keyPathsForValuesAffectingHtmlRepresentation: NSSet {
		return NSSet(objects: "answers", "type", "question")
	}
}
