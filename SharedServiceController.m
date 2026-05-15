//
//  SharedServiceController.m
//  Czedr
//

#import "SharedServiceController.h"
#import "CzedrSignupCrypto.h"
#import "CzedrRuntimeConfig.h"
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

+ (void)saveLoginPayload:(NSDictionary *)data
{
    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *auth = [data objectForKey:@"auth_code"];
    if (auth.length > 0) {
        [[NSUserDefaults standardUserDefaults] setValue:auth forKey:@"auth_codeSaved"];
    }
    [[NSUserDefaults standardUserDefaults] setValue:data forKey:@"userDataArray"];
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
    return @{
        @"auth_code": [data objectForKey:@"auth_code"] ?: @"",
        @"id": czedrId,
        @"czedr_id": czedrId,
        @"email": email,
        @"email ": email,
        @"user_pin": [data objectForKey:@"user_pin"] ?: @"0",
        @"profile_pic ": @"",
        @"user": user ?: @{}
    };
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
                        NSString *imageUrl = [challenge objectForKey:@"image_url"];
                        if (challengeId.length == 0 || imageUrl.length == 0) {
                            failure(@"Could not start secure request");
                            return;
                        }
                        [CzedrSignupCrypto fetchImageDataFromURL:imageUrl
                                                      completion:^(NSData *imageData, NSError *err) {
                            if (err || !imageData.length) {
                                failure(err.localizedDescription ?: @"Could not load encryption image");
                                return;
                            }
                            NSError *cryptErr = nil;
                            NSString *enc = [CzedrSignupCrypto encryptPayload:payload
                                                                     imageData:imageData
                                                                   challengeId:challengeId
                                                                         error:&cryptErr];
                            if (!enc.length) {
                                failure(cryptErr.localizedDescription ?: @"Encryption failed");
                                return;
                            }
                            [self requestJSONMethod:@"POST"
                                               path:path
                                         parameters:@{
                                             @"challenge_id": challengeId,
                                             @"enc_data": enc
                                         }
                                      authenticated:authenticated
                                            success:success
                                            failure:failure];
                        }];
                    }
                    failure:failure];
}

+ (void)requestJSONMethod:(NSString *)method
                      path:(NSString *)path
                parameters:(NSDictionary *)params
             authenticated:(BOOL)authenticated
                   success:(CzedrAPISuccessBlock)success
                   failure:(CzedrAPIFailureBlock)failure
{
    NSString *url = [NSString stringWithFormat:@"%@%@", [self apiBaseURLString], path];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    if (authenticated) {
        NSString *token = [self authToken];
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token]
                         forHTTPHeaderField:@"Authorization"];
    }
    void (^ok)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = [NSString stringWithFormat:@"%@", operation.responseString];
        NSDictionary *json = [[response JSONValue] isKindOfClass:[NSDictionary class]] ? [response JSONValue] : nil;
        NSString *status = [NSString stringWithFormat:@"%@", [json objectForKey:@"Status"]];
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
            NSString *msg = @"Request failed";
            id errData = [json objectForKey:@"Data"];
            if ([errData isKindOfClass:[NSArray class]] && [[errData firstObject] isKindOfClass:[NSDictionary class]]) {
                msg = [[errData firstObject] objectForKey:@"result"] ?: msg;
            }
            failure(msg);
        }
    };
    void (^fail)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error.localizedDescription ?: @"Network error");
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

