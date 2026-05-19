//
//  CzedrSignupCrypto.m
//  Czedr
//

#import "CzedrSignupCrypto.h"
#import "NSData+Encryption.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <Security/Security.h>

#if __has_include("Czedr-Swift.h")
#import "Czedr-Swift.h"
#endif

static const uint8_t kCzedrCryptoVersionV2 = 0x02;
static const size_t kCzedrGcmIvLen = 12;
static const size_t kCzedrGcmTagLen = 16;
static const size_t kCzedrAesKeyLen = 32;
static NSString * const kCzedrHkdfInfo = @"czedr-secure-v2";
static NSString * const kCzedrHkdfCardInfo = @"czedr-card-link-v2";

@implementation CzedrSignupCrypto

+ (NSInteger)preferredCryptoVersion
{
    return 2;
}

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
               cryptoVersion:(NSInteger)cryptoVersion
                      error:(NSError **)error
{
    if (cryptoVersion <= 1) {
        return [self encryptPayloadV1:payload imageData:imageData challengeId:challengeId error:error];
    }
    return [self encryptPayloadV2:payload imageData:imageData challengeId:challengeId error:error];
}

+ (NSString *)encryptPayloadV1:(NSDictionary *)payload
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

+ (NSString *)encryptPayloadV2:(NSDictionary *)payload
                    imageData:(NSData *)imageData
                  challengeId:(NSString *)challengeId
                        error:(NSError **)error
{
    NSData *json = [NSJSONSerialization dataWithJSONObject:payload options:0 error:error];
    if (!json) {
        return nil;
    }
    NSData *key = [self deriveKeyV2FromImageData:imageData challengeId:challengeId];
    if (key.length != kCzedrAesKeyLen) {
        if (error) {
            *error = [NSError errorWithDomain:@"CzedrSignupCrypto" code:4
                                     userInfo:@{NSLocalizedDescriptionKey: @"Key derivation failed"}];
        }
        return nil;
    }

    uint8_t iv[kCzedrGcmIvLen];
    if (SecRandomCopyBytes(kSecRandomDefault, kCzedrGcmIvLen, iv) != errSecSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:@"CzedrSignupCrypto" code:5
                                     userInfo:@{NSLocalizedDescriptionKey: @"Random IV failed"}];
        }
        return nil;
    }

    uint8_t tag[kCzedrGcmTagLen];
    NSData *cipher = [self aesGcmEncrypt:json key:key iv:iv tagOut:tag error:error];
    if (!cipher) {
        return nil;
    }

    NSMutableData *wire = [NSMutableData dataWithCapacity:1 + kCzedrGcmIvLen + kCzedrGcmTagLen + cipher.length];
    uint8_t version = kCzedrCryptoVersionV2;
    [wire appendBytes:&version length:1];
    [wire appendBytes:iv length:kCzedrGcmIvLen];
    [wire appendBytes:tag length:kCzedrGcmTagLen];
    [wire appendData:cipher];

    return [wire base64EncodedStringWithOptions:0];
}

+ (NSData *)deriveKeyV2FromImageData:(NSData *)imageData challengeId:(NSString *)challengeId
{
    return [self deriveKeyV2FromImageData:imageData salt:challengeId info:kCzedrHkdfInfo];
}

