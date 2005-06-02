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

@implementation NSString (WhiteSpaceExt)
- (NSString *)stringByRemovingSurroundingWhitespace
{
    static NSCharacterSet *nonWhitespace = nil;
    NSRange firstValidCharacter, lastValidCharacter;
    if (!nonWhitespace) {
        nonWhitespace = [[[NSCharacterSet characterSetWithCharactersInString: @" \t\r\n"] invertedSet] retain];
    }

    firstValidCharacter = [self rangeOfCharacterFromSet:nonWhitespace];
    if (firstValidCharacter.length == 0)
	return @"";
    lastValidCharacter = [self rangeOfCharacterFromSet:nonWhitespace options:NSBackwardsSearch];

    if (firstValidCharacter.location == 0 && lastValidCharacter.location == [self length] - 1)
	return self;
    else
	return [self substringWithRange:NSUnionRange(firstValidCharacter, lastValidCharacter)];
}
@end

@implementation NSString (ConstainsString)
- (BOOL) containsString: (NSString *) myString
{
    return ([self rangeOfString: myString].location != NSNotFound);
}
@end

@implementation NSString (HtmlCodec)
- (NSString *) encodeAsHtml {
    NSMutableString *buf = [NSMutableString stringWithString: self];
    NSMutableString *escapedString = [NSMutableString string];

    int i = 0;
    int size = [self length];
    unsigned int ch;
    int pos = 0;

    for (i = 0; i < size; i++) {
        ch = [self characterAtIndex: i];

        // HTML unicode char entities values can be seen at
        // taken from http://www.w3.org/TR/REC-html32#latin1
        // and http://www.w3.org/TR/html4/sgml/entities.html
        if (ch > 126) {
            [escapedString setString: @"&#"];
            [escapedString appendString: [[NSNumber numberWithUnsignedInt: ch] stringValue] ];
            [escapedString appendString: @";"];

            [buf replaceCharactersInRange:NSMakeRange(pos, 1) withString: escapedString];

            // we move up pos depending on how many digits are in the escaped html
            // (base of 3 digits for "&#" and ";")
            if (ch < 1000) {
                pos += 6; // 3 digits
            } else if (ch < 10000) {
                pos += 7; // 4 digits
            } else {
                pos += 8; // 5 digits
            }

        } else {
            pos++;
        }
    }

    return buf;
}

- (NSString *) decodeHtml {
    NSMutableString *buf = [NSMutableString string];

    int i,j,copiedUpTo = 0;
    int textSize = [self length];
    unsigned int ch;
    int length;
    NSRange escapedRange;
    int endMarkerFound = false;
    unichar uch;

    while (1) {
        if (copiedUpTo > textSize) {
            break;
        }

        // keep searching for a &# substring...
        escapedRange = [self rangeOfString: @"&#" options: 0 range: NSMakeRange (copiedUpTo, textSize - copiedUpTo)];

        if (escapedRange.location == NSNotFound) {
            // no more escaped chars...
            [buf appendString: [self substringFromIndex: copiedUpTo]];

            break;  // move along we're done

        } else {
            // first copy everything up to the &#
            [buf appendString: [self substringWithRange: NSMakeRange (copiedUpTo, escapedRange.location - copiedUpTo)]];
            copiedUpTo = escapedRange.location;
            length = 0;

            // make sure this isn't coming at the end of our string
            if (copiedUpTo + 2 < textSize) {
                j = MIN (textSize, copiedUpTo + 8);

                // we've gots to pull out the next few numbered chars
                for (i = copiedUpTo + 2; i < j; i++) {
                    ch = [self characterAtIndex: i];

                    // parse the next char
                    if (ch == ';') {
                        // found the end marker
                        endMarkerFound = true;
                    } else if (ch >= '0' && ch <= '9') {
                        // got another digit
                        length++;
                    } else {
                        // not a digit or ';', so we're done
                        break;
                    }
                }
            } else {
                i = textSize;
            }

            // did we find the end-marker and we have atleast 3 digits
            if (endMarkerFound && length >= 3) {
                // get the int (unichar) value of this number
                uch = [[self substringWithRange: NSMakeRange (copiedUpTo + 2, length)] intValue];

                // make the number into a string
                [buf appendString: [NSString stringWithCharacters: &uch length: 1]];

                // update copied up to
                copiedUpTo = copiedUpTo + 2 + length + 1; // includes the &# and ;

            } else {
                // copy up to i
                [buf appendString: [self substringWithRange: NSMakeRange (copiedUpTo, i - copiedUpTo)]];

                copiedUpTo = i;
            }

            endMarkerFound = 0; // clear the end marker
        }
    }

    return buf;
} 

