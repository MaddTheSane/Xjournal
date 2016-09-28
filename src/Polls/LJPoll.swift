//
//  LJPoll.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/23/15.
//
//

import Foundation
import SwiftAdditions

private let pollNameKey = "Poll Name"
private let pollVotingKey = "Voting Permissions"
private let pollViewingKey = "Viewing Permissions"
private let pollQuestionsKey = "Poll Questions"

class LJPoll: NSObject, NSSecureCoding {
	public static var supportsSecureCoding: Bool {
		return true
	}

	private var questions = [PollQuestion]()
	/// Get and set the name of the poll
	var name = "NewPoll"
	
	/// Get and set the voting permissions, according to the enum `LJPollVoters`
	var votingPermissions = Voters.all
	
	/// Get and set the viewing permissions, according to the enum `LJPollViewers`
	var viewingPermissions = Viewers.all
	
	@objc(LJPollVoters) enum Voters: Int {
		case all = 1
		case friends = 2
		
		fileprivate var stringRepresentation: String {
			switch self {
			case .all:
				return "all"
				
			case .friends:
				return "friends"
			}
		}
	}
	
	@objc(LJPollViewers) enum Viewers: Int {
		case all = 1
		case friends = 2
		case none = 3
		
		fileprivate var stringRepresentation: String {
			switch self {
			case .all:
				return "all"
				
			case .friends:
				return "friends"
				
			case .none:
				return "none"
			}
		}
	}

	/// Default initializer
	override init() {
		super.init()
	}
	
	/// How many questions in the poll?
	var numberOfQuestions: Int {
		return questions.count
	}
	
	/// Add a question to the poll
	@objc(addQuestion:) func add(question newQ: PollQuestion) {
		questions.append(newQ)
	}
	
	/// Get the question at the index?
	@objc(questionAtIndex:) func question(at idx: Int) -> PollQuestion {
		return questions[idx]
	}
	
	/// Move a question from idx to newIdx
	@objc(moveQuestionAtIndex:toIndex:) func moveQuestion(at idx: Int, to newIdx: Int) {
		if newIdx == idx {
			return
		}
		if(newIdx < 0 || newIdx >= questions.count) {
			return
		}
		
		let obj = questions[idx]
		questions.remove(at: idx)
		questions.insert(obj, at: newIdx)
	}
	
	/// Insert the question at the given index
	@objc(insertQuestion:atIndex:) func insert(question: PollQuestion, at idx: Int) {
		questions.insert(question, at: idx)
	}
	
	/// Remove the question at idx
	@objc(deleteQuestionAtIndex:) func deleteQuestion(at idx: Int) {
		questions.remove(at: idx)
	}
	
	/// Remove the questions at idx
	@objc(deleteQuestionsAtIndexes:) func deleteQuestions(at idx: IndexSet) {
		questions.remove(indexes: idx)
	}
	
	/// Get the HTML representation of the entire poll.  This method
	/// will gather the HTML representation of every question in the
	/// poll.  There is no need to manually gather the HTML for every
	/// question in the poll.
	var htmlRepresentation: String {
		var buf = "<lj-poll name=\"\(name)\""
		buf += " whovote=\"\(votingPermissions.stringRepresentation)\""
		buf += " whoview=\"\(viewingPermissions.stringRepresentation)\">\n\n"
		
		for ques in questions {
			buf += ques.htmlRepresentation + "\n\n"
		}
		
		buf += "</lj-poll>"
		
		return buf
	}
	
	class var keyPathsForValuesAffectingHtmlRepresentation: Set<String> {
		return Set(["votingPermissions", "viewingPermissions", "name", "questions"])
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(name, forKey: pollNameKey)
		aCoder.encode(questions, forKey: pollQuestionsKey)
		aCoder.encode(votingPermissions.rawValue, forKey: pollVotingKey)
		aCoder.encode(viewingPermissions.rawValue, forKey: pollViewingKey)
	}
	
	
	required convenience init?(coder aDecoder: NSCoder) {
		self.init()
		name = aDecoder.decodeObject(forKey: pollNameKey) as? String ?? name
		questions = aDecoder.decodeObject(forKey: pollQuestionsKey) as? [PollQuestion] ?? questions
		votingPermissions = Voters(rawValue: aDecoder.decodeInteger(forKey: pollVotingKey)) ?? .all
		viewingPermissions = Viewers(rawValue: aDecoder.decodeInteger(forKey: pollViewingKey)) ?? .all
	}
}

extension LJPoll {
	@available(*, unavailable, renamed: "deleteQuestions(at:)")
	@nonobjc func deleteQuestionsAtIndexes(_ idx: IndexSet) {
		
	}
	
	@available(*, unavailable, renamed: "deleteQuestion(at:)")
	@nonobjc func deleteQuestionAtIndex(_ idx: Int) {
		
	}
	
	@available(*, unavailable, renamed: "moveQuestion(at:to:)")
	@nonobjc func moveQuestionAtIndex(_ idx: Int, toIndex newIdx: Int) {
		
	}
	
	@available(*, unavailable, renamed: "insert(question:at:)")
	@nonobjc func insertQuestion(_ question: PollQuestion, atIndex idx: Int) {
		
	}
	
	@available(*, unavailable, renamed: "question(at:)")
	@nonobjc func questionAtIndex(_ idx: Int) -> PollQuestion {
		return question(at: idx)
	}
	
	@available(*, unavailable, renamed: "add(question:)")
	@nonobjc func addQuestion(_ newQ: PollQuestion) {
		
	}
}
