#import "XJKeyChain.h"
#import <Security/Security.h>

static XJKeyChain* defaultKeyChain = nil;

@interface XJKeyChain ()

-(SecKeychainItemRef)_genericPasswordReferenceForService:(NSString *)service account:(NSString*)account CF_RETURNS_RETAINED;

@end

@implementation XJKeyChain
@synthesize maxPasswordLength;

+ (instancetype) defaultKeyChain {
	return ( defaultKeyChain ?: [[self alloc] init] );
}

- (instancetype)init
{
    self = [super init];
    maxPasswordLength = 127;
    return self;
}

- (OSStatus)setGenericPassword:(NSString*)password forService:(NSString *)service account:(NSString*)account
{
    OSStatus ret = noErr;
    SecKeychainItemRef itemref = NULL;
    void *p = (void *)alloca(maxPasswordLength * sizeof(char));
    
    if ([service length] == 0 || [account length] == 0) {
        return ret;
    }
    
    if (!password || [password length] == 0) {
        [self removeGenericPasswordForService:service account:account];
    } else {
        strcpy(p,[password UTF8String]);
    
        if ((itemref = [self _genericPasswordReferenceForService:service account:account]))
			SecKeychainItemDelete(itemref);
        SecKeychainRef keychain;
        SecKeychainCopyDefault(&keychain);
        ret = SecKeychainAddGenericPassword(keychain, (UInt32)[service lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [service UTF8String], (UInt32)[account lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [account UTF8String], (UInt32)strlen(p), p, &itemref);
        CFRelease(itemref);
    }
    return ret;
}

- (NSString*)genericPasswordForService:(NSString *)service account:(NSString*)account
{
    OSStatus ret = noErr;
    UInt32 length = 0;
    void *p = NULL;
    NSString *string = @"";
    
    if ([service length] == 0 || [account length] == 0) {
        return @"";
    }
    
    ret = SecKeychainFindGenericPassword(NULL, (UInt32)[service lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [service UTF8String], (UInt32)[account lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [account UTF8String], &length, &p, NULL);

    if (ret == noErr)
        string = [[NSString alloc] initWithBytes:p length:length encoding:NSUTF8StringEncoding];
	if (p) {
        SecKeychainItemFreeContent(NULL, p);
	}
    return string;
}

- (void)removeGenericPasswordForService:(NSString *)service account:(NSString*)account
{
    SecKeychainItemRef itemref = nil ;
    if ((itemref = [self _genericPasswordReferenceForService:service account:account]))
        SecKeychainItemDelete(itemref);
}

- (void)setMaxPasswordLength:(NSUInteger)length
{
    if (![self isEqual:defaultKeyChain]) {
        maxPasswordLength = length ;
    } else {
    }
}

- (SecKeychainItemRef)_genericPasswordReferenceForService:(NSString *)service account:(NSString*)account
{
    SecKeychainItemRef itemref = nil;
    SecKeychainFindGenericPassword(NULL, (UInt32)[service lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [service UTF8String], (UInt32)[account lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [account UTF8String], NULL, NULL, &itemref);
    return itemref;
}

@end
