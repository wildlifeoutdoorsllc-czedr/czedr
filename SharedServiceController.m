//
//  SharedServiceController.m
//  Czedr
//

#import "SharedServiceController.h"
#import "CzedrSignupCrypto.h"
#import "CzedrRuntimeConfig.h"
#import "CzedrLanAPIFinder.h"
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@implementation SharedServiceController

+ (BOOL)usesV1API
{
#if CZEDR_USE_V1_API
    return YES;
#else
    return NO;
#endif
}

+ (NSString *)apiBaseURLString
{
    return CzedrEffectiveAPIBase();
}

+ (NSString *)authToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"auth_codeSaved"] ?: @"";
}

+ (NSDictionary *)savedUserPayload
{
    id data = [[NSUserDefaults standardUserDefaults] objectForKey:@"userDataArray"];
    return [data isKindOfClass:[NSDictionary class]] ? data : nil;
}

+ (NSString *)savedCzedrUserId
{
    NSDictionary *user = [self savedUserPayload];
    if (!user) {
        return @"";
    }
    id cid = user[@"id"] ?: user[@"czedr_id"];
    return [cid isKindOfClass:[NSString class]] ? cid : @"";
}

static void CzedrDispatchMain(void (^block)(void))
{
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (id)plistSafeObject:(id)obj
{
    if (obj == nil || obj == [NSNull null]) {
        return nil;
    }
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSData class]] ||
        [obj isKindOfClass:[NSDate class]]) {
        return obj;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *out = [NSMutableDictionary dictionary];
        [(NSDictionary *)obj enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop) {
            (void)stop;
            if (![key isKindOfClass:[NSString class]]) {
                return;
            }
            id safe = [self plistSafeObject:val];
            if (safe != nil) {
                out[key] = safe;
            }
        }];
        return [out copy];
    }
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *out = [NSMutableArray array];
        for (id item in (NSArray *)obj) {
            id safe = [self plistSafeObject:item];
            if (safe != nil) {
                [out addObject:safe];
            }
        }
        return [out copy];
    }
    return [NSString stringWithFormat:@"%@", obj];
}

