#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import <Carbon/Carbon.h>

@interface XJKeyChain : NSObject

@property (nonatomic) UInt32 maxPasswordLength;

+ (instancetype)defaultKeyChain;

- (OSStatus)setGenericPassword:(NSString*)password forService:(NSString *)service account:(NSString*)account;
- (NSString*)genericPasswordForService:(NSString *)service account:(NSString*)account;
- (void)removeGenericPasswordForService:(NSString *)service account:(NSString*)account;

@end
