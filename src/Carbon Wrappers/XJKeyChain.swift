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
	
	@objc(defaultKeyChain) static let `default`: KeyChain = KeyChain()
	
	private func genericPasswordReference(service: String, account: String) -> SecKeychainItem? {
		var itemref: SecKeychainItem? = nil
		SecKeychainFindGenericPassword(currentKeychain, UInt32(service.lengthOfBytes(using: String.Encoding.utf8)), service, UInt32(account.lengthOfBytes(using: String.Encoding.utf8)), account, nil, nil, &itemref)
		
		return itemref
	}
	
	@objc(removeGenericPasswordForService:account:) func removeGenericPassword(service: String, account: String) {
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
			SecKeychainAddGenericPassword(currentKeychain, UInt32(service.lengthOfBytes(using: String.Encoding.utf8)), service, UInt32(account.lengthOfBytes(using: String.Encoding.utf8)), account, UInt32(aPass.lengthOfBytes(using: String.Encoding.utf8)), UnsafeRawPointer((aPass as NSString).utf8String!), nil)
		} else {
			removeGenericPassword(service: service, account: account)
		}
	}
	
	@objc(genericPasswordForService:account:) func genericPassword(service: String, account: String) -> String {
		var ret: OSStatus = noErr
		var string = ""
		var p: UnsafeMutableRawPointer? = nil
		var length: UInt32 = 0
		
		if service.characters.count == 0 || account.characters.count == 0 {
			return ""
		}

		ret = SecKeychainFindGenericPassword(currentKeychain, UInt32(service.lengthOfBytes(using: String.Encoding.utf8)), service, UInt32(account.lengthOfBytes(using: String.Encoding.utf8)), account, &length, &p, nil)
		
		if ret == noErr {
			string = NSString(bytes: p!, length: Int(length), encoding: String.Encoding.utf8.rawValue) as! String
		}
		if p != nil {
			SecKeychainItemFreeContent(nil, p)
		}
		
		return string
	}
	
	var keychainURL: URL? {
		var pathLen: UInt32 = 0
		var pathName: [Int8] = [Int8](repeating: 0, count: Int(PATH_MAX))
		let iErr = SecKeychainGetPath(currentKeychain, &pathLen, &pathName)
		if iErr != noErr {
			return nil
		}
		pathName[Int(pathLen)] = 0
		
		return URL(fileURLWithFileSystemRepresentation: pathName, isDirectory: false, relativeTo: nil)
	}
}