+ (void)saveLoginPayload:(NSDictionary *)data
{
    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *safeData = [self plistSafeObject:data];
    if (![safeData isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *auth = [safeData objectForKey:@"auth_code"];
    if (![auth isKindOfClass:[NSString class]] || auth.length == 0) {
        auth = [safeData objectForKey:@"auth_token"];
    }
    if ([auth isKindOfClass:[NSString class]] && auth.length > 0) {
        [[NSUserDefaults standardUserDefaults] setValue:auth forKey:@"auth_codeSaved"];
    }
    [[NSUserDefaults standardUserDefaults] setValue:safeData forKey:@"userDataArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDictionary *)legacyUserPayloadFromV1:(NSDictionary *)data
{
    NSDictionary *user = [data objectForKey:@"user"];
    if (![user isKindOfClass:[NSDictionary class]]) {
        user = data;
    }
    NSString *czedrId = [user objectForKey:@"czedr_id"] ?: [data objectForKey:@"id"] ?: @"";
    NSString *email = [user objectForKey:@"email"] ?: @"";
    NSString *name = [user objectForKey:@"name"] ?: [user objectForKey:@"display_name"] ?: email;
    NSString *auth = [data objectForKey:@"auth_code"];
    if (![auth isKindOfClass:[NSString class]] || auth.length == 0) {
        auth = [data objectForKey:@"auth_token"];
    }
    if (![auth isKindOfClass:[NSString class]]) {
        auth = @"";
    }
    NSDictionary *payload = @{
        @"auth_code": auth,
        @"id": czedrId,
        @"czedr_id": czedrId,
        @"email": email,
        @"email ": email,
        @"name": name,
        @"user_pin": [data objectForKey:@"user_pin"] ?: @"0",
        @"profile_pic ": @"",
        @"user": user ?: @{}
    };
    id safe = [self plistSafeObject:payload];
    return [safe isKindOfClass:[NSDictionary class]] ? safe : payload;
}

+ (void)sendSecurePOSTToPath:(NSString *)path
                     payload:(NSDictionary *)payload
                 authenticated:(BOOL)authenticated
                       success:(CzedrAPISuccessBlock)success
                       failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"GET"
                       path:@"/v1/auth/signup-challenge"
                 parameters:nil
              authenticated:NO
                    success:^(NSDictionary *challenge) {
                        NSString *challengeId = [challenge objectForKey:@"challenge_id"];
                        NSString *imageB64 = [challenge objectForKey:@"image_b64"];
                        NSString *imageUrl = [challenge objectForKey:@"image_url"];
                        if (challengeId.length == 0) {
                            failure(@"Could not start secure request");
                            return;
                        }
                        NSInteger cryptoVersion = 2;
                        id cv = [challenge objectForKey:@"crypto_version"];
                        if ([cv respondsToSelector:@selector(integerValue)] && [cv integerValue] > 0) {
                            cryptoVersion = [cv integerValue];
                        }
                        if (cryptoVersion < 2) {
                            cryptoVersion = [CzedrSignupCrypto preferredCryptoVersion];
                        }
                        void (^encryptAndPost)(NSData *) = ^(NSData *imageData) {
                            if (!imageData.length) {
                                failure(@"Could not load encryption image");
                                return;
                            }
                            NSError *cryptErr = nil;
                            NSString *enc = [CzedrSignupCrypto encryptPayload:payload
                                                                     imageData:imageData
                                                                   challengeId:challengeId
                                                                  cryptoVersion:cryptoVersion
                                                                         error:&cryptErr];
                            if (!enc.length) {
                                failure(cryptErr.localizedDescription ?: @"Encryption failed");
                                return;
                            }
                            [self requestJSONMethod:@"POST"
                                               path:path
                                         parameters:@{
                                             @"challenge_id": challengeId,
                                             @"enc_data": enc,
                                             @"crypto_version": @(cryptoVersion)
                                         }
                                      authenticated:authenticated
                                            success:success
                                            failure:failure];
                        };
                        if ([imageB64 isKindOfClass:[NSString class]] && imageB64.length > 0) {
                            NSData *imageData = [[NSData alloc] initWithBase64EncodedString:imageB64 options:0];
                            encryptAndPost(imageData);
                            return;
                        }
                        if (imageUrl.length == 0) {
                            failure(@"Could not start secure request");
                            return;
                        }
                        [CzedrSignupCrypto fetchImageDataFromURL:imageUrl
                                                      completion:^(NSData *imageData, NSError *err) {
                            if (err || !imageData.length) {
                                failure(err.localizedDescription ?: @"Could not load encryption image");
                                return;
                            }
                            encryptAndPost(imageData);
                        }];
                    }
                    failure:failure];
}

+ (NSString *)messageFromAPIResponse:(NSString *)response fallback:(NSString *)fallback
{
    NSDictionary *json = [[response JSONValue] isKindOfClass:[NSDictionary class]] ? [response JSONValue] : nil;
    if (!json) {
        return fallback;
    }
    id errData = [json objectForKey:@"Data"];
    if ([errData isKindOfClass:[NSArray class]] && [[errData firstObject] isKindOfClass:[NSDictionary class]]) {
        NSString *result = [[errData firstObject] objectForKey:@"result"];
        if ([result isKindOfClass:[NSString class]] && result.length > 0) {
            return result;
        }
    }
    return fallback;
}

+ (void)requestJSONMethod:(NSString *)method
                      path:(NSString *)path
                parameters:(NSDictionary *)params
             authenticated:(BOOL)authenticated
                   success:(CzedrAPISuccessBlock)success
                   failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:method
                       path:path
                 parameters:params
              authenticated:authenticated
         retryAfterDiscovery:YES
                    success:success
                    failure:failure];
}

