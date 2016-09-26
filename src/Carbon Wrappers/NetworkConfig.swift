//
//  NetworkConfig.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/24/15.
//
//

import Foundation
import SystemConfiguration
import SwiftAdditions

class NetworkConfig: NSObject {
	/// Convenience method that checks:
	///  1. If proxying is enabled generally and then
	///  2. if proxying should be used for the given host
	@objc(proxyIsEnabledForHost:) class func proxyIsEnabled(for hostname: String) -> Bool {
		if !httpProxyIsEnabled {
			return false
		} else {
			return destinationIsProxied(hostname)
		}
	}
	
	/// is True if HTTP proxying is turned on in System Prefs
	@objc class var httpProxyIsEnabled: Bool {
		if let aBool = settingsDictionary[kSCPropNetProxiesHTTPEnable as String] as? Bool {
			return aBool
		}
		return false
	}
	
	/// The HTTP proxy, or nil if none is set
	@objc class var httpProxyHost: String? {
		if let val = settingsDictionary[kSCPropNetProxiesHTTPProxy as String] as? String {
			return val
		}
		
		return nil;
	}

	/// Returns YES if the proxy should be used for the given URL.
	/// i.e. The domain does not appear in the non-proxied destinations list.
	@objc class func destinationIsProxied(_ host: String) -> Bool {
		if let nonProxied = settingsDictionary[kSCPropNetProxiesExceptionsList as String] as? [String] {
			for exception in nonProxied {
				if host.hasSuffix(exception) {
					return false
				}
			}
		}
		return true;
	}
	
	/// Returns the HTTP Proxy port, or nil if none is set
	class var httpProxyPort: Int32? {
		if let val = settingsDictionary[kSCPropNetProxiesHTTPPort as String] as? Int {
			return Int32(val)
		}
		return nil
	}
	
	/// Returns the HTTP Proxy port, or 80 if none is set
	@objc class var httpProxyPortOr80: Int32 {
		return httpProxyPort ?? 80
	}
	
	@objc class func destinationIsReachable(_ host: String) -> Bool {
		var	result = false
		var	flags: SCNetworkReachabilityFlags = []
		
		if let target = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host) {
			let ok = SCNetworkReachabilityGetFlags(target, &flags)
			
			if ok {
				result = !flags.contains(.connectionRequired) &&
					flags.contains(.reachable)
			}
		}
		return result
	}
}

private var settingsDictionary: [String: Any] {
	if let sc_store = SCDynamicStoreCreate(kCFAllocatorDefault, ProcessInfo().processName as NSString, nil, nil) {
		let proxiesKey = SCDynamicStoreKeyCreateProxies(kCFAllocatorDefault)
		if let dict = SCDynamicStoreCopyValue(sc_store, proxiesKey) {
			return dict as! CFDictionary as! [String: Any]
		}
	}
	return [:]
}
