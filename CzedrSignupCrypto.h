//
//  CzedrSignupCrypto.h
//  Czedr — image-bound AES-256-GCM payloads (NIST-aligned v2)
//

#import <Foundation/Foundation.h>

@interface CzedrSignupCrypto : NSObject

/** Current wire format version (AES-256-GCM + HKDF-SHA256). */
+ (NSInteger)preferredCryptoVersion;

/** Legacy v1 key (ECB). Do not use for new traffic. */
+ (NSString *)derivedKeyFromImageData:(NSData *)imageData challengeId:(NSString *)challengeId;

/** Encrypt JSON with v2 (GCM) or v1 when cryptoVersion == 1. */
+ (NSString *)encryptPayload:(NSDictionary *)payload
                  imageData:(NSData *)imageData
                challengeId:(NSString *)challengeId
               cryptoVersion:(NSInteger)cryptoVersion
                      error:(NSError **)error;

/** Download image bytes (prefer server-provided image_b64). */
+ (void)fetchImageDataFromURL:(NSString *)imageUrl
                   completion:(void (^)(NSData *imageData, NSError *error))completion;

@end