+ (void)requestJSONMethod:(NSString *)method
                      path:(NSString *)path
                parameters:(NSDictionary *)params
             authenticated:(BOOL)authenticated
         retryAfterDiscovery:(BOOL)retryAfterDiscovery
                   success:(CzedrAPISuccessBlock)success
                   failure:(CzedrAPIFailureBlock)failure
{
    NSString *url = [NSString stringWithFormat:@"%@%@", [self apiBaseURLString], path];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
    responseSerializer.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 400)];
    manager.responseSerializer = responseSerializer;
    if (authenticated) {
        NSString *token = [self authToken];
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token]
                         forHTTPHeaderField:@"Authorization"];
    }
    void (^ok)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = [NSString stringWithFormat:@"%@", operation.responseString];
        NSDictionary *json = [[response JSONValue] isKindOfClass:[NSDictionary class]] ? [response JSONValue] : nil;
        NSString *status = [NSString stringWithFormat:@"%@", [json objectForKey:@"Status"]];
        CzedrDispatchMain(^{
            if ([status isEqualToString:@"true"]) {
                id data = [json objectForKey:@"Data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    success((NSDictionary *)data);
                } else if ([data isKindOfClass:[NSArray class]]) {
                    NSMutableDictionary *wrap = [NSMutableDictionary dictionaryWithObject:data forKey:@"Data"];
                    if ([json objectForKey:@"Total_rows"] != nil) {
                        [wrap setObject:[json objectForKey:@"Total_rows"] forKey:@"Total_rows"];
                    }
                    success(wrap);
                } else {
                    success(@{@"Data": data ?: @[]});
                }
            } else {
                failure([self messageFromAPIResponse:response fallback:@"Request failed"]);
            }
        });
    };
    void (^fail)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *base = [self apiBaseURLString];
        NSString *response = operation.responseString ? [NSString stringWithFormat:@"%@", operation.responseString] : @"";
        NSString *detail = [self messageFromAPIResponse:response fallback:(error.localizedDescription ?: @"Network error")];
        NSInteger code = error.code;
        BOOL unreachable = (response.length == 0 &&
            (code == NSURLErrorNotConnectedToInternet ||
             code == NSURLErrorCannotConnectToHost ||
             code == NSURLErrorTimedOut ||
             code == NSURLErrorNetworkConnectionLost));
        if (unreachable && retryAfterDiscovery) {
            [CzedrLanAPIFinder resolveWithCompletion:^(NSString *resolvedBase, NSError *resolveError) {
                if (resolvedBase.length > 0) {
                    [self requestJSONMethod:method
                                       path:path
                                 parameters:params
                              authenticated:authenticated
                         retryAfterDiscovery:NO
                                    success:success
                                    failure:failure];
                } else {
                    NSString *hint = resolveError.localizedDescription ?: detail;
                    failure(hint);
                }
            }];
            return;
        }
        if (unreachable) {
            detail = [NSString stringWithFormat:
                @"Cannot reach the API at %@. On your PC run START-IPHONE-TESTING.cmd (click Yes if Windows asks). Same Wi-Fi as the PC. Settings -> Czedr -> Local Network ON.",
                base];
        }
        CzedrDispatchMain(^{
            failure(detail);
        });
    };
    if ([method isEqualToString:@"GET"]) {
        [manager GET:url parameters:params success:ok failure:fail];
    } else {
        [manager POST:url parameters:params success:ok failure:fail];
    }
}

+ (void)loginWithEmail:(NSString *)email
              password:(NSString *)password
               success:(CzedrAPISuccessBlock)success
               failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        failure(@"Legacy login: use ViewController call_LoginService");
        return;
    }
    [self loginSecureWithEmail:email password:password success:success failure:failure];
}

