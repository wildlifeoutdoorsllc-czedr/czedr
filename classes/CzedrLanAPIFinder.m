//
//  CzedrLanAPIFinder.m
//

#import "CzedrLanAPIFinder.h"
#import "CzedrRuntimeConfig.h"
#import "CzedrConfig.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>

static NSString * const kCzedrFinderErrorDomain = @"CzedrLanAPIFinder";
static const NSTimeInterval kHealthTimeout = 1.8;
static const NSUInteger kMaxParallelProbes = 28;

@implementation CzedrLanAPIFinder

+ (NSString *)normalizedBase:(NSString *)base
{
    if (![base isKindOfClass:[NSString class]]) {
        return @"";
    }
    NSString *trimmed = [base stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    while ([trimmed hasSuffix:@"/"]) {
        trimmed = [trimmed substringToIndex:trimmed.length - 1];
    }
    return trimmed;
}

+ (BOOL)isSimulator
{
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isLocalhostBase:(NSString *)base
{
    NSString *lower = [[self normalizedBase:base] lowercaseString];
    return [lower containsString:@"127.0.0.1"] || [lower containsString:@"localhost"];
}

+ (void)testBaseURL:(NSString *)base completion:(void (^)(BOOL))completion
{
    NSString *normalized = [self normalizedBase:base];
    if (normalized.length == 0) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    NSString *urlString = [NSString stringWithFormat:@"%@/v1/health", normalized];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = kHealthTimeout;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        BOOL ok = NO;
        if (!error && data.length > 0) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json isKindOfClass:[NSDictionary class]]) {
                NSString *status = [NSString stringWithFormat:@"%@", json[@"Status"]];
                ok = [status isEqualToString:@"true"];
            }
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(ok);
            });
        }
    }] resume];
}

+ (NSString *)wifiIPv4Address
{
    struct ifaddrs *interfaces = NULL;
    if (getifaddrs(&interfaces) != 0) {
        return nil;
    }
    NSString *result = nil;
    for (struct ifaddrs *cursor = interfaces; cursor != NULL; cursor = cursor->ifa_next) {
        if (!cursor->ifa_addr || cursor->ifa_addr->sa_family != AF_INET) {
            continue;
        }
        NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
        if (![name hasPrefix:@"en"]) {
            continue;
        }
        char host[INET_ADDRSTRLEN];
        struct sockaddr_in *addr = (struct sockaddr_in *)cursor->ifa_addr;
        if (!inet_ntop(AF_INET, &addr->sin_addr, host, sizeof(host))) {
            continue;
        }
        NSString *ip = [NSString stringWithUTF8String:host];
        if ([ip hasPrefix:@"127."] || [ip hasPrefix:@"169.254."]) {
            continue;
        }
        result = ip;
        break;
    }
    freeifaddrs(interfaces);
    return result;
}

+ (NSArray<NSString *> *)candidateBases
{
    NSMutableOrderedSet<NSString *> *ordered = [NSMutableOrderedSet orderedSet];
    void (^add)(NSString *) = ^(NSString *value) {
        NSString *normalized = [self normalizedBase:value];
        if (normalized.length == 0) {
            return;
        }
        if (![self isSimulator] && [self isLocalhostBase:normalized]) {
            return;
        }
        [ordered addObject:normalized];
    };

    add(CzedrEffectiveAPIBase());
    add(CzedrLastGoodAPIBase());

#if CZEDR_USE_V1_API
    add(@CZEDR_API_BASE);
#endif

    NSString *wifiIP = [self wifiIPv4Address];
    if (wifiIP.length > 0) {
        NSArray *parts = [wifiIP componentsSeparatedByString:@"."];
        if (parts.count == 4) {
            NSString *prefix = [NSString stringWithFormat:@"%@.%@.%@.", parts[0], parts[1], parts[2]];
            NSInteger ownHost = [parts[3] integerValue];
            NSMutableArray<NSNumber *> *hosts = [NSMutableArray array];
            for (NSNumber *n in @[@1, @10, @20, @51, @100, @(ownHost), @254]) {
                if (![hosts containsObject:n] && n.integerValue > 0 && n.integerValue < 255) {
                    [hosts addObject:n];
                }
            }
            for (NSUInteger host = 1; host <= 254; host++) {
                NSNumber *n = @(host);
                if (![hosts containsObject:n]) {
                    [hosts addObject:n];
                }
            }
            for (NSNumber *host in hosts) {
                add([NSString stringWithFormat:@"http://%@%@:8080", prefix, host]);
            }
        }
    }

    return ordered.array;
}

+ (void)probeCandidates:(NSArray<NSString *> *)candidates
                    from:(NSUInteger)index
              completion:(CzedrLanAPIFinderCompletion)completion
{
    if (index >= candidates.count) {
        if (completion) {
            NSError *err = [NSError errorWithDomain:kCzedrFinderErrorDomain
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey:
                                                        @"Could not find your Czedr server. On your PC run START-IPHONE-TESTING.cmd and click Yes if Windows asks. iPhone and PC must be on the same Wi‑Fi. In Settings → Czedr → turn Local Network ON."}];
            completion(nil, err);
        }
        return;
    }

    NSUInteger batchEnd = MIN(index + kMaxParallelProbes, candidates.count);
    dispatch_group_t group = dispatch_group_create();
    __block NSString *found = nil;

    for (NSUInteger i = index; i < batchEnd; i++) {
        NSString *base = candidates[i];
        dispatch_group_enter(group);
        [self testBaseURL:base completion:^(BOOL reachable) {
            if (reachable && !found) {
                @synchronized (self) {
                    if (!found) {
                        found = base;
                    }
                }
            }
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (found.length > 0) {
            CzedrSetAPIBaseOverride(found);
            CzedrRememberLastGoodAPIBase(found);
            if (completion) {
                completion(found, nil);
            }
            return;
        }
        [self probeCandidates:candidates from:batchEnd completion:completion];
    });
}

+ (void)resolveWithCompletion:(CzedrLanAPIFinderCompletion)completion
{
    if (![self isSimulator] && [self isLocalhostBase:CzedrEffectiveAPIBase()]) {
        CzedrSetAPIBaseOverride(@"");
    }

    NSArray<NSString *> *candidates = [self candidateBases];
    if (candidates.count == 0) {
        if (completion) {
            NSError *err = [NSError errorWithDomain:kCzedrFinderErrorDomain
                                             code:2
                                         userInfo:@{NSLocalizedDescriptionKey: @"No API server to search for."}];
            completion(nil, err);
        }
        return;
    }

    [self probeCandidates:candidates from:0 completion:completion];
}

@end
