//
//  PollEditorController.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/23/15.
//
//

import Cocoa
import OgreKit
import SwiftAdditions

private let kPollAddTextItemIdentifier = "kPollAddTextItemIdentifier"
private let kPollAddMultipleItemIdentifier = "kPollAddMultipleItemIdentifier"
private let kPollAddScaleItemIdentifier = "kPollAddScaleItemIdentifier"

private let kPollDeleteItemIdentifier = "kPollDeleteItemIdentifier"
private let kPollMoveUpItemIdentifier = "kPollMoveUpItemIdentifier"
private let kPollMoveDownItemIdentifier = "kPollMoveDownItemIdentifier"
private let kPollShowCodeItemIdentifier = "kPollShowCodeItemIdentifier"

private let kMultipleAnswerPasteboardType = "kMultipleAnswerPasteboardType"
private let kPollQuestionPasteboardType = "kPollQuestionPasteboardType"


private let sheetOK = 0
private let sheetCancel = 1

class XJPollEditorController: NSWindowController {
    var thePoll = LJPoll()
    var currentlyEditedQuestion: PollQuestion!
    private weak var currentSheet: NSWindow?
    fileprivate var toolbarItemCache = [String: NSToolbarItem]()
	fileprivate var currentlyEditedQuestionMemento: [String: Any]?
    
    @IBOutlet weak var pollName: NSTextField!
    @IBOutlet weak var questionTable: NSTableView!
    @IBOutlet weak var resultAccess: NSPopUpButton!
    
    @IBOutlet weak var drawer: NSDrawer!
    @IBOutlet weak var drawerTextView: NSScrollView!
    
    @IBOutlet weak var multipleAnswerTable: NSTableView!
    @IBOutlet weak var multipleQuestion: NSTextField!
    @IBOutlet weak var multipleSheet: NSPanel!
    @IBOutlet weak var multipleType: NSPopUpButton!
    
    @IBOutlet weak var scaleSheet: NSPanel!
    @IBOutlet weak var scaleQuestionField: NSTextField!
    @IBOutlet weak var scaleStartField: NSTextField!
    @IBOutlet weak var scaleEndField: NSTextField!
    @IBOutlet weak var scaleStepField: NSTextField!
    
    @IBOutlet weak var textQuestionField: NSTextField!
    @IBOutlet weak var textSizeField: NSTextField!
    @IBOutlet weak var textMaxLengthField: NSTextField!
    @IBOutlet weak var textSheet: NSPanel!
    @IBOutlet weak var votingAccess: NSPopUpButton!

    class var nibName: String {
        return "PollEditor"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        let toolBar = NSToolbar(identifier: "kPollToolbar")
        toolBar.allowsUserCustomization = true
        toolBar.autosavesConfiguration = true
        toolBar.delegate = self
        window?.toolbar = toolBar
        
        pollName.stringValue = thePoll.name
        questionTable.target = self
        questionTable.doubleAction = #selector(XJPollEditorController.editSelectedQuestion(_:))
        
        // Set the height of the drawer
        let currentDrawerSize = drawer.contentSize
        drawer.contentSize = NSSize(width: currentDrawerSize.width, height: 150)
        
        drawer.open()
    }

	@IBAction func changePollName(_ sender: AnyObject?) {
		if let asend = sender as? NSTextField {
			let regex = OGRegularExpression(string: "\"")!
			thePoll.name = regex.replaceAllMatches(in: asend.stringValue, with: "&quot;")
			updateDrawer()
		}
	}

    @IBAction func changeVotingAccess(_ sender: AnyObject?) {
        if let unwrapped = sender as? NSPopUpButton {
            if let v2 = unwrapped.selectedItem?.tag {
				if let votrs = LJPoll.Voters(rawValue: v2) {
					thePoll.votingPermissions = votrs
				}
            }
        } else {
            return
        }
        updateDrawer()
    }
    
    @IBAction func changeResultAccess(_ sender: AnyObject?) {
        if let unwrapped = sender as? NSPopUpButton {
            if let v2 = unwrapped.selectedItem?.tag {
				if let aViers = LJPoll.Viewers(rawValue: v2) {
					thePoll.viewingPermissions = aViers
				}
            }
        } else {
            return
        }
        updateDrawer()
    }
	
