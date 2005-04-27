//
//  LJPoll.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPoll.h"


@implementation LJPoll
+ (void)initialize {
	NSArray *keys = [NSArray arrayWithObjects: @"votingPermissions", @"viewingPermissions", @"name", @"questions", nil];
	[self setKeys: keys triggerChangeNotificationsForDependentKey: @"htmlRepresentation"];
}

- (id)init
{
    if([super init] == nil)
        return nil;
    
    questions = [[NSMutableArray arrayWithCapacity: 30] retain];
    name = @"NewPoll";
	
    return self;
}

- (void)dealloc
{
    [name release];
    [questions release];
    [super dealloc];
}

- (NSString *)name { return name; }
- (void)setName: (NSString *)newName
{
    name = [newName copy];
}

- (int)votingPermissions { return whoVote; }
- (void)setVotingPermissions: (int)newPerms { whoVote = newPerms; }

- (int)viewingPermissions { return whoView; }
- (void)setViewingPermissions: (int)newPerms { whoView = newPerms; }

	//=========================================================== 
	// - questions:
	//=========================================================== 
- (NSMutableArray *)questions {
    return questions; 
}

//=========================================================== 
// - setQuestions:
//=========================================================== 
- (void)setQuestions:(NSMutableArray *)aQuestions {
    [aQuestions retain];
    [questions release];
    questions = aQuestions;
}

///////  questions  ///////

- (unsigned int)countOfQuestions 
{
    return [[self questions] count];
}

- (id)objectInQuestionsAtIndex:(unsigned int)index 
{
    return [[self questions] objectAtIndex:index];
}

- (void)insertObject:(id)anObject inQuestionsAtIndex:(unsigned int)index 
{
    [[self questions] insertObject:anObject atIndex:index];
}

- (void)removeObjectFromQuestionsAtIndex:(unsigned int)index 
{
    [[self questions] removeObjectAtIndex:index];
}

- (void)replaceObjectInQuestionsAtIndex:(unsigned int)index withObject:(id)anObject 
{
    [[self questions] replaceObjectAtIndex:index withObject:anObject];
}
- (NSString *)htmlRepresentation
{
    NSMutableString *buf = [[NSMutableString stringWithCapacity: 100] retain];
    NSEnumerator *enu = [questions objectEnumerator];
    LJPollQuestion *ques;
	
    [buf appendString: @"<lj-poll"];
	
    // Append name
    [buf appendString: @" name=\""];
    if(name)
        [buf appendString: name];
    [buf appendString: @"\""];
	
    // Append voting permission property
    [buf appendString: @" whovote=\""];
    switch(whoVote) {
        case LJPollAllVote:
            [buf appendString: @"all"];
            break;
        case LJPollFriendsVote:
            [buf appendString: @"friends"];
            break;
    }
    [buf appendString: @"\""];
	
    // Append viewing permission property
    [buf appendString: @" whoview=\""];
    switch(whoView) {
        case LJPollAllView:
            [buf appendString: @"all"];
            break;
        case LJPollFriendsView:
            [buf appendString: @"friends"];
            break;
        case LJPollNoneView:
            [buf appendString: @"none"];
            break;
    }
    [buf appendString: @"\""];
    
    
    [buf appendString: @">\n\n"];
    
    while(ques = [enu nextObject]) {
        [buf appendString: [ques htmlRepresentation]];
        [buf appendString: @"\n\n"];
    }
    [buf appendString: @"</lj-poll>"];
    return [buf autorelease];
}
@end
