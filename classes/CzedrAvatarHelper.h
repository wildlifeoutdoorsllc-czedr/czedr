//
//  CzedrAvatarHelper.h
//  Pick, crop, and upload profile avatars.
//

#import <UIKit/UIKit.h>

@class AsyncImageView;

@interface CzedrAvatarHelper : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

/** Photo library / camera sheet, square crop, upload to POST /v1/profile/avatar. */
+ (void)presentFromViewController:(UIViewController *)host
                       imageView:(UIImageView *)preview;

@end