	@IBAction func cancelSheet(_ sender: AnyObject?) {
		currentSheet!.endEditing(for: nil)
		window?.endSheet(currentSheet!, returnCode: sheetCancel)
	}
	
	@IBAction func commitSheet(_ sender: AnyObject?) {
		currentSheet!.endEditing(for: nil)
		window?.endSheet(currentSheet!, returnCode: sheetOK)
	}
    
	@IBAction func editSelectedQuestion(_ sender: AnyObject?) {
		let selectedRow = questionTable.selectedRow
		if selectedRow != -1 {
			currentlyEditedQuestion = thePoll.question(at: selectedRow)
			currentlyEditedQuestionMemento = currentlyEditedQuestion.memento
			if let _ = currentlyEditedQuestion as? PollMultipleOptionQuestion {
				runMultipleSheet()
			} else if let _ = currentlyEditedQuestion as? PollScaleQuestion {
				runScaleSheet()
			} else if let _ = currentlyEditedQuestion as? PollTextEntryQuestion {
				runTextSheet()
			}
		}
	}
	
	@IBAction func moveSelectedQuestionUp(_ sender: AnyObject?) {
		currentSheet?.endEditing(for: nil)
		if let aTag = (sender as? NSControl)?.tag {
			switch aTag {
			case 0:
				if questionTable.numberOfSelectedRows == 1 {
					thePoll.moveQuestion(at: questionTable.selectedRow, to: questionTable.selectedRow - 1)
					questionTable.selectRowIndexes(IndexSet(integer: questionTable.selectedRow - 1), byExtendingSelection: false)
					questionTable.reloadData()
				}
				
			case 1:
				if multipleAnswerTable.numberOfSelectedRows == 1 {
					(currentlyEditedQuestion as! PollMultipleOptionQuestion).moveAnswer(at: multipleAnswerTable.selectedRow, to: multipleAnswerTable.selectedRow - 1)
					multipleAnswerTable.selectRowIndexes(IndexSet(integer: multipleAnswerTable.selectedRow - 1), byExtendingSelection: false)
					multipleAnswerTable.reloadData()
				}
				
			default:
				break
			}
			updateDrawer()
		}
	}
	
	@IBAction func moveSelectedQuestionDown(_ sender: AnyObject?) {
		currentSheet?.endEditing(for: nil)
		if let aTag = (sender as? NSControl)?.tag {
			switch aTag {
			case 0:
				if questionTable.numberOfSelectedRows == 1 {
					thePoll.moveQuestion(at: questionTable.selectedRow, to: questionTable.selectedRow + 1)
					questionTable.selectRowIndexes(IndexSet(integer: questionTable.selectedRow + 1), byExtendingSelection: false)
					questionTable.reloadData()
				}
				
			case 1:
				if multipleAnswerTable.numberOfSelectedRows == 1 {
					(currentlyEditedQuestion as! PollMultipleOptionQuestion).moveAnswer(at: multipleAnswerTable.selectedRow, to: multipleAnswerTable.selectedRow + 1)
					multipleAnswerTable.selectRowIndexes(IndexSet(integer: multipleAnswerTable.selectedRow + 1), byExtendingSelection: false)
					multipleAnswerTable.reloadData()
				}
				
			default:
				break
			}
			updateDrawer()
		}
	}

	@IBAction func addMultipleAnswer(_ sender: AnyObject) {
		multipleSheet.endEditing(for: nil)
		(currentlyEditedQuestion as! PollMultipleOptionQuestion).add(answer: "answer")
		multipleAnswerTable.reloadData()
		multipleAnswerTable.selectRowIndexes(IndexSet(integer: multipleAnswerTable.numberOfRows - 1), byExtendingSelection: false)
		multipleAnswerTable.editColumn(0, row: multipleAnswerTable.numberOfRows - 1, with: nil, select: true)
		updateDrawer()
	}
	
