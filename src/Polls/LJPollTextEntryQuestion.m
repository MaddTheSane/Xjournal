//
//  LJPollTextEntryQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollTextEntryQuestion.h"

#define kPollTextSize @"LJPollTextSize"
#define kPollTextLength @"LJPollTextLength"

@implementation LJPollTextEntryQuestion
@synthesize size;
@synthesize maxLength;

+ (LJPollTextEntryQuestion *)textEntryQuestionWithSize: (NSInteger)theSize maxLength: (NSInteger)theLength
{
    LJPollTextEntryQuestion *teQ = [[LJPollTextEntryQuestion alloc] init];
    teQ.question = @"New Text Question";
    teQ.size = theSize;
    teQ.maxLength = theLength;

    return teQ;
}

- (NSString *)htmlRepresentation
{
    return [NSString stringWithFormat: @"<lj-pq type=\"text\" size=\"%ld\" maxlength=\"%ld\">%@</lj-pq>", (long)size, (long)maxLength, theQuestion];
}

#pragma mark Memento Pattern
- (NSDictionary *) memento
{
    NSDictionary *dict = @{kLJPollQuestionKey   : [self.question copy],
                           kPollTextSize        : @(size),
                           kPollTextLength      : @(maxLength)};

    return dict;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    self.question = memento[kLJPollQuestionKey];
    self.size = [memento[kPollTextSize] integerValue];
    self.maxLength = [memento[kPollTextLength] integerValue];
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder: encoder];
    [encoder encodeInteger: maxLength forKey: kPollTextLength];
    [encoder encodeInteger: size forKey: kPollTextSize];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder: decoder]) {
        maxLength = [decoder decodeIntegerForKey: kPollTextLength];
        size = [decoder decodeIntegerForKey: kPollTextSize];
    }
    return self;
}
@end
