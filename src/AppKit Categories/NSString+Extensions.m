#import "NSString+Extensions.h"
#define NSLogDebug NSLog
#import "XJPreferences.h"
#import <OgreKit/OgreKit.h>

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
	NSString *replacementString = [NSString stringWithFormat: @"<nobr><a href=\"http://www.livejournal.com/userinfo.bml?user=\\1\"><img height=\"17\" border=\"0\" src=\"%@\" align=\"absmiddle\" width=\"17\"></a><b><a href=\"http://www.livejournal.com/users/\\1/\">\\1</a></b></nobr>", [XJPreferences userIconURL]];
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: @"<lj user=\"([A-Za-z0-9_]*)\" ?/?>"];
	return [regex replaceAllMatchesInString: self withString: replacementString];
}

- (NSString *)translateLJComm
{
	NSString *replacementString = [NSString stringWithFormat: @"<nobr><a href=\"http://www.livejournal.com/userinfo.bml?user=\\1\"><img height=\"17\" border=\"0\" src=\"%@\" align=\"absmiddle\" width=\"17\"></a><b><a href=\"http://www.livejournal.com/community/\\1/\">\\1</a></b></nobr>", [XJPreferences communityIconURL]];
	
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: @"<lj comm=\"([A-Za-z0-9_]*)\">"];
	return [regex replaceAllMatchesInString: self withString: replacementString];
}


- (NSString *)translateLJCutOpenTagWithText
{
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: @"<lj-cut text=\"([^>]*)\">"];
	return [regex replaceAllMatchesInString: self withString: @"<div class=\"xjljcut\">LJ-Cut: \\1</div>"];
}

- (NSString *)translateBasicLJCutOpenTag
{
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: @"<lj-cut>"];
	return [regex replaceAllMatchesInString: self withString: @"<div class=\"xjljcut\">LJ-Cut</div>"];
}

- (NSString *)translateLJCutCloseTag
{
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: @"</lj-cut>"];
	return [regex replaceAllMatchesInString: self withString: @"<br><div class=\"xjljcut\">&nbsp;</div>"];
}

- (NSString *)translateLJPoll
{
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: @"<lj-poll-([^>]*)>"];
	return [regex replaceAllMatchesInString: self withString: @"<a href=\"http://www.livejournal.com/poll/?id=\\1\">LJ-Poll ID: \\1</a>"];
}

- (NSString *)translateLJPhonePostWithItemURL:(NSString *)url userName: (NSString *)user{
	NSString *replacementString = [NSString stringWithFormat: @"<a href=\"http://files.livejournal.com/%@/phonepost/\\2.ogg\">PhonePost</a> (<a href=\"http://www.livejournal.com/phonepost/transcribe.bml?user=%@&ppid=\\2\">transcribe</a>)<br><br><a href=\"%@\">View PhonePost Online</a>", user, user, url];
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: @"<lj-phonepost journalid='([^']*)' dpid='([^']*)' />"];
	return [regex replaceAllMatchesInString: self withString: replacementString];
	
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
