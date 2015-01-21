//
//  LJPollScaleQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollScaleQuestion.h"

#define kPollScaleStart @"LJPollScaleStart"
#define kPollScaleEnd @"LJPollScaleEnd"
#define kPollScaleStep @"LJPollScaleStep"

@implementation LJPollScaleQuestion
@synthesize start;
@synthesize end;
@synthesize step;

+ (LJPollScaleQuestion *)scaleQuestionWithStart: (NSInteger)theStart end: (NSInteger)theEnd step:(NSInteger)theStep
{
    LJPollScaleQuestion *scale = [[LJPollScaleQuestion alloc] initWithStart:theStart end:theEnd step:theStep];

    return scale;
}

- (instancetype)init
{
    return [self initWithStart:0 end:100 step:10];
}

- (instancetype)initWithStart: (NSInteger)theStart end: (NSInteger)theEnd step:(NSInteger)theStep
{
    if (self = [super init]) {
        start = theStart;
        end = theEnd;
        step = theStep;
    }
    return self;
}

- (NSString *)htmlRepresentation
{
    return [NSString stringWithFormat: @"<lj-pq type=\"scale\" from=\"%ld\" to=\"%ld\" by=\"%ld\">%@</lj-pq>", (long)start, (long)end, (long)step, self.question];
}

#pragma mark Memento Pattern
- (NSDictionary *) memento
{
    NSDictionary *dict = @{kLJPollQuestionKey   : self.question,
                           kPollScaleStart      : @(start),
                           kPollScaleEnd        : @(end),
                           kPollScaleStep       : @(step)};

    return dict;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    self.question = memento[kLJPollQuestionKey];
    self.start = [memento[kPollScaleStart] integerValue];
    self.end = [memento[kPollScaleEnd] integerValue];
    self.step = [memento[kPollScaleStep] integerValue];
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder: encoder];
    [encoder encodeInteger: start forKey: kPollScaleStart];
    [encoder encodeInteger: end forKey: kPollScaleEnd];
    [encoder encodeInteger: step forKey: kPollScaleStep];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder: decoder]) {
        start = [decoder decodeIntegerForKey: kPollScaleStart];
        end = [decoder decodeIntegerForKey: kPollScaleEnd];
        step = [decoder decodeIntegerForKey: kPollScaleStep];
    }
    return self;
}
@end