+ (NSString *)normalizedAPIBaseURL
{
    NSString *base = [[self apiBaseURLString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    while ([base hasSuffix:@"/"]) {
        base = [base substringToIndex:base.length - 1];
    }
    return base ?: @"";
}

+ (void)loginSecureWithEmail:(NSString *)email
                    password:(NSString *)password
                     success:(CzedrAPISuccessBlock)success
                     failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        CzedrDispatchMain(^{
            failure(@"Secure login requires Czedr API");
        });
        return;
    }
    NSString *trimmedEmail = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *base = [self normalizedAPIBaseURL];
    if (base.length == 0) {
        CzedrDispatchMain(^{
            failure(@"Enter the API server URL (e.g. http://192.168.x.x:8080).");
        });
        return;
    }
    NSString *urlString = [NSString stringWithFormat:@"%@/v1/auth/login", base];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        CzedrDispatchMain(^{
            failure(@"Invalid API server URL.");
        });
        return;
    }

    NSDictionary *body = @{
        @"user_email": trimmedEmail ?: @"",
        @"email": trimmedEmail ?: @"",
        @"user_pwd": password ?: @"",
        @"password": password ?: @""
    };
    NSError *jsonError = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    if (!bodyData) {
        CzedrDispatchMain(^{
            failure(jsonError.localizedDescription ?: @"Could not encode login request.");
        });
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = bodyData;
    request.timeoutInterval = 25.0;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        CzedrDispatchMain(^{
            if (error) {
                NSString *detail = error.localizedDescription ?: @"Network error";
                if ([error.domain isEqualToString:NSURLErrorDomain]) {
                    detail = [NSString stringWithFormat:
                        @"Cannot reach %@. Run START-IPHONE-TESTING.cmd on your PC, same Wi-Fi, Settings → Czedr → Local Network ON.",
                        base];
                }
                failure(detail);
                return;
            }
            NSString *raw = data.length > 0 ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
            NSDictionary *json = nil;
            if (raw.length > 0) {
                id parsed = [raw JSONValue];
                if ([parsed isKindOfClass:[NSDictionary class]]) {
                    json = (NSDictionary *)parsed;
                }
            }
            if (!json) {
                failure(@"Invalid response from server.");
                return;
            }
            NSString *status = [NSString stringWithFormat:@"%@", [json objectForKey:@"Status"]];
            if ([status isEqualToString:@"true"]) {
                id dataObj = [json objectForKey:@"Data"];
                if ([dataObj isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *legacy = [self legacyUserPayloadFromV1:(NSDictionary *)dataObj];
                    [self saveLoginPayload:legacy];
                    success(legacy);
                    return;
                }
                failure(@"Invalid login response.");
                return;
            }
            failure([self messageFromAPIResponse:raw fallback:@"Sign-in failed"]);
        });
    }] resume];
}

+ (void)verifyPinSecure:(NSString *)pin
                success:(CzedrAPISuccessBlock)success
                failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        failure(@"Secure PIN verify requires Czedr API");
        return;
    }
    [self sendSecurePOSTToPath:@"/v1/auth/pin/verify-secure"
                       payload:@{@"user_pin": pin ?: @""}
                   authenticated:YES
                         success:success
                         failure:failure];
}

+ (void)updatePinSecureOldPin:(NSString *)oldPin
                       newPin:(NSString *)newPin
                      success:(CzedrAPISuccessBlock)success
                      failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        failure(@"Secure PIN update requires Czedr API");
        return;
    }
    [self sendSecurePOSTToPath:@"/v1/auth/pin/update-secure"
                       payload:@{@"old_pin": oldPin ?: @"", @"new_pin": newPin ?: @""}
                   authenticated:YES
                         success:success
                         failure:failure];
}

+ (void)setPinSecure:(NSString *)pin
             success:(CzedrAPISuccessBlock)success
             failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        failure(@"PIN set requires Czedr API");
        return;
    }
    [self requestJSONMethod:@"POST"
                       path:@"/v1/auth/pin/set"
                 parameters:@{@"user_pin": pin ?: @""}
              authenticated:YES
                    success:success
                    failure:failure];
}

+ (void)requestPasswordResetForEmail:(NSString *)email
                             success:(CzedrAPISuccessBlock)success
                             failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        failure(@"Password reset requires Czedr API");
        return;
    }
    [self requestJSONMethod:@"POST"
                       path:@"/v1/auth/forgot-password"
                 parameters:@{@"user_email": email ?: @"", @"email": email ?: @""}
              authenticated:NO
                    success:success
                    failure:failure];
}

+ (void)completePasswordResetWithToken:(NSString *)token
                           newPassword:(NSString *)password
                               success:(CzedrAPISuccessBlock)success
                               failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        failure(@"Password reset requires Czedr API");
        return;
    }
    [self requestJSONMethod:@"POST"
                       path:@"/v1/auth/reset-password"
                 parameters:@{
                     @"reset_token": token ?: @"",
                     @"password": password ?: @"",
                     @"user_pwd": password ?: @""
                 }
              authenticated:NO
                    success:success
                    failure:failure];
}

+ (void)registerWithEmail:(NSString *)email
                 password:(NSString *)password
                     name:(NSString *)name
                  success:(CzedrAPISuccessBlock)success
                  failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        failure(@"Legacy signup not wrapped");
        return;
    }
    [self registerSecureWithName:name
                          email:email
                       password:password
                    mobileNumber:@""
                        success:success
                        failure:failure];
}

