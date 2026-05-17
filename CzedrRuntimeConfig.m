//
//  CzedrRuntimeConfig.m
//

#import "CzedrRuntimeConfig.h"
#import "CzedrConfig.h"

NSString * const CzedrAPIBaseUserDefaultsKey = @"czedr_api_base";
NSString * const CzedrLastGoodAPIBaseKey = @"czedr_last_good_api_base";

static NSString *CzedrTrimmedBase(NSString *base)
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

NSString *CzedrLastGoodAPIBase(void)
{
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:CzedrLastGoodAPIBaseKey];
    return CzedrTrimmedBase(saved);
}

void CzedrRememberLastGoodAPIBase(NSString *base)
{
    NSString *trimmed = CzedrTrimmedBase(base);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (trimmed.length > 0) {
        [defaults setObject:trimmed forKey:CzedrLastGoodAPIBaseKey];
    } else {
        [defaults removeObjectForKey:CzedrLastGoodAPIBaseKey];
    }
    [defaults synchronize];
}

NSString *CzedrEffectiveAPIBase(void)
{
    NSString *override = [[NSUserDefaults standardUserDefaults] stringForKey:CzedrAPIBaseUserDefaultsKey];
    if (override.length > 0) {
        return [override stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
#if CZEDR_USE_V1_API
    return @CZEDR_API_BASE;
#else
    return @CZEDR_LEGACY_API;
#endif
}

void CzedrSetAPIBaseOverride(NSString *base)
{
    NSString *trimmed = CzedrTrimmedBase(base);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (trimmed.length > 0) {
        [defaults setObject:trimmed forKey:CzedrAPIBaseUserDefaultsKey];
    } else {
        [defaults removeObjectForKey:CzedrAPIBaseUserDefaultsKey];
    }
    [defaults synchronize];
}
