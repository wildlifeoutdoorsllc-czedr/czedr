//
//  CzedrSignupCrypto.h
//  Czedr — encrypt signup payloads with a hidden random image key
//

#import <Foundation/Foundation.h>

@interface CzedrSignupCrypto : NSObject

/** First 16 chars of base64(image) + first 16 chars of md5(challengeId). */
+ (NSString *)derivedKeyFromImageData:(NSData *)imageData challengeId:(NSString *)challengeId;

/** AES-256 encrypt JSON payload; returns base64 ciphertext. */
+ (NSString *)encryptPayload:(NSDictionary *)payload
                  imageData:(NSData *)imageData
                challengeId:(NSString *)challengeId
                      error:(NSError **)error;

/** Download image bytes in background (Library of Congress URL from challenge). */
+ (void)fetchImageDataFromURL:(NSString *)imageUrl
                   completion:(void (^)(NSData *imageData, NSError *error))completion;

@end
