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
