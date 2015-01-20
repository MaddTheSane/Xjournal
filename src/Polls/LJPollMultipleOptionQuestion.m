//
//  LJPollRadioQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollMultipleOptionQuestion.h"


@implementation LJPollMultipleOptionQuestion
@synthesize type;

+ (LJPollMultipleOptionQuestion *)questionOfType: (LJPollMultipleOptionType)questionType
{
    LJPollMultipleOptionQuestion *mo_question = [[LJPollMultipleOptionQuestion alloc] init];
    [mo_question setType:questionType];
    
    return mo_question;
}

- (instancetype)init
{
    if (self = [super init]) {
    
    [self setQuestion: @"New Question"];
    [self setType: LJPollRadioType];
    answers = [[NSMutableArray alloc] initWithCapacity: 10];
    }
    return self;
}

- (NSInteger)numberOfAnswers
{
    return [answers count];
}

- (NSString *)answerAtIndex: (NSInteger)idx
{
    return answers[idx];
}

- (void)setAnswer:(NSString *)answer atIndex: (NSInteger)idx
{
    [answers removeObjectAtIndex: idx];
    [answers insertObject: answer atIndex: idx];
}

- (void)addAnswer:(NSString *)answer
{
    [answers addObject: answer];
}

// Insert the question at the given index
- (void)insertAnswer: (NSString *)answer atIndex:(NSInteger)idx
{
    [answers insertObject: answer atIndex: idx];
}

- (void)deleteAnswerAtIndex: (NSInteger)idx
{
    [answers removeObjectAtIndex: idx];
}

- (void)deleteAnswersAtIndexes:(NSIndexSet*)idx
{
	[answers removeObjectsAtIndexes:idx];
}

// Deletes all the answers
- (void)deleteAllAnswers
{
	[answers removeAllObjects];
}

- (void)moveAnswerAtIndex: (NSInteger) idx toIndex: (NSInteger) newIdx
{
    if(newIdx == idx) return;
    if(newIdx < 0 || newIdx >= [answers count]) return;

    id obj = answers[idx];
    [answers removeObjectAtIndex: idx];
    [answers insertObject: obj atIndex: newIdx];
}

- (NSString *)htmlRepresentation
{
    NSMutableString *buf = [NSMutableString stringWithCapacity: 100];

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
    
    return buf;
}

// Memento
- (NSDictionary *) memento
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    NSDictionary *tempQuestion = [[self question] copy];
    dictionary[@"LJPollQuestion"] = tempQuestion;

    dictionary[@"LJMultipleOptionType"] = @([self type]);

    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [answers objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        [array addObject: object];
    }

    dictionary[@"LJMultipleOptionAnswerArray"] = array;
    return dictionary;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    [self setQuestion: memento[@"LJPollQuestion"]];
    [self setType: [memento[@"LJMultipleOptionType"] intValue]];

    [self deleteAllAnswers];
    NSEnumerator *enumerator = [memento[@"LJMultipleOptionAnswerArray"] objectEnumerator];
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
        [encoder encodeInt: type forKey:@"LJMultipleOptionType"];
        [encoder encodeObject: answers forKey:@"LJMultipleOptionAnswerArray"];
        [encoder encodeObject: [self question] forKey:@"LJPollQuestion"];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"LJKit requires keyed coding."];
    }
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        [self setQuestion: [decoder decodeObjectForKey:@"LJPollQuestion"]];
        answers = [decoder decodeObjectForKey: @"LJMultipleOptionAnswerArray"];
        type = [decoder decodeIntForKey:@"LJMultipleOptionType"];
    }
    return self;
}
@end
