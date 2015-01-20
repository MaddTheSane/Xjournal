//
//  LJPollScaleQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollScaleQuestion.h"


@implementation LJPollScaleQuestion
@synthesize start;
@synthesize end;
@synthesize step;

+ (LJPollScaleQuestion *)scaleQuestionWithStart: (int)theStart end: (int)theEnd step:(int)theStep
{
    LJPollScaleQuestion *scale = [[LJPollScaleQuestion alloc] init];
    [scale setQuestion: @"New Question"];
    [scale setStart: theStart];
    [scale setEnd: theEnd];
    [scale setStep: theStep];

    return scale;
}

- (NSString *)htmlRepresentation
{
    return [NSString stringWithFormat: @"<lj-pq type=\"scale\" from=\"%d\" to=\"%d\" by=\"%d\">%@</lj-pq>", start, end, step, theQuestion];
}

// Memento
- (NSDictionary *) memento
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"LJPollQuestion"] = [[self question] copy];
    dictionary[@"LJPollScaleStart"] = @([self start]);
    dictionary[@"LJPollScaleEnd"] = @([self end]);
    dictionary[@"LJPollScaleStep"] = @([self step]);

    return dictionary;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    [self setQuestion: memento[ @"LJPollQuestion"]];
    [self setStart: [memento[ @"LJPollScaleStart"] intValue]];
    [self setEnd: [memento[ @"LJPollScaleEnd"] intValue]];
    [self setStep: [memento[ @"LJPollScaleStep"] intValue]];
}

// ----------------------------------------------------------------------------------------
// NSCoding
// ----------------------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeInt: start forKey:@"LJPollScaleStart"];
        [encoder encodeInt: end forKey:@"LJPollScaleEnd"];
        [encoder encodeInt: step forKey:@"LJPollScaleStep"];

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
        
        start = [decoder decodeIntForKey: @"LJPollScaleStart"];
        end = [decoder decodeIntForKey: @"LJPollScaleEnd"];
        step = [decoder decodeIntForKey: @"LJPollScaleStep"];
    }
    return self;
}
@end