+ (void)registerSecureWithName:(NSString *)name
                       email:(NSString *)email
                    password:(NSString *)password
                 mobileNumber:(NSString *)mobile
                     success:(CzedrAPISuccessBlock)success
                     failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        failure(@"Secure signup requires Czedr API");
        return;
    }
    NSDictionary *payload = @{
        @"user_name": name ?: @"",
        @"user_email": email ?: @"",
        @"email": email ?: @"",
        @"user_pwd": password ?: @"",
        @"password": password ?: @"",
        @"mobile_no": mobile ?: @""
    };
    void (^finishRegister)(NSDictionary *) = ^(NSDictionary *data) {
        NSDictionary *legacy = [self legacyUserPayloadFromV1:data];
        if (![legacy objectForKey:@"auth_code"] || [[legacy objectForKey:@"auth_code"] length] == 0) {
            NSString *token = [data objectForKey:@"auth_token"];
            if (token.length > 0) {
                NSMutableDictionary *fixed = [legacy mutableCopy];
                [fixed setObject:token forKey:@"auth_code"];
                legacy = fixed;
            }
        }
        NSMutableDictionary *withPin = [legacy mutableCopy];
        [withPin setObject:@"0" forKey:@"user_pin"];
        legacy = withPin;
        [self saveLoginPayload:legacy];
        success(legacy);
    };
    [self sendSecurePOSTToPath:@"/v1/auth/register-secure"
                       payload:payload
                   authenticated:NO
                         success:finishRegister
                         failure:failure];
}

+ (void)fetchLedgerBalanceSuccess:(CzedrAPISuccessBlock)success
                          failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"GET"
                       path:@"/v1/ledger/balance"
                 parameters:nil
              authenticated:YES
                    success:success
                    failure:failure];
}

+ (void)fetchReferralEarningsSuccess:(CzedrAPISuccessBlock)success
                           failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"GET"
                       path:@"/v1/referrals/earnings"
                 parameters:nil
              authenticated:YES
                    success:success
                    failure:failure];
}

+ (void)transferToCzedrId:(NSString *)czedrId
              amountCents:(NSInteger)amountCents
                     memo:(NSString *)memo
                      pin:(NSString *)pin
                  success:(CzedrAPISuccessBlock)success
                  failure:(CzedrAPIFailureBlock)failure
{
    NSString *key = [NSString stringWithFormat:@"ios-%@", [[NSUUID UUID] UUIDString]];
    [self requestJSONMethod:@"POST"
                       path:@"/v1/transfers"
                 parameters:@{
                     @"to_czedr_id": czedrId ?: @"",
                     @"amount_cents": @(amountCents),
                     @"idempotency_key": key,
                     @"memo": memo ?: @"Payment",
                     @"user_pin": pin ?: @""
                 }
              authenticated:YES
                    success:success
                    failure:failure];
}

+ (void)fetchPaymentHistorySuccess:(void (^)(NSArray *, NSInteger))success
                          failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"GET"
                       path:@"/v1/transfers/history"
                 parameters:nil
              authenticated:YES
                    success:^(NSDictionary *data) {
                        NSArray *txns = [data objectForKey:@"transactions"];
                        if (![txns isKindOfClass:[NSArray class]]) {
                            success(@[], 0);
                            return;
                        }
                        NSString *myId = [[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"];
                        NSMutableArray *rows = [NSMutableArray array];
                        for (NSDictionary *t in txns) {
                            if (![t isKindOfClass:[NSDictionary class]]) continue;
                            float amount = [[t objectForKey:@"amount_cents"] floatValue] / 100.0f;
                            NSString *from = [t objectForKey:@"from_czedr_id"] ?: @"";
                            NSString *to = [t objectForKey:@"to_czedr_id"] ?: @"";
                            BOOL sent = [from isEqualToString:myId];
                            [rows addObject:@{
                                @"name": [t objectForKey:@"memo"] ?: @"Transfer",
                                @"amount": @(amount),
                                @"email": sent ? to : from,
                                @"sender_user_id": from,
                                @"receiver_user_id": to,
                                @"cardnumber": @"0000"
                            }];
                        }
                        success(rows, (NSInteger)rows.count);
                    }
                    failure:failure];
}

