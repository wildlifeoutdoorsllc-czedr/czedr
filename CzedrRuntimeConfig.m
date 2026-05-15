//
//  CzedrRuntimeConfig.m
//

#import "CzedrRuntimeConfig.h"
#import "CzedrConfig.h"

NSString * const CzedrAPIBaseUserDefaultsKey = @"czedr_api_base";

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
