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
//  NetworkConfig.m
//  ProxyDetect
//
//  Created by Fraser Speirs on Thu Sep 12 2002.
//  Copyright (c) 2002 Fraser Speirs. All rights reserved.
//

#import "NetworkConfig.h"

#define SCSTR(s) (NSString *)CFSTR(s)
#import <SystemConfiguration/SystemConfiguration.h>

@interface NetworkConfig(PrivateAPI)
+ (NSDictionary *)getSettingsDictionary;
@end

@implementation NetworkConfig
// Convenience method that checks:
//  1. If proxying is enabled generally and then
//  2. if proxying should be used for the given host
+ (BOOL)proxyIsEnabledForHost:(NSString *) hostname
{
    if(![self httpProxyIsEnabled])
        return NO;
    else
        return [self destinationIsProxied: hostname];
}

// returns YES if HTTP proxying is turned on in System Prefs
+ (BOOL)httpProxyIsEnabled
{
    NSDictionary *dict = [self getSettingsDictionary];
    return [[dict objectForKey: kSCPropNetProxiesHTTPEnable] boolValue];
}

    // Returns the HTTP proxy or nil if none is set
+ (NSString *)httpProxyHost
{
    NSDictionary *dict = [self getSettingsDictionary];
    id val = [dict objectForKey: kSCPropNetProxiesHTTPProxy];
    if([val isKindOfClass: [NSString class]])
        return (NSString *)val;
    else
        return nil;        
}

    // Returns the HTTP Proxy port, or 80 if none is set
+ (int)httpProxyPort {
    NSDictionary *dict = [self getSettingsDictionary];
    id val = [dict objectForKey: kSCPropNetProxiesHTTPPort];
    if(val != nil)
        return [val intValue];
    else {
        return 80;
    }
}

// Returns YES if the proxy should be used for the given URL
// i.e. The domain does not appear in the non-proxied destinations list
+ (BOOL)destinationIsProxied:(NSString *)host {
    NSDictionary *dict = [self getSettingsDictionary];
    NSArray *nonProxied = [dict objectForKey: @"ExceptionsList"];
    
    if(nonProxied != nil && [nonProxied count] > 0) {
        int ct, idx;

        ct = [nonProxied count];
        for(idx = 0; idx < ct; idx++) {
            NSString *exception = [nonProxied objectAtIndex: idx];
            if([host hasSuffix: exception]) {
                return NO;
            }
        }
    }
    return YES;
}

+ (BOOL)destinationIsReachable:(NSString *)host
{
    Boolean                     result;
    SCNetworkConnectionFlags    flags;
    // IMPORTANT:
    // To work with CodeWarrior you should set the
    // "enums are always int" option, which the CWPro8
    // Mach-O stationery fails to do.

    assert(sizeof(SCNetworkConnectionFlags) == sizeof(int));

    result = false;
    if ( SCNetworkCheckReachabilityByName([host cString], &flags) ) {
        result =    !(flags & kSCNetworkFlagsConnectionRequired)
        &&  (flags & kSCNetworkFlagsReachable);
    }

    if(result == 0) {
        return NO;
    }
    else {
        return YES;
    }

}

+ (void)showUnreachableDialog
{
    NSRunInformationalAlertPanel(@"Network Unreachable", @"Livejournal.com is not reachable with your current network settings."
                                 ,@"OK",nil,nil);
}
@end

@implementation NetworkConfig(PrivateAPI)

static void CallBack(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);

+ (NSDictionary *)getSettingsDictionary {
    SCDynamicStoreRef sc_store;
    CFStringRef proxies_key;
    NSDictionary *dict;

    sc_store = SCDynamicStoreCreate(NULL, (CFStringRef)[[NSProcessInfo processInfo] processName], CallBack, NULL);
    proxies_key = SCDynamicStoreKeyCreateProxies(NULL);
    dict = (NSDictionary *)SCDynamicStoreCopyValue(sc_store, proxies_key);
    CFRelease(proxies_key);
    return [dict autorelease];
}

static void CallBack(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info)
{
    NSLogDebug(@"CallBack");
}


@end