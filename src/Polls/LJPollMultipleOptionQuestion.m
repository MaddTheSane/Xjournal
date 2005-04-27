//
//  LJPollRadioQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollMultipleOptionQuestion.h"


@implementation LJPollMultipleOptionQuestion
+ (LJPollMultipleOptionQuestion *)questionOfType: (int)questionType
{
    LJPollMultipleOptionQuestion *mo_question = [[LJPollMultipleOptionQuestion alloc] init];
    [mo_question setType:questionType];
    
    return [mo_question autorelease];
}

- (id)init
{
	self = [super init];
	if(self) {
		[self setQuestion: @"Multiple Choice Question"];
		[self setType: LJPollRadioType];
		[self setAnswers: [NSMutableArray array]];
	}
    return self;
}

- (void)dealloc
{
    [answers release];
    [super dealloc];
}

- (int)type
{
    return type;
}

- (void)setType:(int)newType
{
    type = newType;
}

- (NSString *)htmlRepresentation
{
    NSMutableString *buf = [[NSMutableString stringWithCapacity: 100] retain];

    if(type == LJPollRadioType)
        [buf appendString: @"<lj-pq type=\"radio\">\n"];
    else if(type == LJPollCheckBoxType)
        [buf appendString: @"<lj-pq type=\"check\">\n"];
    else
        [buf appendString: @"<lj-pq type=\"drop\">\n"];
    
    [buf appendString: theQuestion];
    [buf appendString: @"\n"];

    NSEnumerator *enu = [answers objectEnumerator];
    NSDictionary *ans;
    while(ans = [enu nextObject]) {
        [buf appendString: @"<lj-pi>"];
        [buf appendString: [ans objectForKey: @"answerText"]];
        [buf appendString: @"</lj-pi>\n"];
    }
    
    [buf appendString: @"</lj-pq>"];
    
    return [buf autorelease];
}

//=========================================================== 
//  answers 
//=========================================================== 
- (NSMutableArray *)answers {
    return answers; 
}
- (void)setAnswers:(NSMutableArray *)anAnswers {
    [anAnswers retain];
    [answers release];
    answers = anAnswers;
}

// Memento
- (NSDictionary *) memento
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    [dictionary setObject: [[self question] copy] forKey: @"LJPollQuestion"];
    [dictionary setObject: [NSNumber numberWithInt: [self type]] forKey: @"LJMultipleOptionType"];

    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [answers objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        [array addObject: [object copy]];
    }

    [dictionary setObject: array forKey: @"LJMultipleOptionAnswerArray"];
    return dictionary;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    [self setQuestion: [memento objectForKey: @"LJPollQuestion"]];
    [self setType: [[memento objectForKey: @"LJMultipleOptionType"] intValue]];

    [self setAnswers: [NSMutableArray array]];
    NSEnumerator *enumerator = [[memento objectForKey: @"LJMultipleOptionAnswerArray"] objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        [[self mutableArrayValueForKey:@"answers"] addObject: object];
    }
}

// ----------------------------------------------------------------------------------------
// NSCoding
// ----------------------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject: [NSNumber numberWithInt: type] forKey:@"LJMultipleOptionType"];
        [encoder encodeObject: answers forKey:@"LJMultipleOptionAnswerArray"];
        [encoder encodeObject: [self question] forKey:@"LJPollQuestion"];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"LJKit requires keyed coding."];
    }
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        [self setQuestion: [decoder decodeObjectForKey:@"LJPollQuestion"]];
        answers = [decoder decodeObjectForKey: @"LJMultipleOptionAnswerArray"];
        type = [[decoder decodeObjectForKey: @"LJMultipleOptionType"] intValue];
    }
    return self;
}
@end