- (NSString *) urlEncodeASCII
{
    NSMutableString *buf = [NSMutableString stringWithString: [self encodeAsHtml]];
    NSMutableString *escapedString = [NSMutableString string];
    unsigned int ch;
    int pos = 0;

    for (pos = 0; pos < [buf length]; ) {
        ch = [buf characterAtIndex: pos];

        if ((ch >= 'a' && ch <= 'z') || 
            (ch >= 'A' && ch <= 'Z') ||
            (ch >= '0' && ch <= '9')) {
                pos++;
        } else if (ch == ' ') {
            [escapedString setString: @"+"];
            [buf replaceCharactersInRange: NSMakeRange(pos, 1) withString: escapedString];
            pos++;
        } else {
            [escapedString setString: @"%"];
            [escapedString appendString: [NSString stringWithFormat: @"%02X", ch]];
            [buf replaceCharactersInRange:NSMakeRange(pos, 1) withString: escapedString];
            pos+=3;
        }
    }

    return buf;
}

- (NSString *) urlEncode:(BOOL) useUTF8
{
    if (! useUTF8) {
        return [self urlEncodeASCII];
    } else {
        NSMutableString *buf = [NSMutableString stringWithString: self];
        NSMutableString *escapedString = [NSMutableString string];
        unsigned int pos;

        for (pos = 0; pos < [buf length];) {
            if (([[NSCharacterSet alphanumericCharacterSet] characterIsMember:
                [buf characterAtIndex: pos]])
                && ([[buf substringWithRange: NSMakeRange(pos, 1)] canBeConvertedToEncoding: NSASCIIStringEncoding])) {
                pos++;
            } else {
                const char *utf8In = [[buf substringWithRange: NSMakeRange(pos, 1)] UTF8String];
                int i;

                [escapedString setString: @""];

                for (i = 0; i < strlen(utf8In); i++) {
                    [escapedString appendString: [NSString stringWithFormat: @"%%%02X",
                        (unsigned char) utf8In[i]]];
                }
                [buf replaceCharactersInRange:NSMakeRange(pos, 1) withString: escapedString];
                pos+=(i * 3);
            }
        }

        return buf;
    }
}


- (NSString *) urlDecode:(BOOL) useUTF8
{
    if (! useUTF8) {
        return [self urlDecodeASCII];
    } else {
        NSMutableString *decoded;
        NSMutableString *decodedSpaces;

        // first convert the +'s back into whitespaces
        decodedSpaces = [NSMutableString stringWithString:self];
        [decodedSpaces replaceOccurrencesOfString:@"+"
                                       withString:@" "
                                          options:nil
                                            range:NSMakeRange(0, [self length])];

        // then convert all the %-escaped sequences back into unichars
        decoded = [NSMutableString stringWithString:
            (NSString *) CFURLCreateStringByReplacingPercentEscapes(NULL,
                                                                    (CFStringRef) decodedSpaces,
                                                                    CFSTR(""))];

        return decoded;
    }
}

- (NSString *) urlDecodeASCII
{
    NSMutableString *buf = [NSMutableString stringWithString: self];
    NSMutableString *escapedString = [NSMutableString string];
    unsigned int pos;
    unsigned int ch;

    for (pos=0; pos < [buf length]; pos++)
    {
        ch = [buf characterAtIndex: pos];
        if (ch == '%') {
            // read 2 more characters
            unsigned char chrs[4];
            unsigned int replacement = 0;
            [[buf substringWithRange: NSMakeRange(pos+1, 2)] getCString: chrs];

            replacement = 16 * (isalpha(chrs[0]) ? 10 + (toupper(chrs[0]) - 'A') : (chrs[0] - '0'));
            replacement += (isalpha(chrs[1]) ? 10 + (toupper(chrs[1]) - 'A') : (chrs[1] - '0')) ;
            [escapedString setString: [NSString stringWithFormat:@"%c", replacement]];
            [buf replaceCharactersInRange: NSMakeRange(pos, 3) withString: escapedString];
        } else if (ch == '+') {
            [escapedString setString: @" "];
            [buf replaceCharactersInRange: NSMakeRange(pos, 1) withString: escapedString];
        }
    }

    return [buf decodeHtml];
}

