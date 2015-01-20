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
    if([super init] == nil)
        return nil;
    
    [self setQuestion: @"New Question"];
    [self setType: LJPollRadioType];
    answers = [[NSMutableArray arrayWithCapacity: 10] retain];
    
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

- (int)numberOfAnswers
{
    return [answers count];
}

- (NSString *)answerAtIndex: (int)idx
{
    return [answers objectAtIndex:idx];
}

- (void)setAnswer:(NSString *)answer atIndex: (int)idx
{
    [answers removeObjectAtIndex: idx];
    [answers insertObject: answer atIndex: idx];
}

- (void)addAnswer:(NSString *)answer
{
    [answers addObject: answer];
}

// Insert the question at the given index
- (void)insertAnswer: (NSString *)answer atIndex:(int)idx
{
    [answers insertObject: answer atIndex: idx];
}

- (void)deleteAnswerAtIndex: (int)idx
{
    [answers removeObjectAtIndex: idx];
}

// Deletes all the answers
- (void)deleteAllAnswers
{
    [answers release];
    answers = [[NSMutableArray arrayWithCapacity: 30] retain];
}

- (void)moveAnswerAtIndex: (int) idx toIndex: (int) newIdx
{
    if(newIdx == idx) return;
    if(newIdx < 0 || newIdx >= [answers count]) return;

    id obj = [[answers objectAtIndex: idx] retain];
    [answers removeObjectAtIndex: idx];
    [answers insertObject: obj atIndex: newIdx];
    [obj release];
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
    NSString *ans;
    while(ans = [enu nextObject]) {
        [buf appendString: @"<lj-pi>"];
        [buf appendString: ans];
        [buf appendString: @"</lj-pi>\n"];
    }
    
    [buf appendString: @"</lj-pq>"];
    
    return [buf autorelease];
}

// Memento
- (NSDictionary *) memento
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    NSDictionary *tempQuestion = [[self question] copy];
    [dictionary setObject: tempQuestion forKey: @"LJPollQuestion"];
    [tempQuestion release];

    [dictionary setObject: [NSNumber numberWithInt: [self type]] forKey: @"LJMultipleOptionType"];

    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [answers objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        [array addObject: object];
        [object release];
    }

    [dictionary setObject: array forKey: @"LJMultipleOptionAnswerArray"];
    return dictionary;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    [self setQuestion: [memento objectForKey: @"LJPollQuestion"]];
    [self setType: [[memento objectForKey: @"LJMultipleOptionType"] intValue]];

    [self deleteAllAnswers];
    NSEnumerator *enumerator = [[memento objectForKey: @"LJMultipleOptionAnswerArray"] objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        [self addAnswer: object];
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
