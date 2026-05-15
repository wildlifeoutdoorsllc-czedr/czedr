#import "HFImageEditorViewController+Private.h"
#import "DemoImageEditor.h"

@interface DemoImageEditor ()

@end

@implementation DemoImageEditor

@synthesize  saveButton = _saveButton;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ([[UIScreen mainScreen] bounds].size.height == 568.0f||[[UIScreen mainScreen] bounds].size.height == 480.0f) {
        CGRect frame = CGRectMake(0, 0, 320, 44);
       UIView* numberText= [[UITextField alloc] initWithFrame:frame];
       
        // textfield item
       size_barfix = [[UIBarButtonItem alloc] initWithCustomView:numberText];// behavior of
        //size_barfix.=[UIBarButtonItem alloc]initwith

    }

    if(self) {
        self.cropRect = CGRectMake(0,0,320,320);
        self.minimumScale = 0.2;
        self.maximumScale = 10;
    }
    return self;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    self.saveButton = nil;
    [self setSquareAction:self];
}

- (IBAction)setSquareAction:(id)sender
{
    self.cropRect = CGRectMake((self.frameView.frame.size.width-320)/2.0f, (self.frameView.frame.size.height-320)/2.0f, 320, 320);
    [self reset:YES];
}

- (IBAction)setLandscapeAction:(id)sender
{
    self.cropRect = CGRectMake((self.frameView.frame.size.width-320)/2.0f, (self.frameView.frame.size.height-240)/2.0f, 320, 240);
    [self reset:YES];
}


- (IBAction)setLPortraitAction:(id)sender
{
    self.cropRect = CGRectMake((self.frameView.frame.size.width-240)/2.0f, (self.frameView.frame.size.height-320)/2.0f, 240, 320);
    [self reset:YES];
}

#pragma mark Hooks
- (void)startTransformHook
{
    self.saveButton.tintColor = [UIColor colorWithRed:0 green:49/255.0f blue:98/255.0f alpha:1];
}

- (void)endTransformHook
{
    self.saveButton.tintColor = [UIColor colorWithRed:0 green:128/255.0f blue:1 alpha:1];
}
@end
