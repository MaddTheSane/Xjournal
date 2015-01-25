//
//  XJKeyChain.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/24/15.
//
//

import Cocoa
import Security

var adefaultKeyChain: KeyChain?

final class KeyChain: NSObject {
	var maxPasswordLength: UInt32
	
	required override init() {
		maxPasswordLength = 127;
		
		super.init()
	}
	
	class var defaultKeyChain: KeyChain {
		return adefaultKeyChain ?? self()
	}
	
	private func genericPasswordReference(#service: String, account: String) -> SecKeychainItemRef? {
		var itemref: Unmanaged<SecKeychainItem>? = nil
		SecKeychainFindGenericPassword(nil, UInt32(service.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), service, UInt32(account.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), account, nil, nil, &itemref)
		
		return itemref?.takeRetainedValue()
	}
	
	@objc(removeGenericPasswordForService:account:) func removeGenericPassword(#service: String, account: String) {
		if let itemref = genericPasswordReference(service: service, account: account) {
			SecKeychainItemDelete(itemref)
		}
	}
	
	@objc(setGenericPassword:forService:account:) func setGenericPassword(password: String?, service: String, account: String) {
		var ret: OSStatus = noErr
		
		if countElements(service) == 0 || countElements(account) == 0 {
			return
		}
		
		if let aPass = password {
			if let itemRef = genericPasswordReference(service: service, account: account) {
				SecKeychainItemDelete(itemRef)
			}
			(aPass as NSString).UTF8String
			var itemRef: Unmanaged<SecKeychainItem>? = nil
			SecKeychainAddGenericPassword(nil, UInt32(service.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), service, UInt32(account.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), account, UInt32(aPass.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), UnsafePointer<()>((aPass as NSString).UTF8String), &itemRef)
			
			itemRef?.release()
		} else {
			removeGenericPassword(service: service, account: account)
		}
	}
	
	@objc(genericPasswordForService:account:) func genericPassword(#service: String, account: String) -> String {
		var ret: OSStatus = noErr
		var string = ""
		var p: UnsafeMutablePointer<()> = nil
		var length: UInt32 = 0
		
		if countElements(service) == 0 || countElements(account) == 0 {
			return ""
		}

		ret = SecKeychainFindGenericPassword(nil, UInt32(service.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), service, UInt32(account.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), account, &length, &p, nil)
		
		if ret == noErr {
			string = NSString(bytes: p, length: Int(length), encoding: NSUTF8StringEncoding)!
		}
		
		if p != nil {
			SecKeychainItemFreeContent(nil, p)
		}
		return string
	}
}
