//
//  SharedServiceController.h
//  Czedr
//

#import <Foundation/Foundation.h>
#import "SBJSON.h"
#import "MBProgressHUD.h"
#import "ReachabiltyTest.h"
#import "AFNetworking.h"
#import "CzedrConfig.h"

#if CZEDR_USE_V1_API
#define base_url CZEDR_API_BASE
#else
#define base_url CZEDR_LEGACY_API
#endif

BOOL payNowBool;

typedef void (^CzedrAPISuccessBlock)(NSDictionary *data);
typedef void (^CzedrAPIFailureBlock)(NSString *message);

@interface SharedServiceController : NSObject

+ (BOOL)usesV1API;
+ (NSString *)apiBaseURLString;
+ (NSString *)authToken;

/** Persist login session (auth_code + userDataArray) from v1 or legacy response payload. */
+ (void)saveLoginPayload:(NSDictionary *)data;

+ (void)loginWithEmail:(NSString *)email
              password:(NSString *)password
               success:(CzedrAPISuccessBlock)success
               failure:(CzedrAPIFailureBlock)failure;

/** Image-derived encryption before login (no plaintext credentials on the wire). */
+ (void)loginSecureWithEmail:(NSString *)email
                    password:(NSString *)password
                     success:(CzedrAPISuccessBlock)success
                     failure:(CzedrAPIFailureBlock)failure;

+ (void)verifyPinSecure:(NSString *)pin
                success:(CzedrAPISuccessBlock)success
                failure:(CzedrAPIFailureBlock)failure;

+ (void)updatePinSecureOldPin:(NSString *)oldPin
                       newPin:(NSString *)newPin
                      success:(CzedrAPISuccessBlock)success
                      failure:(CzedrAPIFailureBlock)failure;

+ (void)setPinSecure:(NSString *)pin
             success:(CzedrAPISuccessBlock)success
             failure:(CzedrAPIFailureBlock)failure;

+ (void)requestPasswordResetForEmail:(NSString *)email
                             success:(CzedrAPISuccessBlock)success
                             failure:(CzedrAPIFailureBlock)failure;

+ (void)completePasswordResetWithToken:(NSString *)token
                           newPassword:(NSString *)password
                               success:(CzedrAPISuccessBlock)success
                               failure:(CzedrAPIFailureBlock)failure;

+ (void)registerWithEmail:(NSString *)email
                 password:(NSString *)password
                     name:(NSString *)name
                  success:(CzedrAPISuccessBlock)success
                  failure:(CzedrAPIFailureBlock)failure;

/** Fetches a random LoC image, encrypts signup fields, then registers (no plaintext on the wire). */
+ (void)registerSecureWithName:(NSString *)name
                       email:(NSString *)email
                    password:(NSString *)password
                 mobileNumber:(NSString *)mobile
                     success:(CzedrAPISuccessBlock)success
                     failure:(CzedrAPIFailureBlock)failure;

+ (void)fetchLedgerBalanceSuccess:(CzedrAPISuccessBlock)success
                          failure:(CzedrAPIFailureBlock)failure;

+ (void)transferToCzedrId:(NSString *)czedrId
              amountCents:(NSInteger)amountCents
                     memo:(NSString *)memo
                  success:(CzedrAPISuccessBlock)success
                  failure:(CzedrAPIFailureBlock)failure;

+ (void)validateCzedrRecipient:(NSString *)czedrId
                       success:(void (^)(NSString *displayName))success
                       failure:(CzedrAPIFailureBlock)failure;

+ (void)addBankAccountHolder:(NSString *)holderName
                     routing:(NSString *)routing
                     account:(NSString *)account
                 accountType:(NSString *)accountType
                     success:(CzedrAPISuccessBlock)success
                     failure:(CzedrAPIFailureBlock)failure;

+ (void)deleteBankAccountId:(NSString *)bankAccountId
                    success:(CzedrAPISuccessBlock)success
                    failure:(CzedrAPIFailureBlock)failure;

+ (void)fetchBankAccountsSuccess:(void (^)(NSArray *accounts))success
                         failure:(CzedrAPIFailureBlock)failure;

+ (void)syncBankAccountsToCoreData:(void (^)(void))completion;

/** Returns legacy-shaped rows: name, amount, email, sender_user_id, receiver_user_id, cardnumber */
+ (void)fetchPaymentHistorySuccess:(void (^)(NSArray *rows, NSInteger total))success
                          failure:(CzedrAPIFailureBlock)failure;

+ (void)fetchLinkedAccountCountSuccess:(void (^)(NSInteger count))success
                               failure:(CzedrAPIFailureBlock)failure;

+ (void)createInvoiceToCzedrId:(NSString *)czedrId
                        amount:(NSString *)amountDollars
                   description:(NSString *)description
                       success:(CzedrAPISuccessBlock)success
                       failure:(CzedrAPIFailureBlock)failure;

+ (void)fetchReceivedInvoicesOffset:(NSInteger)offset
                              limit:(NSInteger)limit
                            success:(void (^)(NSArray *rows, NSInteger total))success
                            failure:(CzedrAPIFailureBlock)failure;

+ (void)fetchSentInvoicesOffset:(NSInteger)offset
                          limit:(NSInteger)limit
                        success:(void (^)(NSArray *rows, NSInteger total))success
                        failure:(CzedrAPIFailureBlock)failure;

+ (void)loadLinkedCardsForPickerSuccess:(void (^)(NSArray *cards))success
                                failure:(CzedrAPIFailureBlock)failure;

/** Builds profile image URL on the Czedr API (replaces legacy S3 hosts). */
+ (NSURL *)profileImageURLForStoredName:(NSString *)storedName;

+ (void)uploadProfileImageData:(NSData *)jpegData
                       success:(CzedrAPISuccessBlock)success
                       failure:(CzedrAPIFailureBlock)failure;

@end
