//
//  LJPollRadioQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollMultipleOptionQuestion.h"

#define kMultipleOptionType @"LJMultipleOptionType"
#define kMultipleOptionAnswerArray @"LJMultipleOptionAnswerArray"

@implementation LJPollMultipleOptionQuestion {
    NSMutableArray *answers;
}
@synthesize type;

+ (LJPollMultipleOptionQuestion *)questionOfType: (LJPollMultipleOptionType)questionType
{
    return [[self alloc] initWithType:questionType];
}

- (instancetype)init
{
    return [self initWithType:LJPollRadioType];
}

- (instancetype)initWithType:(LJPollMultipleOptionType)questionType
{
    if (self = [super init]) {
        type = questionType;
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
    answers[idx] = answer;
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
    
    [buf appendString: self.question];
    [buf appendString: @"\n"];

    NSEnumerator *enu = [answers objectEnumerator];
    NSString *ans;
    while(ans = [enu nextObject]) {
        [buf appendString: @"<lj-pi>"];
        [buf appendString: ans];
        [buf appendString: @"</lj-pi>\n"];
    }
    
    [buf appendString: @"</lj-pq>"];
    
    return [NSString stringWithString: buf];
}

#pragma mark Memento Pattern
- (NSDictionary *) memento
{
    NSDictionary *dict = @{kLJPollQuestionKey: self.question,
                           kMultipleOptionType: @(type),
                           kMultipleOptionAnswerArray: [answers copy]};
	
	return dict;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    self.question = memento[kLJPollQuestionKey];
    self.type = [memento[kMultipleOptionType] integerValue];

    [self deleteAllAnswers];
    
    for (NSString *object in memento[kMultipleOptionAnswerArray]) {
        [self addAnswer:object];
    }
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder: encoder];
    [encoder encodeInteger: type forKey: kMultipleOptionType];
    [encoder encodeObject: answers forKey: kMultipleOptionAnswerArray];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder: decoder]) {
        answers = [decoder decodeObjectForKey: kMultipleOptionAnswerArray];
        type = [decoder decodeIntegerForKey: kMultipleOptionType];
    }
    return self;
}
@end
