//
//  CzedrRuntimeConfig.h
//  Override API base without recompiling (after a dev build is installed).
//

#ifndef CzedrRuntimeConfig_h
#define CzedrRuntimeConfig_h

#import <Foundation/Foundation.h>

/** UserDefaults key: set to e.g. http://192.168.1.10:8080 */
FOUNDATION_EXPORT NSString * const CzedrAPIBaseUserDefaultsKey;

/** Last API base that responded to /v1/health (used for auto-discovery). */
FOUNDATION_EXPORT NSString * const CzedrLastGoodAPIBaseKey;

/** Compile-time default from CzedrConfig.h, or UserDefaults override when set. */
NSString *CzedrEffectiveAPIBase(void);

/** Last known working LAN API base, if any. */
NSString *CzedrLastGoodAPIBase(void);

/** Persist API base for subsequent requests (trims whitespace; empty clears override). */
void CzedrSetAPIBaseOverride(NSString *base);

/** Remember a base URL that passed /v1/health. */
void CzedrRememberLastGoodAPIBase(NSString *base);

#endif
