//
//  CzedrSignupCrypto.m
//  Czedr
//

#import "CzedrSignupCrypto.h"
#import "NSData+Encryption.h"
#import <CommonCrypto/CommonDigest.h>

@implementation CzedrSignupCrypto

+ (NSString *)derivedKeyFromImageData:(NSData *)imageData challengeId:(NSString *)challengeId
{
    NSString *b64 = [imageData base64EncodedStringWithOptions:0];
    if (b64.length < 16) {
        b64 = [b64 stringByPaddingToLength:16 withString:@"0" startingAtIndex:0];
    }
    NSString *base16 = [b64 substringToIndex:16];
    NSString *md5 = [self md5Hex:challengeId ?: @""];
    NSString *chal16 = md5.length >= 16 ? [md5 substringToIndex:16] : md5;
    return [base16 stringByAppendingString:chal16];
}

+ (NSString *)encryptPayload:(NSDictionary *)payload
                  imageData:(NSData *)imageData
                challengeId:(NSString *)challengeId
                      error:(NSError **)error
{
    NSData *json = [NSJSONSerialization dataWithJSONObject:payload options:0 error:error];
    if (!json) {
        return nil;
    }
    NSString *key = [self derivedKeyFromImageData:imageData challengeId:challengeId];
    NSData *cipher = [json AES256EncryptWithKey:key];
    if (!cipher) {
        if (error) {
            *error = [NSError errorWithDomain:@"CzedrSignupCrypto" code:2
                                     userInfo:@{NSLocalizedDescriptionKey: @"Encryption failed"}];
        }
        return nil;
    }
    return [cipher base64EncodedStringWithOptions:0];
}

+ (void)fetchImageDataFromURL:(NSString *)imageUrl
                   completion:(void (^)(NSData *, NSError *))completion
{
    NSURL *url = [NSURL URLWithString:imageUrl ?: @""];
    if (!url) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"CzedrSignupCrypto" code:1
                                            userInfo:@{NSLocalizedDescriptionKey: @"Invalid image URL"}]);
        }
        return;
    }
    NSURLSessionDataTask *task = [[NSURLSession sharedSession]
        dataTaskWithURL:url
      completionHandler:^(NSData *data, NSURLResponse *response, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err || !data.length) {
                if (completion) {
                    completion(nil, err ?: [NSError errorWithDomain:@"CzedrSignupCrypto" code:3
                                                           userInfo:@{NSLocalizedDescriptionKey: @"Image download failed"}]);
                }
                return;
            }
            if (completion) {
                completion(data, nil);
            }
        });
    }];
    [task resume];
}

+ (NSString *)md5Hex:(NSString *)input
{
    const char *str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x", result[i]];
    }
    return ret;
}

@end
