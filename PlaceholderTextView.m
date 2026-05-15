//
//  PlaceholderTextView.m
//  CabProjectUniversal
//
//  Created by Graycell on 07/11/13.
//  Copyright (c) 2013 Graycell. All rights reserved.
//

#import "PlaceholderTextView.h"

@implementation PlaceholderTextView

//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code
//    }
//    return self;
//}
@synthesize placeholderText;

- (void)hidePlaceholder {
    if ([placeholderLabel superview]) {
        [placeholderLabel removeFromSuperview];
    }
}

- (void)maybeShowPlaceholder {
    if ([placeholderText length] > 0) {
        if (![self hasText] && ![placeholderLabel superview]) {
            CGRect frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
            placeholderLabel.frame = frame;
            placeholderLabel.text = placeholderText;
            [self addSubview:placeholderLabel];
        }
    }
}

- (void)initCommon {
    if (!placeholderLabel) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beganEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endedEditing:) name:UITextViewTextDidEndEditingNotification object:nil];
        placeholderLabel = [[UILabel alloc] init];
        placeholderLabel.numberOfLines = 0;
        placeholderLabel.backgroundColor = [UIColor clearColor];
        placeholderLabel.textColor = [UIColor whiteColor];
        placeholderLabel.font = self.font;
        placeholderLabel.lineBreakMode = UILineBreakModeWordWrap;
        placeholderLabel.textAlignment = UITextAlignmentCenter;
        [self maybeShowPlaceholder];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initCommon];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)setPlaceholderText:(NSString *)newValue {

    NSString *oldValue = placeholderText;
    placeholderText = newValue;

    [self maybeShowPlaceholder];
}

- (void)beganEditing:(NSNotification *)notification {
    [self hidePlaceholder];
}

- (void)endedEditing:(NSNotification *)notification {
    [self maybeShowPlaceholder];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