	@IBAction func addMultipleQuestion(_ sender: AnyObject?) {
		currentlyEditedQuestion = PollMultipleOptionQuestion(type: .radio)
		currentlyEditedQuestionMemento = currentlyEditedQuestion.memento
		
		(currentlyEditedQuestion as! PollMultipleOptionQuestion).add(answer: "answer")
		
		thePoll.add(question: currentlyEditedQuestion)
		questionTable.reloadData()
		
		runMultipleSheet()
		updateDrawer()
	}
	
	@IBAction func changeMultipleOptionType(_ sender: AnyObject?) {
		if let aTag = (sender as? NSPopUpButton)?.selectedItem?.tag {
			if let aTyp = PollMultipleOptionQuestion.MultipleOption(rawValue: aTag) {
				(currentlyEditedQuestion as! PollMultipleOptionQuestion).type = aTyp
			}
		}
	}

	@IBAction func addScaleQuestion(_ sender: AnyObject?) {
		currentlyEditedQuestion = PollScaleQuestion(start: 1, end: 10, step: 1)
		currentlyEditedQuestionMemento = currentlyEditedQuestion.memento
		
		thePoll.add(question: currentlyEditedQuestion)
		questionTable.reloadData()
		runScaleSheet()
		updateDrawer()
	}
	
	@IBAction func addTextQuestion(_ sender: AnyObject?) {
		currentlyEditedQuestion = PollTextEntryQuestion(size: 30, maxLength: 15)
		currentlyEditedQuestionMemento = currentlyEditedQuestion.memento
		
		thePoll.add(question: currentlyEditedQuestion)
		questionTable.reloadData()
		runTextSheet()
		updateDrawer()
	}
	
	@IBAction func deleteMultipleAnswer(_ sender: AnyObject?) {
		window?.endEditing(for: nil)
		
		let selectedRows = multipleAnswerTable.selectedRowIndexes
		(currentlyEditedQuestion as! PollMultipleOptionQuestion).deleteAnswers(at: selectedRows)
		
		multipleAnswerTable.reloadData()
		updateDrawer()
	}

	@IBAction func deleteSelectedQuestion(_ sender: AnyObject?) {
		let selectedRows = questionTable.selectedRowIndexes
		
		thePoll.deleteQuestions(at: selectedRows)
		
		questionTable.reloadData()
		updateDrawer()
	}
	
	private func runMultipleSheet() {
		currentSheet = multipleSheet
		
		multipleQuestion.stringValue = currentlyEditedQuestion.question
		multipleAnswerTable.reloadData()
		
		let questionType = (currentlyEditedQuestion as! PollMultipleOptionQuestion).type
		switch questionType {
		case .radio:
			multipleType.selectItem(at: 0)
			
		case .checkBox:
			multipleType.selectItem(at: 1)
			
		case .dropDown:
			multipleType.selectItem(at: 2)
		}
		
		window?.beginSheet(multipleSheet, completionHandler: { (response) -> Void in
			switch response {
			case NSModalResponseAbort, sheetCancel:
				self.currentlyEditedQuestion.restore(fromMemento: self.currentlyEditedQuestionMemento!)
				self.currentlyEditedQuestionMemento = nil
				self.currentSheet = nil;

			case sheetOK, NSModalResponseStop:
				self.currentlyEditedQuestion.question = self.multipleQuestion.stringValue
				self.currentlyEditedQuestionMemento = nil
				self.currentSheet = nil;
				self.questionTable.reloadData()
				self.updateDrawer()

			default:
				break
			}
		})
	}
	
	private func runScaleSheet() {
		currentSheet = scaleSheet
		
		scaleQuestionField.stringValue = currentlyEditedQuestion.question
		scaleStartField.integerValue = (currentlyEditedQuestion as! PollScaleQuestion).start
		scaleEndField.integerValue = (currentlyEditedQuestion as! PollScaleQuestion).end
		scaleStepField.integerValue = (currentlyEditedQuestion as! PollScaleQuestion).step
		
		window?.beginSheet(scaleSheet, completionHandler: { (response) -> Void in
			switch response {
			case NSModalResponseAbort, sheetCancel:
				self.currentlyEditedQuestion.restore(fromMemento: self.currentlyEditedQuestionMemento!)
				self.currentlyEditedQuestionMemento = nil
				self.currentSheet = nil;
				
			case sheetOK, NSModalResponseStop:
				let currEdQues = self.currentlyEditedQuestion as! PollScaleQuestion
				self.currentlyEditedQuestion.question = self.scaleQuestionField.stringValue
				currEdQues.start = self.scaleStartField.integerValue
				currEdQues.end = self.scaleEndField.integerValue
				currEdQues.step = self.scaleStepField.integerValue
				self.currentlyEditedQuestionMemento = nil
				self.currentSheet = nil;
				self.questionTable.reloadData()
				self.updateDrawer()
				
			default:
				break
			}
		})
	}
	
