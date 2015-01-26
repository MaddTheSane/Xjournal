//
//  LJPoll.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/23/15.
//
//

import Foundation
import SwiftAdditions

class LJPoll: NSObject {
	private var questions = [LJPollQuestion]()
	/// Get and set the name of the poll
	var name = "NewPoll"
	
	/// Get and set the voting permissions, according to the enum PollVoters
	var votingPermissions = Voters.All
	
	/// Get and set the viewing permissions, according to the enum PollViewers
	var viewingPermissions = Viewers.All
	
	enum Voters: Int {
		case All = 1
		case Friends = 2
		
		private var stringRepresentation: String {
			switch self {
			case .All:
				return "all"
				
			case .Friends:
				return "friends"
			}
		}
	}
	
	enum Viewers: Int {
		case All = 1
		case Friends = 2
		case None = 3
		
		private var stringRepresentation: String {
			switch self {
			case .All:
				return "all"
				
			case .Friends:
				return "friends"
				
			case .None:
				return "none"
			}
		}
	}

	/// How many questions in the poll?
	var numberOfQuestions: Int {
		return questions.count
	}
	
	/// Add a question to the poll
	func addQuestion(newQ: LJPollQuestion) {
		questions.append(newQ)
	}
	
	/// Get the question at the index?
	func questionAtIndex(idx: Int) -> LJPollQuestion {
		return questions[idx]
	}
	
	/// Move a question from idx to newIdx
	func moveQuestionAtIndex(idx: Int, toIndex newIdx: Int) {
		if newIdx == idx {return}
		if(newIdx < 0 || newIdx >= questions.count) {return}
		
		let obj = questions[idx]
		questions.removeAtIndex(idx)
		questions.insert(obj, atIndex: newIdx)
	}
	
	/// Insert the question at the given index
	func insertQuestion(question: LJPollQuestion, atIndex idx: Int) {
		questions.insert(question, atIndex: idx)
	}
	
	/// Remove the question at idx
	func deleteQuestionAtIndex(idx: Int) {
		questions.removeAtIndex(idx)
	}
	
	/// Remove the questions at idx
	func deleteQuestionsAtIndexes(idx: NSIndexSet) {
		removeObjects(inArray: &questions, atIndexes: idx)
	}
	
	/**
 Get the HTML representation of the entire poll.  This method
 will gather the HTML representation of every question in the
 poll.  There is no need to manually gather the HTML for every
 question in the poll.
 */
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
}
