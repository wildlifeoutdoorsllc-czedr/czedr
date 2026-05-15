//
//  PlaceholderTextView.h
//  CabProjectUniversal
//
//  Created by Graycell on 07/11/13.
//  Copyright (c) 2013 Graycell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlaceholderTextView : UITextView
{
    UILabel *placeholderLabel;
    NSString *placeholderText;
}
@property (nonatomic, retain) NSString *placeholderText;
@end