	private func runTextSheet() {
		currentSheet = textSheet
		
		textQuestionField.stringValue = currentlyEditedQuestion.question
		textSizeField.integerValue = (currentlyEditedQuestion as! PollTextEntryQuestion).size
		textMaxLengthField.integerValue = (currentlyEditedQuestion as! PollTextEntryQuestion).maxLength
		
		window?.beginSheet(textSheet, completionHandler: { (response) -> Void in
			switch response {
			case NSModalResponseAbort, sheetCancel:
				self.currentlyEditedQuestion.restore(fromMemento: self.currentlyEditedQuestionMemento!)
				self.currentlyEditedQuestionMemento = nil
				self.currentSheet = nil;

			case sheetOK, NSModalResponseStop:
				self.currentlyEditedQuestion.question = self.textQuestionField.stringValue
				let currEdQues = self.currentlyEditedQuestion as! PollTextEntryQuestion
				currEdQues.size = self.textSizeField.integerValue
				currEdQues.maxLength = self.textMaxLengthField.integerValue
				self.currentlyEditedQuestionMemento = nil
				self.currentSheet = nil;
				self.questionTable.reloadData()
				self.updateDrawer()
				
			default:
				break
			}
		})
	}

	private func updateDrawer() {
        (drawerTextView.contentView.documentView as! NSTextView).string = thePoll.htmlRepresentation
    }
}

