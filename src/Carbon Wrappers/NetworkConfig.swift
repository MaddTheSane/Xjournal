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

@objc class NetworkConfig {
	/// Convenience method that checks:
	///  1. If proxying is enabled generally and then
	///  2. if proxying should be used for the given host
	@objc class func proxyIsEnabledForHost(hostname: String) -> Bool {
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
	@objc class func destinationIsProxied(host: String) -> Bool {
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
	
	private struct NetworkFlags : RawOptionSetType {
		typealias RawValue = UInt32
		private var value: UInt32 = 0
		init(_ value: UInt32) { self.value = value }
		init(rawValue value: UInt32) { self.value = value }
		init(nilLiteral: ()) { self.value = 0 }
		static var allZeros: NetworkFlags { return self(0) }
		static func fromMask(raw: UInt32) -> NetworkFlags { return self(raw) }
		var rawValue: UInt32 { return self.value }
		
		static var TransientConnection: NetworkFlags { return NetworkFlags(1 << 0) }
		static var Reachable: NetworkFlags { return NetworkFlags(1 << 1) }
		static var ConnectionRequired: NetworkFlags { return NetworkFlags(1 << 2) }
		static var ConnectionAutomatic: NetworkFlags { return NetworkFlags(1 << 3) }
		static var InterventionRequired: NetworkFlags { return NetworkFlags(1 << 4) }
		static var IsLocalAddress: NetworkFlags { return NetworkFlags(1 << 16) }
		static var IsDirect: NetworkFlags { return NetworkFlags(1 << 17) }
	}
	
	@objc class func destinationIsReachable(host: String) -> Bool {
		var	result = false
		var	flags: SCNetworkConnectionFlags = 0
		
		let target = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host).takeRetainedValue()
		let ok = SCNetworkReachabilityGetFlags(target, &flags)
		
		if ok {
			let betterFlags = NetworkFlags(flags)
			result = (!((betterFlags & .ConnectionRequired) == .ConnectionRequired)
				&&  ((betterFlags & .Reachable) == .Reachable))
		}
		
		return result
	}
}

private var settingsDictionary: NSDictionary {
	let sc_store = SCDynamicStoreCreate(kCFAllocatorDefault, NSProcessInfo().processName, nil, nil).takeRetainedValue()
	let proxiesKey: String = SCDynamicStoreKeyCreateProxies(kCFAllocatorDefault).takeRetainedValue() as String
	let dict = SCDynamicStoreCopyValue(sc_store, proxiesKey).takeRetainedValue() as! CFDictionary
	return dict
}
