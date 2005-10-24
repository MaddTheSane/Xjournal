//
//  LJPollScaleQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollScaleQuestion.h"


@implementation LJPollScaleQuestion
+ (LJPollScaleQuestion *)scaleQuestionWithStart: (int)theStart end: (int)theEnd step:(int)theStep
{
    LJPollScaleQuestion *scale = [[LJPollScaleQuestion alloc] init];
    [scale setQuestion: @"New Question"];
    [scale setStart: theStart];
    [scale setEnd: theEnd];
    [scale setStep: theStep];

    return [scale autorelease];
}

- (int)start { return start; }
- (void)setStart: (int)newValue { start = newValue; }

- (int)end { return end; }
- (void)setEnd: (int)newValue { end = newValue; }

- (int)step { return step; }
- (void)setStep: (int)newValue { step = newValue; }

- (NSString *)htmlRepresentation
{
    return [NSString stringWithFormat: @"<lj-pq type=\"scale\" from=\"%d\" to=\"%d\" by=\"%d\">%@</lj-pq>", start, end, step, theQuestion];
}

// Memento
- (NSDictionary *) memento
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject: [[self question] copy] forKey: @"LJPollQuestion"];
    [dictionary setObject: [NSNumber numberWithInt: [self start]] forKey: @"LJPollScaleStart"];
    [dictionary setObject: [NSNumber numberWithInt: [self end]] forKey: @"LJPollScaleEnd"];
    [dictionary setObject: [NSNumber numberWithInt: [self step]] forKey: @"LJPollScaleStep"];

    return dictionary;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    [self setQuestion: [memento objectForKey: @"LJPollQuestion"]];
    [self setStart: [[memento objectForKey: @"LJPollScaleStart"] intValue]];
    [self setEnd: [[memento objectForKey: @"LJPollScaleEnd"] intValue]];
    [self setStep: [[memento objectForKey: @"LJPollScaleStep"] intValue]];
}

// ----------------------------------------------------------------------------------------
// NSCoding
// ----------------------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject: [NSNumber numberWithInt: start] forKey:@"LJPollScaleStart"];
        [encoder encodeObject: [NSNumber numberWithInt: end] forKey:@"LJPollScaleEnd"];
        [encoder encodeObject: [NSNumber numberWithInt: step] forKey:@"LJPollScaleStep"];

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
        
        start = [[decoder decodeObjectForKey: @"LJPollScaleStart"] intValue];
        end = [[decoder decodeObjectForKey: @"LJPollScaleEnd"] intValue];
        step = [[decoder decodeObjectForKey: @"LJPollScaleStep"] intValue];
    }
    return self;
}
@end
