//
//  CzedrLanAPIFinder.h
//  Finds the Czedr API on the local Wi‑Fi network (health check + subnet scan).
//

#import <Foundation/Foundation.h>

typedef void (^CzedrLanAPIFinderCompletion)(NSString * _Nullable baseURL, NSError * _Nullable error);

@interface CzedrLanAPIFinder : NSObject

/** Probes saved URLs, then scans the phone's Wi‑Fi subnet for :8080 /v1/health. */
+ (void)resolveWithCompletion:(CzedrLanAPIFinderCompletion)completion;

/** Quick health check for a base URL (no trailing slash). */
+ (void)testBaseURL:(NSString *)base completion:(void (^)(BOOL reachable))completion;

@end
