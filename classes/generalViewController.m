//
//  generalViewController.m
//  payoox
//
//  Created by Renu on 13/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import "generalViewController.h"
#import "CzedrTheme.h"
#import "SharedServiceController.h"
#import "changePasswordViewController.h"
#import "ChangePinViewController.h"
#import "forgotViewController.h"
#import "CzedrAvatarHelper.h"
@interface generalViewController ()
@end



@implementation generalViewController
-(void)viewWillAppear:(BOOL)animated
{
    _name.text=[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"name"];
     _emailAddress.text=[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"email "];
     _contactNumber.text=[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"mobile_no"];
    [CzedrTheme applyLoggedInDarkScreenToView:self.view];
    [CzedrTheme styleEmailField:_emailAddress];
    [self refreshProfilePhoto];
}

- (void)refreshProfilePhoto
{
    [[AsyncImageLoader sharedLoader].cache removeAllObjects];
    NSString *pic = [[NSUserDefaults standardUserDefaults] valueForKey:@"profile_pic"];
    profilepic.imageURL = [SharedServiceController profileImageURLForStoredName:pic];
    if (pic.length == 0) {
        profilepic.image = [UIImage imageNamed:@"pro_icon.png"];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //[AsyncImageLoader sharedLoader].cache = nil;
    [[AsyncImageLoader sharedLoader].cache removeAllObjects];

    profilepic.imageURL = [SharedServiceController profileImageURLForStoredName:[[NSUserDefaults standardUserDefaults] valueForKey:@"profile_pic"]];
    
    NSURL *uu = [SharedServiceController profileImageURLForStoredName:[[NSUserDefaults standardUserDefaults] valueForKey:@"profile_pic"]];
    
    profilepic.layer.cornerRadius=profilepic.frame.size.height/2;
    profilepic.layer.masksToBounds=YES;

    NSString *strTitleLbl = NSLocalizedString(@"GENERAL INFO", Nil);
    titleLbl.text = strTitleLbl;
    
    NSString *strName = NSLocalizedString(@"Name", Nil);
    nameLbl.text = strName;
    

    NSString *strEmail = NSLocalizedString(@"email address", Nil);
    email.text = [strEmail capitalizedString];
    
    NSString *strContactNo = NSLocalizedString(@"Contact Number", Nil);
    contactNo.text = strContactNo;
    
    NSString *strProfilePic = NSLocalizedString(@"Profile Picture", Nil);
    profilePic.text = strProfilePic;
    
    NSString *strUpdateProfile = NSLocalizedString(@"Update Profile", Nil);
    [updateProfile setTitle: strUpdateProfile forState: UIControlStateNormal];
    
    NSString *strChangePwd = NSLocalizedString(@"Change Password", Nil);
    [changePwd setTitle: strChangePwd forState: UIControlStateNormal];
    
    NSString *strChangePin = NSLocalizedString(@"Change Pin", Nil);
    [changePin setTitle: strChangePin forState: UIControlStateNormal];
    
    NSString *strForgotPin = NSLocalizedString(@"Forgot Pin", Nil);
    [ForgotPin setTitle: strForgotPin forState: UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    //Dispose of any resources that can be recreated.
}


- (IBAction)backButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)profilebtnClick:(id)sender
{
    [_name resignFirstResponder];
    [_contactNumber resignFirstResponder];
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    [CzedrAvatarHelper presentFromViewController:self imageView:profilepic];
}

#pragma mark alertview
-(void)messageCode
{
    NSString *strGallery = NSLocalizedString(@"from gallery", Nil);
    NSString *strCancel = NSLocalizedString(@"Cancel", Nil);
    NSString *strOpenCamera = NSLocalizedString(@"Open Camera", Nil);
    
    backView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
     if ([[UIScreen mainScreen] bounds].size.height == 568.0f||[[UIScreen mainScreen] bounds].size.height == 480.0f)
     {
         AlerView1=[[UIView alloc]initWithFrame:CGRectMake(23, 190, 280, 200)];
     }
    else if ([[UIScreen mainScreen] bounds].size.height == 667.0f) {
         AlerView1=[[UIView alloc]initWithFrame:CGRectMake(47, 190, 280, 200)];
    }
    else
    {
         AlerView1=[[UIView alloc]initWithFrame:CGRectMake(66, 190, 280, 200)];
    }
    backView.backgroundColor=[UIColor colorWithWhite:0 alpha:0.3];
    AlerView1.backgroundColor=[UIColor whiteColor];
    UILabel *titleLbl=[[UILabel alloc]initWithFrame:CGRectMake(10, 0, 280, 50)];
        titleLbl.text=@"Pick an Image";
    titleLbl.backgroundColor=[UIColor clearColor];
    [titleLbl setTextColor:[UIColor colorWithRed:55/255.0 green:181/255.0 blue:229/255.0 alpha:1.0]];
    [AlerView1 addSubview:titleLbl];
    
    UIView *line1=[[UIView alloc]initWithFrame:CGRectMake(0, 50, 280, 2)];
    line1.backgroundColor=[UIColor colorWithRed:55/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
    [AlerView1 addSubview:line1];
    
    UIButton *chosseGalleryButton=[UIButton buttonWithType:UIButtonTypeCustom];
    chosseGalleryButton.frame=CGRectMake(10, 55, 280, 40);
    [chosseGalleryButton setTitle:strGallery forState:UIControlStateNormal];
    [chosseGalleryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [chosseGalleryButton addTarget:self action:@selector(galleryClick:) forControlEvents:UIControlEventTouchUpInside];
     [AlerView1 addSubview:chosseGalleryButton];
    UIView *linefr3=[[UIView alloc]initWithFrame:CGRectMake(0, 100, 280, 1)];
    linefr3.backgroundColor=[UIColor colorWithRed:209/255.0 green:209/255.0 blue:209/255.0 alpha:1.0];
    [AlerView1 addSubview:linefr3];
    
    UIButton *camraButton=[UIButton buttonWithType:UIButtonTypeCustom];
    camraButton.frame=CGRectMake(10, 102, 280, 40);
    [camraButton setTitle:strOpenCamera forState:UIControlStateNormal];
    [camraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [camraButton addTarget:self action:@selector(camraClick:) forControlEvents:UIControlEventTouchUpInside];
     [AlerView1 addSubview:camraButton];
    UIView *linefr=[[UIView alloc]initWithFrame:CGRectMake(0, 150, 280, 1)];
    linefr.backgroundColor=[UIColor colorWithRed:209/255.0 green:209/255.0 blue:209/255.0 alpha:1.0];
    [AlerView1 addSubview:linefr];
        UIButton *okButton=[UIButton buttonWithType:UIButtonTypeCustom];
    okButton.frame=CGRectMake(10, 153, 280, 40);
    [okButton setTitle:strCancel forState:UIControlStateNormal];
    [okButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [okButton addTarget:self action:@selector(okBackClick:) forControlEvents:UIControlEventTouchUpInside];
    
    okButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    camraButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    chosseGalleryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [AlerView1 addSubview:okButton];
    [backView addSubview:AlerView1];
    [self.view addSubview:backView];
}

//- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
//    [backView removeFromSuperview];
//}

-(IBAction)okBackClick:(id)sender
{
    [backView removeFromSuperview];
}

-(IBAction)galleryClick:(id)sender
{
    if (backView) {
        [backView removeFromSuperview];
    }
    [CzedrAvatarHelper presentFromViewController:self imageView:profilepic];
}

-(IBAction)camraClick:(id)sender
{
    if (backView) {
        [backView removeFromSuperview];
    }
    [CzedrAvatarHelper presentFromViewController:self imageView:profilepic];
}

-(IBAction)updateprofile_click:(id)sender
{
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    [_name resignFirstResponder];
    [_contactNumber resignFirstResponder];
    if (_name.text.length==0)
    {
        NSString *str = NSLocalizedString(@"enter username", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if (_contactNumber.text.length==0)
    {
        NSString *str = NSLocalizedString(@"enter contact number", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
        else
        {
            NSString *rawString = [_name text];
            NSString *rawString2 = [_contactNumber text];
            
            NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
            NSString *trimmed2 = [rawString2 stringByTrimmingCharactersInSet:whitespace];
            
            if ([trimmed length] == 0 || [trimmed2 length] == 0)
            {
                NSString *strAttention = NSLocalizedString(@"Attention", Nil);
                NSString *strCorrectValues = NSLocalizedString(@"correct values", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strAttention message:strCorrectValues delegate:nil cancelButtonTitle:strOk otherButtonTitles: nil];
                [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
            }
            else
            {
                [self update_profile];
            }
        }
}

-(IBAction)changepasswordClik:(id)sender
{
    changePasswordViewController *obj=[[changePasswordViewController alloc]initWithNibName:@"changePasswordViewController" bundle:nil];
    [self.navigationController pushViewController:obj animated:YES];
}

-(IBAction)changePinClick:(id)sender
{
    ChangePinViewController *obj=[[ChangePinViewController alloc]initWithNibName:@"ChangePinViewController" bundle:nil];
    [self.navigationController pushViewController:obj animated:YES];
}

-(IBAction)forgot_Pin:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setValue:@"forgot" forKey:@"pin"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    forgotViewController *forgotViewControllerobj=[[forgotViewController alloc]initWithNibName:@"forgotViewController" bundle:nil];
    [self.navigationController pushViewController:forgotViewControllerobj animated:YES];
}

-(void)update_profile
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int reach = [reachAbilty updateInterfaceWithReachability];
    if (reach==0)
    {
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else
    {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        NSString* authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:_name.text forKey:@"user_name"];
        [params setValue:_contactNumber.text forKey:@"mobile_no"];
        [params setValue:@"0" forKey:@"auto_accept"];
        
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"updateprofile"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 NSString *str = NSLocalizedString(@"Profile Updated", Nil);
                 NSString *strOk = NSLocalizedString(@"OK", Nil);

                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                 [alert show];
                 NSMutableDictionary *dic=[[NSMutableDictionary alloc]init];
                 
                 NSString* authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
                [dic setValue:authCodeStr forKey:@"auth_code"];
                [dic setValue:[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"email "] forKey:@"email "];
                [dic setValue:[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"] forKey:@"id"];
                [dic setValue:_contactNumber.text forKey:@"mobile_no"];
                [dic setValue:_name.text forKey:@"name"];
                [dic setValue:[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"profile_pic "] forKey:@"profile_pic "];
                  [dic setValue:[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"user_pin"] forKey:@"user_pin"];
                 [[NSUserDefaults standardUserDefaults] setValue:dic forKey:@"userDataArray"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
        
                 return;
             }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([Alertstatus isEqual:@"Data is missing"])
                     {
                         Alertstatus = @"Données manquantes";
                     }
                     else if ([Alertstatus isEqual:@"Data Updated"])
                     {
                         Alertstatus = @"Données mises à jour";
                     }
                 }
                 
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                 [alert show];
                 return;
             }
         }
              failure:^(AFHTTPRequestOperation *operation, NSError *error)
        {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            NSString *strErrorMsg = NSLocalizedString(@"error", Nil);
            NSString *strOk = NSLocalizedString(@"OK", Nil);
            
            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strErrorMsg delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
            [alert show];
              }];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField==_emailAddress)
    {
            return NO;
    }
    if (textField==_contactNumber)
    {
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -10, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField==_name)
    {
        [_contactNumber becomeFirstResponder];
    }
    if (textField==_contactNumber) {
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
        [_name resignFirstResponder];
        [_contactNumber resignFirstResponder];
    }
    return YES;
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(void)photoUpload_service
{
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int i = [reachAbilty updateInterfaceWithReachability];
    if (i==0)
    {
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else
    {
        UIImage *getImage=[self imageWithImage:profilepic.image scaledToSize:CGSizeMake(200, 200)];
        NSData *myData=UIImageJPEGRepresentation(getImage,0.8);
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSMutableURLRequest *request;
    
        if ([SharedServiceController usesV1API]) {
            [SharedServiceController uploadProfileImageData:myData success:^(NSDictionary *data) {
                NSString *pic = [data objectForKey:@"profile_pic"] ?: [data objectForKey:@"profile_pic "];
                if (pic.length > 0) {
                    [SharedServiceController saveProfilePicFilename:pic];
                    [self refreshProfilePhoto];
                }
                NSString *str = NSLocalizedString(@"User Image Uploaded", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                [alert show];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            } failure:^(NSString *message) {
                NSString *str = NSLocalizedString(@"User Image not Uploaded", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                [alert show];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            }];
            return;
        }
        NSString *urlString = @CZEDR_LEGACY_PROFILE_UPLOAD;
        
        NSString* result =[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"];
        request= [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"POST"];
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        NSMutableData *postbody = [NSMutableData data];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"user_pic\"; filename=\"%@.jpg\"\r\n",result] dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        
        
        [postbody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[NSData dataWithData:myData]];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:postbody];
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString *returnString;
        returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        if ([[[returnString JSONValue] valueForKey:@"Status"] isEqualToString:@"true"])
        {
            [self upload_textimage];
        }
        else
        {
            NSString *str = NSLocalizedString(@"User Image not Uploaded", Nil);
            NSString *strOk = NSLocalizedString(@"OK", Nil);

            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
            [alert show];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }
}

-(void)upload_textimage
{
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int reach = [reachAbilty updateInterfaceWithReachability];
    if (reach==0)
    {
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else
    {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
         NSString *authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"userimage"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 NSString *result =[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"];
                [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%@.jpg",result] forKey:@"profile_pic"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                 
                 NSString *str = NSLocalizedString(@"User Image Uploaded", Nil);
                 NSString *strOk = NSLocalizedString(@"OK", Nil);

                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                 [alert show];
             }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([Alertstatus isEqual:@"Data is missing"])
                     {
                         Alertstatus = @"Données manquantes";
                     }
                 }
                 
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                 [alert show];
                 return;
             }
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
                  NSString *strErrorMsg = NSLocalizedString(@"error", Nil);
                  NSString *strOk = NSLocalizedString(@"OK", Nil);
                  
                  UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strErrorMsg delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                  [alert show];
              }];
    }
}
@end