+ (void)fetchLinkedAccountCountSuccess:(void (^)(NSInteger))success
                               failure:(CzedrAPIFailureBlock)failure
{
    [self fetchBankAccountsSuccess:^(NSArray *accounts) {
        success((NSInteger)accounts.count);
    } failure:failure];
}

+ (void)validateCzedrRecipient:(NSString *)czedrId
                       success:(void (^)(NSString *displayName))success
                       failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"GET" path:@"/v1/users/validate"
                 parameters:@{@"czedr_id": czedrId ?: @""}
              authenticated:YES
                    success:^(NSDictionary *data) {
                        success([data objectForKey:@"display_name"] ?: czedrId);
                    } failure:failure];
}

// Ledger-only API: POST /v1/bank-accounts returns HTTP 501; GET returns an empty list.
+ (void)addBankAccountHolder:(NSString *)holderName
                     routing:(NSString *)routing
                     account:(NSString *)account
                 accountType:(NSString *)accountType
                     success:(CzedrAPISuccessBlock)success
                     failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"POST" path:@"/v1/bank-accounts"
                 parameters:@{
                     @"holder_name": holderName ?: @"",
                     @"routing": routing ?: @"",
                     @"account": account ?: @"",
                     @"account_type": accountType ?: @"checking"
                 }
              authenticated:YES success:success failure:failure];
}

+ (void)deleteBankAccountId:(NSString *)bankAccountId
                    success:(CzedrAPISuccessBlock)success
                    failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"POST" path:@"/v1/bank-accounts/delete"
                 parameters:@{@"bank_account_id": bankAccountId ?: @""}
              authenticated:YES success:success failure:failure];
}

+ (void)fetchBankAccountsSuccess:(void (^)(NSArray *accounts))success
                         failure:(CzedrAPIFailureBlock)failure
{
    if ([self usesV1API]) {
        [self fetchLinkedCardsSuccess:success failure:failure];
        return;
    }
    [self requestJSONMethod:@"GET" path:@"/v1/bank-accounts" parameters:nil authenticated:YES
                    success:^(NSDictionary *data) {
                        NSArray *accounts = [data objectForKey:@"accounts"];
                        success([accounts isKindOfClass:[NSArray class]] ? accounts : @[]);
                    } failure:failure];
}

+ (void)fetchLinkedCardsSuccess:(void (^)(NSArray *cards))success
                        failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"GET" path:@"/v1/cards" parameters:nil authenticated:YES
                    success:^(NSDictionary *data) {
                        NSArray *cards = [data objectForKey:@"cards"];
                        success([cards isKindOfClass:[NSArray class]] ? cards : @[]);
                    } failure:failure];
}

+ (void)linkCardSecureWithJPEGData:(NSData *)jpegData
                           payload:(NSDictionary *)payload
                           success:(CzedrAPISuccessBlock)success
                           failure:(CzedrAPIFailureBlock)failure
{
    NSString *userId = [self savedCzedrUserId];
    if (userId.length == 0) {
        failure(@"Not signed in");
        return;
    }
    NSError *cryptoErr = nil;
    NSString *enc = [CzedrSignupCrypto encryptCardPayload:payload
                                                imageData:jpegData
                                                   userId:userId
                                                    error:&cryptoErr];
    if (!enc.length) {
        failure(cryptoErr.localizedDescription ?: @"Encryption failed");
        return;
    }
    NSString *imageB64 = [jpegData base64EncodedStringWithOptions:0];
    [self requestJSONMethod:@"POST" path:@"/v1/cards/link-secure"
                 parameters:@{
                     @"image_b64": imageB64 ?: @"",
                     @"enc_data": enc,
                     @"crypto_version": @([CzedrSignupCrypto preferredCryptoVersion])
                 }
              authenticated:YES success:success failure:failure];
}

+ (void)deleteLinkedCardId:(NSString *)cardId
                   success:(CzedrAPISuccessBlock)success
                   failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"POST" path:@"/v1/cards/delete"
                 parameters:@{@"card_id": cardId ?: @""}
              authenticated:YES success:success failure:failure];
}

