//
//  CzedrMaximizeIconView.m
//

#import "CzedrMaximizeIconView.h"

@implementation CzedrMaximizeIconView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGRect box = CGRectInset(rect, 4.0, 5.0);
    if (box.size.width < 4.0 || box.size.height < 4.0) {
        return;
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) {
        return;
    }
    [[UIColor whiteColor] setStroke];
    CGContextSetLineWidth(ctx, 1.5);
    CGContextStrokeRect(ctx, box);
    CGContextSetLineWidth(ctx, 3.0);
    CGContextMoveToPoint(ctx, CGRectGetMinX(box), CGRectGetMinY(box));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(box), CGRectGetMinY(box));
    CGContextStrokePath(ctx);
}

@end
