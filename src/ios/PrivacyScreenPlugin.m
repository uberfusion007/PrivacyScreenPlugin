/**

 * PrivacyScreenPlugin.m

 * Created by Tommy-Carlos Williams on 18/07/2014

 * Copyright (c) 2014 Tommy-Carlos Williams. All rights reserved.

 * MIT Licensed

 */

#import "PrivacyScreenPlugin.h"



static UIImageView *imageView;



@implementation PrivacyScreenPlugin



- (void)pluginInitialize

{

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:)

                                               name:UIApplicationDidBecomeActiveNotification object:nil];



  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:)

                                               name:UIApplicationWillResignActiveNotification object:nil];

}



- (void)onAppDidBecomeActive:(UIApplication *)application

{

  if (imageView == NULL) {

    self.viewController.view.window.hidden = NO;

  } else {

    [imageView removeFromSuperview];

  }

}



- (void)onAppWillResignActive:(UIApplication *)application

{

  CDVViewController *vc = (CDVViewController*)self.viewController;

  NSString *imgName = [self getImageName:self.viewController.interfaceOrientation delegate:(id<CDVScreenOrientationDelegate>)vc device:[self getCurrentDevice]];

  UIImage *splash = [UIImage imageNamed:imgName];

  if (splash == NULL) {

    imageView = NULL;

    self.viewController.view.window.hidden = YES;

  } else {

    imageView = [[UIImageView alloc]initWithFrame:[self.viewController.view bounds]];

    [imageView setImage:splash];

      [self updateBounds];

    

    #ifdef __CORDOVA_4_0_0

        [[UIApplication sharedApplication].keyWindow addSubview:imageView];

    #else

        [self.viewController.view addSubview:imageView];

    #endif

  }

}



- (void)updateBounds

{

    if ([self isUsingCDVLaunchScreen]) {

        // CB-9762's launch screen expects the image to fill the screen and be scaled using AspectFill.

        CGSize viewportSize = [UIApplication sharedApplication].delegate.window.bounds.size;

        imageView.frame = CGRectMake(0, 0, viewportSize.width, viewportSize.height);

        imageView.contentMode = UIViewContentModeScaleAspectFill;

        return;

    }



    UIImage* img = imageView.image;

    CGRect imgBounds = (img) ? CGRectMake(0, 0, img.size.width, img.size.height) : CGRectZero;



    CGSize screenSize = [self.viewController.view convertRect:[UIScreen mainScreen].bounds fromView:nil].size;

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    CGAffineTransform imgTransform = CGAffineTransformIdentity;



    /* If and only if an iPhone application is landscape-only as per

     * UISupportedInterfaceOrientations, the view controller's orientation is

     * landscape. In this case the image must be rotated in order to appear

     * correctly.

     */

    CDV_iOSDevice device = [self getCurrentDevice];

    if (UIInterfaceOrientationIsLandscape(orientation) && !device.iPhone6Plus && !device.iPad && !device.iPhoneX)

    {

        imgTransform = CGAffineTransformMakeRotation(M_PI / 2);

        imgBounds.size = CGSizeMake(imgBounds.size.height, imgBounds.size.width);

    }



    // There's a special case when the image is the size of the screen.

    if (CGSizeEqualToSize(screenSize, imgBounds.size))

    {

        CGRect statusFrame = [self.viewController.view convertRect:[UIApplication sharedApplication].statusBarFrame fromView:nil];

        if (!(IsAtLeastiOSVersion(@"7.0")))

        {

            imgBounds.origin.y -= statusFrame.size.height;

        }

    }

    else if (imgBounds.size.width > 0)

    {

        CGRect viewBounds = self.viewController.view.bounds;

        CGFloat imgAspect = imgBounds.size.width / imgBounds.size.height;

        CGFloat viewAspect = viewBounds.size.width / viewBounds.size.height;

        // This matches the behaviour of the native splash screen.

        CGFloat ratio;

        if (viewAspect > imgAspect)

        {

            ratio = viewBounds.size.width / imgBounds.size.width;

        }

        else

        {

            ratio = viewBounds.size.height / imgBounds.size.height;

        }

        imgBounds.size.height *= ratio;

        imgBounds.size.width *= ratio;

    }



    imageView.transform = imgTransform;

    imageView.frame = imgBounds;

}
// Code below borrowed from the CDV splashscreen plugin @ https://github.com/apache/cordova-plugin-splashscreen
// Made some adjustments though, becuase landscape splashscreens are not available for iphone < 6 plus
- (CDV_iOSDevice) getCurrentDevice
{
  CDV_iOSDevice device;

  UIScreen* mainScreen = [UIScreen mainScreen];
  CGFloat mainScreenHeight = mainScreen.bounds.size.height;
  CGFloat mainScreenWidth = mainScreen.bounds.size.width;

  int limit = MAX(mainScreenHeight,mainScreenWidth);

  device.iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
  device.iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
  device.retina = ([mainScreen scale] == 2.0);
  device.iPhone4 = (device.iPhone && limit == 480.0);
  device.iPhone5 = (device.iPhone && limit == 568.0);
  // note these below is not a true device detect, for example if you are on an
  // iPhone 6/6+ but the app is scaled it will prob set iPhone5 as true, but
  // this is appropriate for detecting the runtime screen environment
  device.iPhone6 = (device.iPhone && limit == 667.0);
  device.iPhone6Plus = (device.iPhone && limit == 736.0);
  device.iPhoneX  = (device.iPhone && limit == 812.0);

  return device;
}

