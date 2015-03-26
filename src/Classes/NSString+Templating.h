/*

NSString+Templating.h
TemplateTest
by Buzz Andersen

More information at: http://www.scifihifi.com/weblog/software/NSString+Templating.html

This work is licensed under the Creative Commons Attribution License. To view a copy of this license, visit

http://creativecommons.org/licenses/by/1.0/

or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford,
California 94305, USA.

*/

#import <Foundation/Foundation.h>


@interface NSString (Templating)

- (nonnull NSString *) stringByParsingTagsWithStartDelimeter: (nonnull NSString *) startDelim endDelimeter: (nonnull NSString *) endDelim usingObject: (nonnull id) object;
@property (readonly, copy, nonnull) NSString *stringByEscapingQuotes;
- (nonnull NSString *) stringByEscapingCharactersInSet: (nonnull NSCharacterSet *) set usingString: (nonnull NSString*) escapeString;

@end