+ (void)createInvoiceToCzedrId:(NSString *)czedrId
                        amount:(NSString *)amountDollars
                   description:(NSString *)description
                           pin:(NSString *)pin
                       success:(CzedrAPISuccessBlock)success
                       failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"POST" path:@"/v1/invoices"
                 parameters:@{
                     @"to_czedr_id": czedrId ?: @"",
                     @"rec_czedr_id": czedrId ?: @"",
                     @"amount": amountDollars ?: @"0",
                     @"desc": description ?: @"",
                     @"user_pin": pin ?: @""
                 }
              authenticated:YES success:success failure:failure];
}

+ (void)fetchReceivedInvoicesOffset:(NSInteger)offset
                              limit:(NSInteger)limit
                            success:(void (^)(NSArray *, NSInteger))success
                            failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"GET" path:@"/v1/invoices/received"
                 parameters:@{@"offset": @(offset), @"limit": @(limit)}
              authenticated:YES
                    success:^(NSDictionary *data) {
                        id rows = [data objectForKey:@"Data"] ?: data;
                        if (![rows isKindOfClass:[NSArray class]]) {
                            rows = @[];
                        }
                        NSInteger total = [[data objectForKey:@"Total_rows"] integerValue];
                        success((NSArray *)rows, total);
                    } failure:failure];
}

+ (void)fetchSentInvoicesOffset:(NSInteger)offset
                          limit:(NSInteger)limit
                        success:(void (^)(NSArray *, NSInteger))success
                        failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"GET" path:@"/v1/invoices/sent"
                 parameters:@{@"offset": @(offset), @"limit": @(limit)}
              authenticated:YES
                    success:^(NSDictionary *data) {
                        id rows = [data objectForKey:@"Data"] ?: data;
                        if (![rows isKindOfClass:[NSArray class]]) {
                            rows = @[];
                        }
                        NSInteger total = [[data objectForKey:@"Total_rows"] integerValue];
                        success((NSArray *)rows, total);
                    } failure:failure];
}

+ (NSURL *)profileImageURLForStoredName:(NSString *)storedName
{
    if (![storedName isKindOfClass:[NSString class]] || storedName.length == 0) {
        return nil;
    }
    NSString *encoded = [storedName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSString *base = [self apiBaseURLString];
    NSString *url = [NSString stringWithFormat:@"%@/v1/media/profile/%@", base, encoded ?: storedName];
    NSString *token = [self authToken];
    if (token.length > 0) {
        NSString *escaped = [token stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        url = [NSString stringWithFormat:@"%@?auth_code=%@", url, escaped ?: @""];
    }
    return [NSURL URLWithString:url];
}

+ (void)logoutWithSuccess:(void (^)(void))success
                  failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        failure(@"Logout requires Czedr API");
        return;
    }
    NSString *token = [self authToken];
    if (token.length == 0) {
        if (success) {
            success();
        }
        return;
    }
    [self requestJSONMethod:@"POST"
                       path:@"/v1/auth/logout"
                 parameters:nil
              authenticated:YES
                    success:^(__unused NSDictionary *data) {
                        if (success) {
                            success();
                        }
                    }
                    failure:failure];
}

+ (void)saveProfilePicFilename:(NSString *)filename
{
    if (![filename isKindOfClass:[NSString class]] || filename.length == 0) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setValue:filename forKey:@"profile_pic"];
    NSMutableDictionary *user = nil;
    id stored = [[NSUserDefaults standardUserDefaults] objectForKey:@"userDataArray"];
    if ([stored isKindOfClass:[NSDictionary class]]) {
        user = [stored mutableCopy];
    } else {
        user = [NSMutableDictionary dictionary];
    }
    [user setObject:filename forKey:@"profile_pic"];
    [user setObject:filename forKey:@"profile_pic "];
    [[NSUserDefaults standardUserDefaults] setValue:user forKey:@"userDataArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)uploadProfileImageData:(NSData *)jpegData
                       success:(CzedrAPISuccessBlock)success
                       failure:(CzedrAPIFailureBlock)failure
{
    if (!jpegData.length) {
        failure(@"No image data");
        return;
    }
    NSString *token = [self authToken];
    if (token.length == 0) {
        failure(@"Please sign in again");
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/v1/profile/avatar", [self apiBaseURLString]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *body = @{@"image_base64": [jpegData base64EncodedStringWithOptions:0]};
    NSError *jsonErr = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonErr];
    if (!bodyData) {
        failure(jsonErr.localizedDescription ?: @"Upload failed");
        return;
    }
    [request setHTTPBody:bodyData];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                failure(error.localizedDescription ?: @"Upload failed");
                return;
            }
            NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString *status = [NSString stringWithFormat:@"%@", json[@"Status"]];
            if ([status isEqualToString:@"true"]) {
                NSDictionary *payload = [json[@"Data"] isKindOfClass:[NSDictionary class]] ? json[@"Data"] : @{};
                success(payload);
                return;
            }
            failure([self messageFromAPIResponse:raw fallback:@"Upload failed"]);
        });
    }] resume];
}

