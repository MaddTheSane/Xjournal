/*
 * $Id: NSString+Extensions.m,v 1.2 2004/08/07 22:00:42 fspeirs Exp $
 *
 * Copyright (c) 2001, 2002 William J. Coldwell
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



#import "NSString+Extensions.h"
#define NSLogDebug NSLog
#import "XJPreferences.h"
#import <AGRegex/AGRegex.h>

@implementation NSString (LJCutConversions)

- (NSString *)translateNewLines
{
	NSMutableString *newString = [[NSMutableString stringWithCapacity: [self length]] retain];	 
    [newString appendString: self];

    [newString replaceOccurrencesOfString: @"\n" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    [newString replaceOccurrencesOfString: @"\r" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    [newString replaceOccurrencesOfString: @"\r\n" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    return [newString autorelease];

	/*
	 Here's a new algorithm:
	 
	 1. Find every instance of <table></table> pairs.
	 2. Run the above conversions on the areas outside those ranges.
	
	NSScanner *scanner = [[NSScanner scannerWithString: self] retain];
	while(![scanner isAtEnd]) {
		NSString *temp;
		if([scanner scanUpToString: @"<table" intoString: &temp]) {
			[temp convertNewlinesToBR];
			[newString appendString: temp];
			temp = @"";
			[newString appendString: @"<table"];
			
			[scanner scanUpToString: @">" intoString: &temp];
			[newString appendString: temp];
			[newString appendString: @">"];
			
			[scanner scanUpToString: @"</table>" intoString: &temp];
			[newString appendString: temp];
			[newString appendString: @"</table>"];
		}
	}
	*/
	return [newString autorelease];
}

- (NSString *)convertNewlinesToBR {
	NSMutableString *newString = [[NSMutableString stringWithCapacity: [self length]] retain];
    [newString appendString: self];
	
    [newString replaceOccurrencesOfString: @"\n" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    [newString replaceOccurrencesOfString: @"\r" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    [newString replaceOccurrencesOfString: @"\r\n" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    return [newString autorelease];
}

- (NSString *)translateLJUser
{
    AGRegex *userRegex = [[AGRegex alloc] initWithPattern:@"<lj user=\"([A-Za-z0-9_]*)\" ?/?>" options:0];
    NSString *result = [userRegex replaceWithString: [NSString stringWithFormat: @"<nobr><a href=\"http://www.livejournal.com/userinfo.bml?user=$1\"><img height=\"17\" border=\"0\" src=\"%@\" align=\"absmiddle\" width=\"17\"></a><b><a href=\"http://www.livejournal.com/users/$1/\">$1</a></b></nobr>", [XJPreferences userIconURL]] inString: self];
    [userRegex release];
    return result;
}

- (NSString *)translateLJComm
{
    AGRegex *commRegex = [[AGRegex alloc] initWithPattern:@"<lj comm=\"([A-Za-z0-9_]*)\">" options:0];
    NSString *result = [commRegex replaceWithString: [NSString stringWithFormat: @"<nobr><a href=\"http://www.livejournal.com/userinfo.bml?user=$1\"><img height=\"17\" border=\"0\" src=\"%@\" align=\"absmiddle\" width=\"17\"></a><b><a href=\"http://www.livejournal.com/community/$1/\">$1</a></b></nobr>", [XJPreferences communityIconURL]] inString: self];
    [commRegex release];
    return result;
}


- (NSString *)translateLJCutOpenTagWithText
{
    AGRegex *blockRegex = [[AGRegex alloc] initWithPattern:@"<lj-cut text=\"([^>]*)\">" options:0];
    NSString *result = [blockRegex replaceWithString: @"<div class=\"xjljcut\">LJ-Cut: $1</div>" inString: self];
    [blockRegex release];
    return result; 
}

- (NSString *)translateBasicLJCutOpenTag
{
    AGRegex *blockRegex = [[AGRegex alloc] initWithPattern:@"<lj-cut>" options:0];
    NSString *result = [blockRegex replaceWithString: @"<div class=\"xjljcut\">LJ-Cut</div>" inString: self];
    [blockRegex release];
    return result;    
}

- (NSString *)translateLJCutCloseTag
{
    AGRegex *blockRegex = [[AGRegex alloc] initWithPattern:@"</lj-cut>" options:0];
    NSString *result = [blockRegex replaceWithString: @"<br><div class=\"xjljcut\">&nbsp;</div>" inString: self];
    [blockRegex release];
    return result;
}

- (NSString *)translateLJPoll
{
    AGRegex *blockRegex = [[AGRegex alloc] initWithPattern:@"<lj-poll-([^>]*)>" options:0];
    NSString *result = [blockRegex replaceWithString: @"<a href=\"http://www.livejournal.com/poll/?id=$1\">LJ-Poll ID: $1</a>" inString: self];
    [blockRegex release];
    return result;
}

- (NSString *)translateLJPhonePostWithItemURL:(NSString *)url userName: (NSString *)user{
    AGRegex *blockRegex = [[AGRegex alloc] initWithPattern:@"<lj-phonepost journalid='([^']*)' dpid='([^']*)' />" options:0];
    NSString *result = [blockRegex replaceWithString: [NSString stringWithFormat: @"<a href=\"http://files.livejournal.com/%@/phonepost/$2.ogg\">PhonePost</a> (<a href=\"http://www.livejournal.com/phonepost/transcribe.bml?user=%@&ppid=$2\">transcribe</a>)<br><br><a href=\"%@\">View PhonePost Online</a>", user, user, url] inString: self];
    [blockRegex release];
    return result;
    
    // Old style
    //<lj-phonepost user='fraserspeirs' phonepostid='3' />
    
    // New style
    //<lj-phonepost journalid='127645' dpid='1498' />
    
}
@end

// ----------------------------------------------------------
// Moved from NSString+extras.m from Ranchero.com's RSS class
// ----------------------------------------------------------
@implementation NSString (extras)
- (NSString *) trimWhiteSpace {
    
    NSMutableString *s = [[self mutableCopy] autorelease];
    
    CFStringTrimWhitespace ((CFMutableStringRef) s);
    
    return (NSString *) [[s copy] autorelease];
} /*trimWhiteSpace*/



+ (BOOL) stringIsEmpty: (NSString *) s {
    
    NSString *copy;
    
    if (s == nil)
        return (YES);
    
    if ([s isEqualTo: @""])
        return (YES);
    
    copy = [[s copy] autorelease];
    
    if ([[copy trimWhiteSpace] isEqualTo: @""])
        return (YES);
    
    return (NO);
} /*stringIsEmpty*/
@end