@end

@implementation NSString (LJCutConversions)

- (NSString *)translateNewLines
{
	NSMutableString *newString = [[NSMutableString stringWithCapacity: [self length]] retain];	 
    [newString appendString: self];

	[newString replaceOccurrencesOfString: @"\r\n" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    [newString replaceOccurrencesOfString: @"\n" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    [newString replaceOccurrencesOfString: @"\r" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
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
	
	[newString replaceOccurrencesOfString: @"\r\n" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
	[newString replaceOccurrencesOfString: @"\n" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    [newString replaceOccurrencesOfString: @"\r" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    return [newString autorelease];
}

- (NSString *)translateLJUser
{
    AGRegex *userRegex = [[AGRegex alloc] initWithPattern:@"<lj user=\"([A-Za-z0-9_]*)\">" options:0];
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

/*
 - (NSString *)translateLJCutBlockWithItemURL: (NSString *)url
{
    AGRegex *blockRegex = [[AGRegex alloc] initWithPattern:@"<lj-cut text=\"(.*)\">(.*)</lj-cut>" options:0];
    NSString *result = [blockRegex replaceWithString: @"<div class=\"xjljcut\"> LJ-Cut:&nbsp;<b>$1</b></div><br>$2<br><div class=\"xjljcut\">&nbsp;</div>" inString: self];
    [blockRegex release];
    return result;
}
*/

- (NSString *)translateLJCutOpenTagWithText
{
    /*
     AGRegex *blockRegex = [[AGRegex alloc] initWithPattern:@"<lj-cut text=\"([^<]*)\">([\\D\\d]*)" options:0];
    NSString *result = [blockRegex replaceWithString: @"<div class=\"xjljcut\"> LJ-Cut:&nbsp;<b>$1</b></div>$2" inString: self];
    [blockRegex release];
    return result;
     */
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
    //AGRegex *blockRegex = [[AGRegex alloc] initWithPattern:@"<lj-phonepost user='([^']*)' phonepostid='([^']*)' />" options:0];
    
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


- (NSString *) ellipsizeAfterNWords: (int) n {
    
    NSArray *stringComponents = [self componentsSeparatedByString: @" "];
    NSMutableArray *componentsCopy = [stringComponents mutableCopy];
    int ix = n;
    int len = [componentsCopy count];
    
    if (len < n)
        ix = len;
    
    [componentsCopy removeObjectsInRange: NSMakeRange (ix, len - ix)];
    
    return [componentsCopy componentsJoinedByString: @" "];
} /*ellipsizeAfterNWords*/


- (NSString *) stripHTML {
    
    int len = [self length];
    NSMutableString *s = [NSMutableString stringWithCapacity: len];
    int i = 0, level = 0;
    
    for (i = 0; i < len; i++) {
        
        NSString *ch = [self substringWithRange: NSMakeRange (i, 1)];
        
        if ([ch isEqualTo: @"<"])
            level++;
        
        else if ([ch isEqualTo: @">"]) {
            
            level--;
            
            if (level == 0)			
                [s appendString: @" "];
        } /*else if*/
		
		else if (level == 0)			
                    [s appendString: ch];
    } /*for*/
	
	return (NSString *) [[s copy] autorelease];
} /*stripHTML*/


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

@implementation NSString (Technorati)
- (NSString *)technoratiTags {
	NSMutableString *html = [[NSMutableString alloc] init];
	NSArray *tagnames = [[self componentsSeparatedByString: @" "] sortedArrayUsingSelector: @selector(compare:)];
	
	NSEnumerator *en = [tagnames objectEnumerator];
	NSString *tag;
	while(tag = [en nextObject]) {
		if([html length] != 0)
			[html appendString: @" "];
		
		NSString *tagString = [NSString stringWithFormat: @"<a rel=\"tag\" href=\"http://www.technorati.com/tags/%@\">%@</a>", tag, tag];
		[html appendString: tagString];
	}
	
	return [html autorelease];
}
@end