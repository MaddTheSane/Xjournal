/*
 * Copyright (c) 2002
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 *  * Neither the name of the author nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
* BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 */
//
//  NetworkConfig.h
//  ProxyDetect
//
//  Created by Fraser Speirs on Thu Sep 12 2002.
//  Copyright (c) 2002 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define NSLogDebug NSLog
@interface NetworkConfig : NSObject

// Convenience method that checks:
//  1. If proxying is enabled generally and then
//  2. if proxying should be used for the given host
+ (BOOL)proxyIsEnabledForHost:(NSString *) hostname;

// returns YES if HTTP proxying is turned on in System Prefs
+ (BOOL)httpProxyIsEnabled;

// Returns the HTTP proxy or nil if none is set
+ (NSString *)httpProxyHost;

// Returns the HTTP Proxy port, or -1 if none is set
+ (int)httpProxyPort;

// Returns YES if the proxy should be used for the given URL
// i.e. The domain does not appear in the non-proxied destinations list

// XXX Still a couple of bugs in this method...
+ (BOOL)destinationIsProxied:(NSString *)host;

+ (BOOL)destinationIsReachable:(NSString *)host;

+ (void)showUnreachableDialog;
@end