//MARK: NSToolbarDelegate
extension XJPollEditorController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: String, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        var item = toolbarItemCache[itemIdentifier]

        if item == nil {
            item = NSToolbarItem(itemIdentifier: itemIdentifier)
            switch itemIdentifier {
            case kPollAddTextItemIdentifier:
                item!.label = NSLocalizedString("Insert Text", comment: "")
				item!.paletteLabel = NSLocalizedString("Insert Text Question", comment: "")
                item!.target = self
				item!.action = #selector(XJPollEditorController.addTextQuestion(_:))
				item!.toolTip = NSLocalizedString("Add a Text question to the Poll", comment: "")
				item!.image = NSImage(named: "InsertTextQuestion")
				
				// Add Scale
			case kPollAddScaleItemIdentifier:
				item!.label = NSLocalizedString("Insert Scale", comment: "")
				item!.paletteLabel = NSLocalizedString("Insert Text Question", comment: "")
				item!.target = self
				item!.action = #selector(XJPollEditorController.addTextQuestion(_:))
				item!.toolTip = NSLocalizedString("Add a scale question to the poll", comment: "")
				item!.image = NSImage(named: "InsertScaleQuestion")
				
				// Multiple
			case kPollAddMultipleItemIdentifier:
				item!.label = NSLocalizedString("Insert Multiple", comment: "")
				item!.paletteLabel = NSLocalizedString("Insert Multple Question", comment: "")
				item!.target = self
				item!.action = #selector(XJPollEditorController.addMultipleQuestion(_:))
				item!.toolTip = NSLocalizedString("Add a multiple choice question to the poll", comment: "")
				item!.image = NSImage(named: "InsertMultipleChoice")
				
			case kPollDeleteItemIdentifier:
				item!.label = NSLocalizedString("Delete", comment: "")
				item?.paletteLabel = NSLocalizedString("Delete Question", comment: "")
				item?.toolTip = NSLocalizedString("Delete selected question from poll", comment: "")
				item?.image = CarbonToolbarIcons.delete.iconRepresentation
				item?.target = self
				item?.action = #selector(XJPollEditorController.deleteSelectedQuestion(_:))
				
			case kPollMoveDownItemIdentifier:
				item?.label = NSLocalizedString("Move Down", comment: "")
				item?.paletteLabel = NSLocalizedString("Move Question Down", comment: "")
				item?.toolTip = NSLocalizedString("Move the selected question down", comment: "")
				item?.image = NSImage(named: "MoveDown")
				item?.target = self
				item?.tag = 0
				item?.action = #selector(XJPollEditorController.moveSelectedQuestionDown(_:))
				
			case kPollMoveUpItemIdentifier:
				item?.label = NSLocalizedString("Move Up", comment: "")
				item?.paletteLabel = NSLocalizedString("Move Question Up", comment: "")
				item?.toolTip = NSLocalizedString("Move the selected question up", comment: "")
				item?.image = NSImage(named:"MoveUp")
				item?.target = self
				item?.tag = 0
				item?.action = #selector(XJPollEditorController.moveSelectedQuestionUp(_:))
				
			case kPollShowCodeItemIdentifier:
				item?.label = NSLocalizedString("Show Code", comment: "")
				item?.paletteLabel = NSLocalizedString("Show Poll Code", comment: "")
				item?.toolTip = NSLocalizedString("Open the code drawer", comment: "")
				item?.image = NSImage(named: "ShowCode")
				item?.target = drawer
				item?.action = #selector(NSDrawer.toggle(_:))

            default:
                break;
            }
			
			toolbarItemCache[itemIdentifier] = item!
        }
        
        return item
    }
	
	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [String] {
		return [kPollAddTextItemIdentifier,
			kPollAddMultipleItemIdentifier,
			kPollAddScaleItemIdentifier,
			kPollDeleteItemIdentifier,
			kPollMoveUpItemIdentifier,
			kPollMoveDownItemIdentifier,
			kPollShowCodeItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier]
	}
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [String] {
		return [kPollAddTextItemIdentifier,
			kPollAddMultipleItemIdentifier,
			kPollAddScaleItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			kPollMoveUpItemIdentifier,
			kPollMoveDownItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			kPollShowCodeItemIdentifier,
			kPollDeleteItemIdentifier]
	}
}

// MARK: NSTableViewDelegate/DataSource
extension XJPollEditorController: NSTableViewDelegate, NSTableViewDataSource {
	func numberOfRows(in atableView: NSTableView) -> Int {
		if atableView == questionTable {
			return thePoll.numberOfQuestions
		} else if atableView == multipleAnswerTable {
			if let multipleOption = currentlyEditedQuestion as? PollMultipleOptionQuestion {
				return multipleOption.numberOfAnswers
			}
		}
		return 0
	}
	
	func tableView(_ aTableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		if aTableView == questionTable {
			let theQuestion = thePoll.question(at: row)
			if tableColumn?.identifier == "question" {
				return theQuestion.question
			} else {
				if let aQues = theQuestion as? PollMultipleOptionQuestion {
					switch aQues.type {
					case .radio:
						return NSLocalizedString("Radio Buttons", comment: "")
					case .checkBox:
						return NSLocalizedString("Check Boxes", comment: "");
					case .dropDown:
						return NSLocalizedString("Drop Down Menu", comment: "");

					}
				} else if let _ = theQuestion as? PollTextEntryQuestion {
					return NSLocalizedString("Text", comment: "");

				} else if let aQues = theQuestion as? PollScaleQuestion {
					return String(format: NSLocalizedString("Scale (%ld-%ld by %ld)", comment: ""), aQues.start, aQues.end, aQues.step)
				}
			}
		} else if aTableView == multipleAnswerTable {
			if let multipleOption = currentlyEditedQuestion as? PollMultipleOptionQuestion {
				return multipleOption.answer(at: row)
			}
		}

		return ""
	}
	
	func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
		return tableView == multipleAnswerTable
	}
	
	func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
		if tableView == multipleAnswerTable {
			if let aQues = currentlyEditedQuestion as? PollMultipleOptionQuestion {
				aQues.set(answer: object as! String, at: row)
			}
		}
	}
}
