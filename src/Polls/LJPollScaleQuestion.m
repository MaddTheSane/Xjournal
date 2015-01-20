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

// Memento
- (NSDictionary *) memento
{
    NSDictionary *dict = @{kLJPollQuestionKey : [self.question copy],
                           kPollScaleStart :    @(self.start),
                           kPollScaleEnd :      @(self.end),
                           kPollScaleStep :     @(self.step)};

    return dict;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    self.question = memento[kLJPollQuestionKey];
    self.start = [memento[kPollScaleStart] intValue];
    self.end = [memento[kPollScaleEnd] intValue];
    self.step = [memento[kPollScaleStep] intValue];
}

// ----------------------------------------------------------------------------------------
// NSCoding
// ----------------------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeInt: start forKey: kPollScaleStart];
        [encoder encodeInt: end forKey: kPollScaleEnd];
        [encoder encodeInt: step forKey: kPollScaleStep];

        [encoder encodeObject: [self question] forKey:kLJPollQuestionKey];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"LJKit requires keyed coding."];
    }
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.question = [decoder decodeObjectForKey: kLJPollQuestionKey];
        
        start = [decoder decodeIntForKey: kPollScaleStart];
        end = [decoder decodeIntForKey: kPollScaleEnd];
        step = [decoder decodeIntForKey: kPollScaleStep];
    }
    return self;
}
@end