+ (void)loginSecureWithEmail:(NSString *)email
                    password:(NSString *)password
                     success:(CzedrAPISuccessBlock)success
                     failure:(CzedrAPIFailureBlock)failure
{
    if (![self usesV1API]) {
        failure(@"Secure login requires Czedr API");
        return;
    }
    NSDictionary *payload = @{
        @"user_email": email ?: @"",
        @"email": email ?: @"",
        @"user_pwd": password ?: @"",
        @"password": password ?: @""
    };
    [self sendSecurePOSTToPath:@"/v1/auth/login-secure"
                       payload:payload
                   authenticated:NO
                         success:^(NSDictionary *data) {
                             NSDictionary *legacy = [self legacyUserPayloadFromV1:data];
                             [self saveLoginPayload:legacy];
                             success(legacy);
                         }
                         failure:failure];
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
        failure(@"Secure PIN set requires Czedr API");
        return;
    }
    [self sendSecurePOSTToPath:@"/v1/auth/pin/set-secure"
                       payload:@{@"user_pin": pin ?: @""}
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
    [self sendSecurePOSTToPath:@"/v1/auth/register-secure"
                       payload:payload
                   authenticated:NO
                         success:^(NSDictionary *data) {
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
                         }
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

+ (void)transferToCzedrId:(NSString *)czedrId
              amountCents:(NSInteger)amountCents
                     memo:(NSString *)memo
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
                     @"memo": memo ?: @"Payment"
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
    [self requestJSONMethod:@"GET" path:@"/v1/bank-accounts" parameters:nil authenticated:YES
                    success:^(NSDictionary *data) {
                        NSArray *accounts = [data objectForKey:@"accounts"];
                        success([accounts isKindOfClass:[NSArray class]] ? accounts : @[]);
                    } failure:failure];
}

+ (void)createInvoiceToCzedrId:(NSString *)czedrId
                        amount:(NSString *)amountDollars
                   description:(NSString *)description
                       success:(CzedrAPISuccessBlock)success
                       failure:(CzedrAPIFailureBlock)failure
{
    [self requestJSONMethod:@"POST" path:@"/v1/invoices"
                 parameters:@{
                     @"to_czedr_id": czedrId ?: @"",
                     @"rec_czedr_id": czedrId ?: @"",
                     @"amount": amountDollars ?: @"0",
                     @"desc": description ?: @""
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
    return [NSURL URLWithString:[NSString stringWithFormat:@"%s%@", CZEDR_PROFILE_CDN, encoded ?: storedName]];
}

+ (void)uploadProfileImageData:(NSData *)jpegData
                       success:(CzedrAPISuccessBlock)success
                       failure:(CzedrAPIFailureBlock)failure
{
    if (!jpegData.length) {
        failure(@"No image data");
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%s/v1/profile/avatar", CZEDR_API_BASE];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", [self authToken]] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *body = @{@"image_base64": [jpegData base64EncodedStringWithOptions:0]};
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                failure(error.localizedDescription ?: @"Upload failed");
                return;
            }
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString *status = [NSString stringWithFormat:@"%@", json[@"Status"]];
            if ([status isEqualToString:@"true"]) {
                NSDictionary *payload = [json[@"Data"] isKindOfClass:[NSDictionary class]] ? json[@"Data"] : @{};
                success(payload);
            } else {
                failure(@"Upload failed");
            }
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
        NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Cards"];
        NSArray *existing = [context executeFetchRequest:fetch error:nil];
        for (NSManagedObject *obj in existing) {
            [context deleteObject:obj];
        }
        for (NSDictionary *acct in accounts) {
            if (![acct isKindOfClass:[NSDictionary class]]) continue;
            NSManagedObject *card = [NSEntityDescription insertNewObjectForEntityForName:@"Cards" inManagedObjectContext:context];
            [card setValue:[acct objectForKey:@"id"] forKey:@"id"];
            [card setValue:[acct objectForKey:@"display_name"] forKey:@"name"];
            [card setValue:[acct objectForKey:@"last4"] forKey:@"cardnumber"];
            [card setValue:@"01" forKey:@"month"];
            [card setValue:@"30" forKey:@"year"];
            [card setValue:@"0" forKey:@"card_default"];
        }
        [context save:nil];
        if (completion) completion();
    } failure:^(NSString *message) {
        if (completion) completion();
    }];
}

@end
