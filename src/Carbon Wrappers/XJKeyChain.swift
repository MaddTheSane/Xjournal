//
//  XJKeyChain.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/24/15.
//
//

import Foundation
import Security

private var adefaultKeyChain: KeyChain = {
	return KeyChain()
}()

final class KeyChain: NSObject {
	var maxPasswordLength: UInt32
	private let currentKeychain: SecKeychain?
	
	enum PreferencesDomain: UInt32 {
		///user domain
		case User
		
		///system (daemon) domain
		case System
		
		///preferences to be merged to everyone
		case Common
		
		///dynamic searchlist (typically removable keychains like smartcards)
		case Dynamic
	}

	required convenience override init() {
		var defKeyChain: SecKeychain?
		_ = SecKeychainCopyDefault(&defKeyChain)
		self.init(keychain: defKeyChain)
	}
	
	init(keychain: SecKeychain?) {
		maxPasswordLength = 127;
		currentKeychain = keychain
		
		super.init()
	}
	
	convenience init?(keychainPath: NSURL) {
		var capturedKey: SecKeychain?
		
		_ = SecKeychainOpen(keychainPath.fileSystemRepresentation, &capturedKey)
		if let aKey = capturedKey {
			self.init(keychain: aKey)
		} else {
			self.init(keychain: nil)
			
			return nil
		}
	}
	
	class var defaultKeyChain: KeyChain {
		return adefaultKeyChain
	}
	
	private func genericPasswordReference(service service: String, account: String) -> SecKeychainItemRef? {
		var itemref: SecKeychainItem? = nil
		SecKeychainFindGenericPassword(currentKeychain, UInt32(service.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), service, UInt32(account.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), account, nil, nil, &itemref)
		
		return itemref
	}
	
	@objc(removeGenericPasswordForService:account:) func removeGenericPassword(service service: String, account: String) {
		if let itemref = genericPasswordReference(service: service, account: account) {
			SecKeychainItemDelete(itemref)
		}
	}
	
	@objc(setGenericPassword:forService:account:) func setGenericPassword(password: String?, service: String, account: String) {
		//var ret: OSStatus = noErr
		
		if service.characters.count == 0 || account.characters.count == 0 {
			return
		}
		
		if let aPass = password {
			if let itemRef = genericPasswordReference(service: service, account: account) {
				SecKeychainItemDelete(itemRef)
			}
			SecKeychainAddGenericPassword(currentKeychain, UInt32(service.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), service, UInt32(account.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), account, UInt32(aPass.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), UnsafePointer<()>((aPass as NSString).UTF8String), nil)
		} else {
			removeGenericPassword(service: service, account: account)
		}
	}
	
	@objc(genericPasswordForService:account:) func genericPassword(service service: String, account: String) -> String {
		var ret: OSStatus = noErr
		var string = ""
		var p: UnsafeMutablePointer<()> = nil
		var length: UInt32 = 0
		
		if service.characters.count == 0 || account.characters.count == 0 {
			return ""
		}

		ret = SecKeychainFindGenericPassword(currentKeychain, UInt32(service.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), service, UInt32(account.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), account, &length, &p, nil)
		
		if ret == noErr {
			string = NSString(bytes: p, length: Int(length), encoding: NSUTF8StringEncoding) as! String
		}
		if p != nil {
			SecKeychainItemFreeContent(nil, p)
		}
		
		return string
	}
	
	var keychainURL: NSURL? {
		var pathLen: UInt32 = 0
		var pathName: [Int8] = [Int8](count: Int(PATH_MAX), repeatedValue: 0)
		let iErr = SecKeychainGetPath(currentKeychain, &pathLen, &pathName)
		if iErr != noErr {
			return nil
		}
		pathName[Int(pathLen)] = 0
		
		return NSURL(fileURLWithFileSystemRepresentation: pathName, isDirectory: false, relativeToURL: nil)
	}
}
