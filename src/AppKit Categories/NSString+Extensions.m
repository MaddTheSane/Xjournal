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
}

- (NSString *)convertNewlinesToBR {
	NSMutableString *newString = [[NSMutableString stringWithCapacity: [self length]] retain];
    [newString appendString: self];
	
    [newString replaceOccurrencesOfString: @"\n" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
    [newString replaceOccurrencesOfString: @"\r" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
//    [newString replaceOccurrencesOfString: @"\r\n" withString: @"<br>" options: NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
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

/*
 http://connectedflow.com:9010/xjournal/ticket/72
 Ticket 72:
 tables render improperly
 
 The solution to the issue of not cleaning CRs in tables becomes tricky when you remember that
 table tags can be nested. Therefore you can't simply wait for the next </table>
 
 This algorithm basically kills all CR to <br /> conversion within the scope of <table> tags.
 
 It does so by blowing up the string into an array and then tracking 'table tag depth'
 
 The function will ignore the table tags if there is a misbalance of table tags.
 */
- (NSString *)translateNewLinesOutsideTables
{
	int		tableDepth = 0;
	int		sectionCount = 0;
	BOOL	error = NO;

	NSString 		*loadString = [NSString stringWithString:self];
	NSArray 		*firstArray = [loadString componentsSeparatedByString:@"<table"];
	NSMutableArray	*returnBuildArray = [NSMutableArray arrayWithCapacity:[firstArray count]];
	NSString 		*finishedWork;
	NSString 		*textBlob;
	NSEnumerator	*dataWalker;
	NSString		*measureString;	// this is an annoying string to type cast array objects so I don't get warnings.
	
	// if we find no tables then just convert the whole thing
	if ([firstArray count] == 1) {
		return [self translateNewLines];
	}
	
	// If first element = 0 length, text begins with <table, so discard first element. It is empty anyway
	measureString = [firstArray objectAtIndex:0];
	if ([measureString length] == 0) {
		NSMutableArray *choppingArrray;

		[returnBuildArray addObject:@""];
		tableDepth ++;
		choppingArrray = [NSMutableArray  arrayWithArray:firstArray];
		[choppingArrray removeObjectAtIndex:0];
		firstArray = [NSArray arrayWithArray:choppingArrray];
	}
	
	dataWalker = [firstArray objectEnumerator];
	while (textBlob = [dataWalker nextObject]) {
		NSArray			*secondArray;
		int				sACount;
		NSMutableArray	*secondBuildArray;
		sectionCount++;
		if ((sectionCount == [firstArray count]) && ([textBlob length] == 0)) {
			NSLog(@"Error: Mismatched <table> - </table> count! Too many <table>");
			error = YES;
			break;
		}
		
		secondArray = [textBlob componentsSeparatedByString:@"/table>"];
		sACount = [secondArray count];
		secondBuildArray = [NSMutableArray arrayWithArray:secondArray];

		if (sACount > tableDepth) {
			NSString *correctedSection =@"";

			if ((sACount - tableDepth) > 1) {
				NSLog(@"Error: Mismatched <table> - </table> count! Too many </table>");
				error = YES;
				break;
			}
			
			measureString  = [secondArray lastObject];
			if ([measureString length] == 0) {
				// By not dropping this section we have [foo, nil]
				// the array builder will reinsert /table> leaving us with:
				// foo/table>nil
			} else {
				// We have a section that should be converted
				correctedSection = [[secondArray lastObject] translateNewLines];
				[secondBuildArray removeLastObject];
				[secondBuildArray addObject:correctedSection];				
			}
			
			if (sACount > 1) {
				[returnBuildArray addObject:[secondBuildArray componentsJoinedByString:@"/table>"]];
			} else {
				[returnBuildArray addObject:correctedSection];
			}
		} else {
			if (sACount > 1) {
				[returnBuildArray addObject:[secondBuildArray componentsJoinedByString:@"/table>"]];
			} else {
				[returnBuildArray addObject:textBlob];
			}
		}
		tableDepth -= ([secondArray count] - 1);
		
		tableDepth++;
	}
	
	
	if (error) {
		finishedWork = [self translateNewLines];
	} else {
		if ([returnBuildArray count] > 1) {
			finishedWork = [returnBuildArray componentsJoinedByString:@"<table"];
		} else {
			finishedWork = loadString;
		}
	}
	
	return finishedWork;
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
