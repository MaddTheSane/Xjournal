//
//  LJPollTextEntryQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollTextEntryQuestion.h"


@implementation LJPollTextEntryQuestion
@synthesize size;
@synthesize maxLength;

+ (LJPollTextEntryQuestion *)textEntryQuestionWithSize: (NSInteger)theSize maxLength: (NSInteger)theLength
{
    LJPollTextEntryQuestion *teQ = [[LJPollTextEntryQuestion alloc] init];
    [teQ setQuestion: @"New Text Question"];
    teQ.size = theSize;
    teQ.maxLength = theLength;

    return teQ;
}

- (NSString *)htmlRepresentation
{
    return [NSString stringWithFormat: @"<lj-pq type=\"text\" size=\"%ld\" maxlength=\"%ld\">%@</lj-pq>", (long)size, (long)maxLength, theQuestion];
}

// Memento
- (NSDictionary *) memento
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"LJPollQuestion"] = [[self question] copy];
    dictionary[@"LJPollTextSize"] = @([self size]);
    dictionary[@"LJPollTextLength"] = @([self maxLength]);

    return dictionary;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    [self setQuestion: memento[@"LJPollQuestion"]];
    [self setSize: [memento[@"LJPollTextSize"] integerValue]];
    [self setMaxLength: [memento[@"LJPollTextLength"] integerValue]];
}

// ----------------------------------------------------------------------------------------
// NSCoding
// ----------------------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeInteger: maxLength forKey: @"LJPollTextLength"];
        [encoder encodeInteger: size forKey: @"LJPollTextSize"];

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

        maxLength = [decoder decodeIntegerForKey: @"LJPollTextLength"];
        size = [decoder decodeIntegerForKey: @"LJPollTextSize"];
    }
    return self;
}
@end
