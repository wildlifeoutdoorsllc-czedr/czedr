//
//  CzedrConfig.h
//  Czedr — central URLs and feature flags (no external legacy hosts)
//

#ifndef CzedrConfig_h
#define CzedrConfig_h

/** 1 = Czedr API only; 0 = legacy-shaped paths on the same Czedr host */
#define CZEDR_USE_V1_API 1

/** Legacy OneSignal SDK (2015) crashes on modern iOS at launch — off until SDK is upgraded. */
#define CZEDR_ENABLE_ONESIGNAL 0

/** 1 = SwiftUI shell (Option B); 0 = legacy Objective-C + MMDrawer */
#define CZEDR_USE_SWIFTUI 1

/** Simulator: 127.0.0.1 — physical device: your PC LAN IP */
#define CZEDR_API_BASE "http://127.0.0.1:8080"

#define CZEDR_LEGACY_API              CZEDR_API_BASE "/v1/legacy/data"
#define CZEDR_LEGACY_CARD_DECRYPT     CZEDR_API_BASE "/v1/legacy/card/decrypt"
#define CZEDR_LEGACY_CARD_UPDATE      CZEDR_API_BASE "/v1/legacy/card/update"
#define CZEDR_LEGACY_IMAGE_UPLOAD     CZEDR_API_BASE "/v1/legacy/card/image"
#define CZEDR_LEGACY_PROFILE_UPLOAD   CZEDR_API_BASE "/v1/profile/avatar"
#define CZEDR_PROFILE_CDN             CZEDR_API_BASE "/v1/media/profile/"
#define CZEDR_PUSH_NOTIFY_IOS         CZEDR_API_BASE "/v1/notifications/dispatch"
#define CZEDR_PUSH_NOTIFY_ANDROID     CZEDR_API_BASE "/v1/notifications/dispatch"

/** Dev routing number when linking a bank account via the card screen (v1 only) */
#define CZEDR_DEV_ROUTING_NUMBER "021000021"

#endif
