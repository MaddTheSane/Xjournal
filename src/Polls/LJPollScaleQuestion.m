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

#pragma mark Memento Pattern
- (NSDictionary *) memento
{
    NSDictionary *dict = @{kLJPollQuestionKey : [self.question copy],
                           kPollScaleStart :    @(start),
                           kPollScaleEnd :      @(end),
                           kPollScaleStep :     @(step)};

    return dict;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    self.question = memento[kLJPollQuestionKey];
    start = [memento[kPollScaleStart] intValue];
    end = [memento[kPollScaleEnd] intValue];
    step = [memento[kPollScaleStep] intValue];
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder: encoder];
    [encoder encodeInt: start forKey: kPollScaleStart];
    [encoder encodeInt: end forKey: kPollScaleEnd];
    [encoder encodeInt: step forKey: kPollScaleStep];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder: decoder]) {
        start = [decoder decodeIntForKey: kPollScaleStart];
        end = [decoder decodeIntForKey: kPollScaleEnd];
        step = [decoder decodeIntForKey: kPollScaleStep];
    }
    return self;
}
@end
