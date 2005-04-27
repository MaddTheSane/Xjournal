//
//  LJPollScaleQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollScaleQuestion.h"


@implementation LJPollScaleQuestion
+ (LJPollScaleQuestion *)scaleQuestionWithStartValue: (int)theStartValue end: (int)theEnd step:(int)theStep
{
    LJPollScaleQuestion *scale = [[LJPollScaleQuestion alloc] init];
    [scale setQuestion: @"Scale Question"];
    [scale setStartValue: [NSNumber numberWithInt: theStartValue]];
    [scale setEnd: theEnd];
    [scale setStep: theStep];

    return [scale autorelease];
}

- (void)setNilValueForKey:(NSString *)theKey {
	NSLog(@"setNilValueForKey: %@", theKey);
}

- (NSNumber *)startValue { return startValue; }
- (void)setStartValue: (NSNumber *)newValue { 
	[startValue release];
	startValue = [[NSNumber numberWithInt: [newValue intValue]] retain];
}

- (int)end { return end; }
- (void)setEnd: (int)newValue { end = newValue; }

- (int)step { return step; }
- (void)setStep: (int)newValue { step = newValue; }

- (NSString *)htmlRepresentation
{
    return [NSString stringWithFormat: @"<lj-pq type=\"scale\" from=\"%d\" to=\"%d\" by=\"%d\">%@</lj-pq>", [startValue intValue], end, step, theQuestion];
}

// Memento
- (NSDictionary *) memento
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject: [[self question] copy] forKey: @"LJPollQuestion"];
    [dictionary setObject: [self startValue] forKey: @"LJPollScalestartValue"];
    [dictionary setObject: [NSNumber numberWithInt: [self end]] forKey: @"LJPollScaleEnd"];
    [dictionary setObject: [NSNumber numberWithInt: [self step]] forKey: @"LJPollScaleStep"];

    return dictionary;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    [self setQuestion: [memento objectForKey: @"LJPollQuestion"]];
    [self setStartValue: [memento objectForKey: @"LJPollScalestartValue"]];
    [self setEnd: [[memento objectForKey: @"LJPollScaleEnd"] intValue]];
    [self setStep: [[memento objectForKey: @"LJPollScaleStep"] intValue]];
}

// ----------------------------------------------------------------------------------------
// NSCoding
// ----------------------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject: startValue forKey: @"LJPollScalestartValue"];
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
        
        startValue = [decoder decodeObjectForKey: @"LJPollScalestartValue"];
        end = [[decoder decodeObjectForKey: @"LJPollScaleEnd"] intValue];
        step = [[decoder decodeObjectForKey: @"LJPollScaleStep"] intValue];
    }
    return self;
}
@end