- (BOOL) isUsingCDVLaunchScreen {
    NSString* launchStoryboardName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UILaunchStoryboardName"];
    if (launchStoryboardName) {
        return ([launchStoryboardName isEqualToString:@"CDVLaunchScreen"]);
    } else {
        return NO;
    }
}

- (NSString*)getImageName:(UIInterfaceOrientation)currentOrientation delegate:(id<CDVScreenOrientationDelegate>)orientationDelegate device:(CDV_iOSDevice)device
{
    return @"LaunchStoryboard";
  // Use UILaunchImageFile if specified in plist.  Otherwise, use Default.
  NSString* imageName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UILaunchImageFile"];

  NSUInteger supportedOrientations = [orientationDelegate supportedInterfaceOrientations];

  // Checks to see if the developer has locked the orientation to use only one of Portrait or Landscape
  BOOL supportsLandscape = (supportedOrientations & UIInterfaceOrientationMaskLandscape);
  BOOL supportsPortrait = (supportedOrientations & UIInterfaceOrientationMaskPortrait || supportedOrientations & UIInterfaceOrientationMaskPortraitUpsideDown);
  // this means there are no mixed orientations in there
  BOOL isOrientationLocked = !(supportsPortrait && supportsLandscape);

  if (imageName) {
    imageName = [imageName stringByDeletingPathExtension];
  } else {
    imageName = @"Default";
  }

  // Add Asset Catalog specific prefixes
  if ([imageName isEqualToString:@"LaunchImage"])
  {
    if(device.iPhone4 || device.iPhone5 || device.iPad) {
      imageName = [imageName stringByAppendingString:@"-700"];
    } else if(device.iPhone6) {
      imageName = [imageName stringByAppendingString:@"-800"];
    } else if(device.iPhone6Plus) {
      imageName = [imageName stringByAppendingString:@"-800"];
      if (currentOrientation == UIInterfaceOrientationPortrait || currentOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        imageName = [imageName stringByAppendingString:@"-Portrait"];
      }
    }
  }

  BOOL isLandscape = supportsLandscape &&
  (currentOrientation == UIInterfaceOrientationLandscapeLeft || currentOrientation == UIInterfaceOrientationLandscapeRight);

  if (device.iPhone5) { // does not support landscape
    imageName = isLandscape ? nil : [imageName stringByAppendingString:@"-568h"];
  } else if (device.iPhone6) { // does not support landscape
    imageName = isLandscape ? nil : [imageName stringByAppendingString:@"-667h"];
  } else if (device.iPhone6Plus) { // supports landscape
    if (isOrientationLocked) {
      imageName = [imageName stringByAppendingString:(supportsLandscape ? @"-Landscape" : @"")];
    } else {
      switch (currentOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
          imageName = [imageName stringByAppendingString:@"-Landscape"];
          break;
        default:
          break;
      }
    }
    imageName = [imageName stringByAppendingString:@"-736h"];

  } else if (device.iPad) { // supports landscape
    if (isOrientationLocked) {
      imageName = [imageName stringByAppendingString:(supportsLandscape ? @"-Landscape" : @"-Portrait")];
    } else {
      switch (currentOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
          imageName = [imageName stringByAppendingString:@"-Landscape"];
          break;

        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        default:
          imageName = [imageName stringByAppendingString:@"-Portrait"];
          break;
      }
    }
  }

  return imageName;
}

@end