+ (NSData *)deriveKeyV2FromImageData:(NSData *)imageData salt:(NSString *)saltString info:(NSString *)infoString
{
    NSData *salt = [saltString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *info = [infoString dataUsingEncoding:NSUTF8StringEncoding];
    return [self hkdfSha256FromInput:imageData salt:salt info:info outputLength:kCzedrAesKeyLen];
}

/** RFC 5869 HKDF-SHA256 fallback when CCKeyDerivationHKDF is unavailable at compile time. */
+ (NSData *)hkdfSha256FromInput:(NSData *)input salt:(NSData *)salt info:(NSData *)info outputLength:(size_t)length
{
    uint8_t prk[CC_SHA256_DIGEST_LENGTH];
    unsigned char zeroSalt[CC_SHA256_DIGEST_LENGTH] = {0};
    const void *saltBytes = salt.length ? salt.bytes : zeroSalt;
    size_t saltLen = salt.length ? salt.length : sizeof(zeroSalt);

    CCHmac(kCCHmacAlgSHA256, saltBytes, saltLen, input.bytes, input.length, prk);

    NSMutableData *okm = [NSMutableData dataWithLength:length];
    uint8_t t[CC_SHA256_DIGEST_LENGTH];
    size_t done = 0;
    uint8_t counter = 1;
    size_t tLen = 0;

    while (done < length) {
        CCHmacContext ctx;
        CCHmacInit(&ctx, kCCHmacAlgSHA256, prk, CC_SHA256_DIGEST_LENGTH);
        if (tLen > 0) {
            CCHmacUpdate(&ctx, t, tLen);
        }
        if (info.length) {
            CCHmacUpdate(&ctx, info.bytes, info.length);
        }
        CCHmacUpdate(&ctx, &counter, 1);
        CCHmacFinal(&ctx, t);
        tLen = CC_SHA256_DIGEST_LENGTH;
        size_t copy = MIN(tLen, length - done);
        memcpy((uint8_t *)okm.mutableBytes + done, t, copy);
        done += copy;
        counter++;
    }

    return okm;
}

+ (NSData *)aesGcmEncrypt:(NSData *)plain
                      key:(NSData *)key
                       iv:(const uint8_t *)iv
                   tagOut:(uint8_t *)tag
                    error:(NSError **)error
{
#if __has_include("Czedr-Swift.h")
    NSData *ivData = [NSData dataWithBytes:iv length:kCzedrGcmIvLen];
    return [CzedrAesGcmBridge encryptPlain:plain key:key iv:ivData tag:tagOut error:error];
#else
    if (error) {
        *error = [NSError errorWithDomain:@"CzedrSignupCrypto" code:6
                                 userInfo:@{NSLocalizedDescriptionKey: @"CryptoKit bridge unavailable"}];
    }
    return nil;
#endif
}

+ (NSString *)encryptCardPayload:(NSDictionary *)payload
                      imageData:(NSData *)imageData
                         userId:(NSString *)userId
                          error:(NSError **)error
{
    NSData *json = [NSJSONSerialization dataWithJSONObject:payload options:0 error:error];
    if (!json) {
        return nil;
    }
    NSData *key = [self deriveKeyV2FromImageData:imageData salt:userId info:kCzedrHkdfCardInfo];
    if (key.length != kCzedrAesKeyLen) {
        if (error) {
            *error = [NSError errorWithDomain:@"CzedrSignupCrypto" code:4
                                     userInfo:@{NSLocalizedDescriptionKey: @"Key derivation failed"}];
        }
        return nil;
    }

    uint8_t iv[kCzedrGcmIvLen];
    if (SecRandomCopyBytes(kSecRandomDefault, kCzedrGcmIvLen, iv) != errSecSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:@"CzedrSignupCrypto" code:5
                                     userInfo:@{NSLocalizedDescriptionKey: @"Random IV failed"}];
        }
        return nil;
    }

    uint8_t tag[kCzedrGcmTagLen];
    NSData *cipher = [self aesGcmEncrypt:json key:key iv:iv tagOut:tag error:error];
    if (!cipher) {
        return nil;
    }

    NSMutableData *wire = [NSMutableData dataWithCapacity:1 + kCzedrGcmIvLen + kCzedrGcmTagLen + cipher.length];
    uint8_t version = kCzedrCryptoVersionV2;
    [wire appendBytes:&version length:1];
    [wire appendBytes:iv length:kCzedrGcmIvLen];
    [wire appendBytes:tag length:kCzedrGcmTagLen];
    [wire appendData:cipher];

    return [wire base64EncodedStringWithOptions:0];
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
