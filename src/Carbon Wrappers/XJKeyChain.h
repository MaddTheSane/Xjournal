#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import <Carbon/Carbon.h>

@interface XJKeyChain : NSObject {
    unsigned	maxPasswordLength ;
}

+ (XJKeyChain*)defaultKeyChain;

- (void)setGenericPassword:(NSString*)password forService:(NSString *)service account:(NSString*)account;
- (NSString*)genericPasswordForService:(NSString *)service account:(NSString*)account;
- (void)removeGenericPasswordForService:(NSString *)service account:(NSString*)account;

- (void)setMaxPasswordLength:(unsigned)length;
- (unsigned)maxPasswordLength;

@end
