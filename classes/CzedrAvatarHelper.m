//
//  CzedrAvatarHelper.m
//

#import "CzedrAvatarHelper.h"
#import "SharedServiceController.h"
#import "HFImageEditorViewController.h"
#import "AsyncImageView.h"
#import "MBProgressHUD.h"
#import <objc/runtime.h>

@interface DemoImageEditor : HFImageEditorViewController
@end

static const void *kCzedrAvatarHelperAssocKey = &kCzedrAvatarHelperAssocKey;

@interface CzedrAvatarHelper ()
@property (nonatomic, weak) UIViewController *host;
@property (nonatomic, weak) UIImageView *preview;
@property (nonatomic, strong) UIImagePickerController *picker;
@end

@implementation CzedrAvatarHelper

+ (void)presentFromViewController:(UIViewController *)host imageView:(UIImageView *)preview
{
    if (!host || !preview) {
        return;
    }
    CzedrAvatarHelper *helper = [[CzedrAvatarHelper alloc] init];
    helper.host = host;
    helper.preview = preview;
    objc_setAssociatedObject(host, kCzedrAvatarHelperAssocKey, helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    NSString *title = NSLocalizedString(@"Profile Picture", nil);
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title
                                                                   message:NSLocalizedString(@"Choose a photo for your avatar", nil)
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Photo Library", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction *a) {
        [helper openPicker:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Take Photo", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(__unused UIAlertAction *a) {
            [helper openPicker:UIImagePickerControllerSourceTypeCamera];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:^(__unused UIAlertAction *a) {
        [helper detach];
    }]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = preview;
        sheet.popoverPresentationController.sourceRect = preview.bounds;
    }
    [host presentViewController:sheet animated:YES completion:nil];
}

- (void)openPicker:(UIImagePickerControllerSourceType)sourceType
{
    self.picker = [[UIImagePickerController alloc] init];
    self.picker.delegate = self;
    self.picker.sourceType = sourceType;
    self.picker.allowsEditing = NO;
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        self.picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    [self.host presentViewController:self.picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (![image isKindOfClass:[UIImage class]]) {
        [picker dismissViewControllerAnimated:YES completion:nil];
        [self detach];
        return;
    }
    DemoImageEditor *editor = [[DemoImageEditor alloc] initWithNibName:@"DemoImageEditor" bundle:nil];
    editor.sourceImage = image;
    editor.previewImage = image;
    editor.checkBounds = YES;
    editor.rotateEnabled = YES;
    editor.cropSize = CGSizeMake(400, 400);
    __weak typeof(self) weakSelf = self;
    editor.doneCallback = ^(UIImage *editedImage, BOOL canceled) {
        [picker dismissViewControllerAnimated:YES completion:^{
            if (!canceled && editedImage) {
                [weakSelf uploadImage:editedImage];
            } else {
                [weakSelf detach];
            }
        }];
    };
    [picker pushViewController:editor animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self detach];
    }];
}

- (UIImage *)scaledJPEGFromImage:(UIImage *)image
{
    CGSize size = CGSizeMake(400, 400);
    UIGraphicsBeginImageContextWithOptions(size, YES, 1.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaled = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaled;
}

- (void)uploadImage:(UIImage *)image
{
    UIImage *scaled = [self scaledJPEGFromImage:image];
    NSData *jpeg = UIImageJPEGRepresentation(scaled, 0.85);
    if (!jpeg.length) {
        [self showMessage:NSLocalizedString(@"Could not prepare image", nil)];
        [self detach];
        return;
    }
    self.preview.image = scaled;
    [MBProgressHUD showHUDAddedTo:self.host.view animated:YES];
    [SharedServiceController uploadProfileImageData:jpeg success:^(NSDictionary *data) {
        [MBProgressHUD hideHUDForView:self.host.view animated:YES];
        NSString *pic = [data objectForKey:@"profile_pic"] ?: [data objectForKey:@"profile_pic "];
        if (pic.length > 0) {
            [SharedServiceController saveProfilePicFilename:pic];
            [self refreshPreviewWithFilename:pic];
        }
        [self showMessage:NSLocalizedString(@"Profile photo updated", nil)];
        [self detach];
    } failure:^(NSString *message) {
        [MBProgressHUD hideHUDForView:self.host.view animated:YES];
        [self showMessage:message ?: NSLocalizedString(@"Upload failed", nil)];
        [self detach];
    }];
}

- (void)refreshPreviewWithFilename:(NSString *)filename
{
    NSURL *url = [SharedServiceController profileImageURLForStoredName:filename];
    if ([self.preview isKindOfClass:[AsyncImageView class]]) {
        ((AsyncImageView *)self.preview).imageURL = url;
    } else if (url) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *img = data ? [UIImage imageWithData:data] : nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (img) {
                    self.preview.image = img;
                }
            });
        });
    }
}

- (void)showMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self.host presentViewController:alert animated:YES completion:nil];
}

- (void)detach
{
    objc_setAssociatedObject(self.host, kCzedrAvatarHelperAssocKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