+ (void)loadLinkedCardsForPickerSuccess:(void (^)(NSArray *))success
                                failure:(CzedrAPIFailureBlock)failure
{
    [self syncBankAccountsToCoreData:^{
        id delegate = [[UIApplication sharedApplication] delegate];
        if (![delegate respondsToSelector:@selector(managedObjectContext)]) {
            success(@[]);
            return;
        }
        NSManagedObjectContext *context = [delegate managedObjectContext];
        NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Cards"];
        NSArray *cards = [context executeFetchRequest:fetch error:nil] ?: @[];
        NSMutableArray *legacy = [NSMutableArray array];
        for (NSManagedObject *card in cards) {
            [legacy addObject:@{
                @"id": [card valueForKey:@"id"] ?: @"",
                @"name": [card valueForKey:@"name"] ?: @"",
                @"cardnumber": [card valueForKey:@"cardnumber"] ?: @"",
                @"month": [card valueForKey:@"month"] ?: @"",
                @"year": [card valueForKey:@"year"] ?: @"",
                @"card_default": [card valueForKey:@"card_default"] ?: @"0"
            }];
        }
        success(legacy);
    }];
}

+ (void)syncBankAccountsToCoreData:(void (^)(void))completion
{
    [self fetchBankAccountsSuccess:^(NSArray *accounts) {
        CzedrDispatchMain(^{
            id delegate = [[UIApplication sharedApplication] delegate];
            if (![delegate respondsToSelector:@selector(managedObjectContext)]) {
                if (completion) completion();
                return;
            }
            NSManagedObjectContext *context = [delegate managedObjectContext];
            if (!context) {
                if (completion) completion();
                return;
            }
            [context performBlockAndWait:^{
                @try {
                    NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Cards"];
                    NSArray *existing = [context executeFetchRequest:fetch error:nil] ?: @[];
                    for (NSManagedObject *obj in existing) {
                        [context deleteObject:obj];
                    }
                    for (NSDictionary *acct in accounts) {
                        if (![acct isKindOfClass:[NSDictionary class]]) continue;
                        if (![NSEntityDescription entityForName:@"Cards" inManagedObjectContext:context]) {
                            continue;
                        }
                        NSManagedObject *card = [NSEntityDescription insertNewObjectForEntityForName:@"Cards" inManagedObjectContext:context];
                        [card setValue:[acct objectForKey:@"id"] forKey:@"id"];
                        NSString *displayName = [acct objectForKey:@"display_name"] ?: [acct objectForKey:@"name"];
                        [card setValue:displayName forKey:@"name"];
                        NSString *last4 = [acct objectForKey:@"last4"] ?: [acct objectForKey:@"cardnumber"];
                        [card setValue:last4 forKey:@"cardnumber"];
                        [card setValue:[acct objectForKey:@"exp_month"] ?: @"01" forKey:@"month"];
                        [card setValue:[acct objectForKey:@"exp_year"] ?: @"30" forKey:@"year"];
                        [card setValue:[acct objectForKey:@"card_default"] ?: @"0" forKey:@"card_default"];
                    }
                    [context save:nil];
                } @catch (NSException *exception) {
                    (void)exception;
                }
            }];
            if (completion) completion();
        });
    } failure:^(NSString *message) {
        (void)message;
        CzedrDispatchMain(^{
            if (completion) completion();
        });
    }];
}

@end
