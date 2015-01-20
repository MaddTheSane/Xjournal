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

// Memento
- (NSDictionary *) memento
{
    NSDictionary *dict = @{kLJPollQuestionKey : [self.question copy],
                           kPollTextSize : @(self.size),
                           kPollTextLength : @(self.maxLength)};

    return dict;
}

- (void) restoreFromMemento: (NSDictionary *)memento
{
    self.question = memento[kLJPollQuestionKey];
    self.size = [memento[kPollTextSize] integerValue];
    self.maxLength = [memento[kPollTextLength] integerValue];
}

// ----------------------------------------------------------------------------------------
// NSCoding
// ----------------------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeInteger: maxLength forKey: kPollTextLength];
        [encoder encodeInteger: size forKey: kPollTextSize];

        [encoder encodeObject: self.question forKey:kLJPollQuestionKey];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"LJKit requires keyed coding."];
    }
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.question = [decoder decodeObjectForKey:kLJPollQuestionKey];

        maxLength = [decoder decodeIntegerForKey: kPollTextLength];
        size = [decoder decodeIntegerForKey: kPollTextSize];
    }
    return self;
}
@end
