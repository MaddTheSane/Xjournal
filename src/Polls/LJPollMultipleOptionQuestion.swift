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
@objc(LJPollMultipleOptionQuestion) final class PollMultipleOptionQuestion: PollQuestion {
	
	@objc(LJPollMultipleOption) enum MultipleOption: Int {
		case radio = 1
		case checkBox = 2
		case dropDown = 3
		
		fileprivate var stringRepresentation: String {
			switch self {
			case .radio:
				return "radio"
				
			case .checkBox:
				return "check"
				
			case .dropDown:
				return "drop"
			}
		}
	}
	
	private var answers = [String]()
	
	var type: MultipleOption
	
	/// Returns a multiple-option radio question type with
	/// a default question
	convenience override init() {
		self.init(type: .radio)
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
	@objc(addAnswer:) func add(answer: String) {
		answers.append(answer)
	}
	
	/// Insert the question at the given index
	@objc(insertAnswer:atIndex:) func insert(answer: String, at idx: Int) {
		answers.insert(answer, at: idx)
	}
	
	/// Returns the answer at idx
	@objc(answerAtIndex:) func answer(at idx: Int) -> String {
		return answers[idx]
	}
	
	/// Modifies the answer at idx to reflect the given string
	@objc(setAnswer:atIndex:) func set(answer: String, at idx: Int) {
		answers[idx] = answer
	}
	
	/// Removes the answer at idx from the question
	@objc(deleteAnswerAtIndex:) func deleteAnswer(at idx: Int) {
		answers.remove(at: idx)
	}
	
	/// Removes answers at idx from the question
	@objc(deleteAnswersAtIndexes:) func deleteAnswers(at idx: IndexSet) {
		answers.remove(indexes: idx)
	}
	
	/// Deletes all the answers
	func deleteAllAnswers() {
		answers.removeAll(keepingCapacity: false)
	}
	
	/// Moves the answer at oldIdx to newIdx
	@objc(moveAnswerAtIndex:toIndex:)
	func moveAnswer(at idx: Int, to newIdx: Int) {
		if newIdx == idx {
			return
		}
		if (newIdx < 0 || newIdx >= answers.count) {
			return
		}
		
		let obj = answers[idx]
		answers.remove(at: idx)
		answers.insert(obj, at: newIdx)
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
	override var memento: [String: Any] {
		let dict: [String: Any] = [kLJPollQuestionKey: question,
			kMultipleOptionType: type.rawValue,
			kMultipleOptionAnswerArray: answers]
		
		return dict
	}
	
	override func restore(fromMemento amemento: [String: Any]) {
		question = memento[kLJPollQuestionKey] as! String
		type = MultipleOption(rawValue: memento[kMultipleOptionType] as! Int) ?? .radio
		
		deleteAllAnswers()
		
		for object in memento[kMultipleOptionAnswerArray] as! [String] {
			add(answer: object)
		}
	}
	
	// MARK: - NSCoding
	required init?(coder aDecoder: NSCoder) {
		if let anAns = aDecoder.decodeObject(forKey: kMultipleOptionAnswerArray) as? [String],
			let aType = MultipleOption(rawValue: aDecoder.decodeInteger(forKey: kMultipleOptionType)) {
				answers = anAns
				type = aType
				super.init(coder: aDecoder)
		} else {
			return nil
		}
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(answers, forKey: kMultipleOptionAnswerArray)
		aCoder.encode(type.rawValue, forKey: kMultipleOptionType)
	}
	
	// MARK: -
	class var keyPathsForValuesAffectingHtmlRepresentation: Set<String> {
		return Set(["answers", "type", "question"])
	}
}

extension PollMultipleOptionQuestion {
	/// Adds an answer to this question
	@available(*, unavailable, renamed: "add(answer:)")
	@nonobjc func addAnswer(_ answer: String) {
	}
	
	/// Insert the question at the given index
	@available(*, unavailable, renamed: "insert(answer:at:)")
	@nonobjc func insertAnswer(_ answer: String, atIndex idx: Int) {
	}
	
	/// Returns the answer at idx
	@available(*, unavailable, renamed: "answer(at:)")
	@nonobjc func answerAtIndex(_ idx: Int) -> String {
		return ""
	}
	
	/// Modifies the answer at idx to reflect the given string
	@available(*, unavailable, renamed: "set(answer:at:)")
	@nonobjc func setAnswer(_ answer: String, atIndex idx: Int) {
	}
	
	/// Removes the answer at idx from the question
	@available(*, unavailable, renamed: "deleteAnswer(at:)")
	@nonobjc func deleteAnswerAtIndex(_ idx: Int) {
	}
	
	/// Removes answers at idx from the question
	@available(*, unavailable, renamed: "deleteAnswers(at:)")
	@nonobjc func deleteAnswersAtIndexes(_ idx: NSIndexSet) {
	}
	
	/// Moves the answer at oldIdx to newIdx
	@available(*, unavailable, renamed: "moveAnswer(at:to:)")
	@nonobjc func moveAnswerAtIndex(_ idx: Int, toIndex newIdx: Int) {
	}	
}
