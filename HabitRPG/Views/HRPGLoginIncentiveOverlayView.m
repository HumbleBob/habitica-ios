//
//  HRPGLoginIncentiveOverlayView.m
//  Habitica
//
//  Created by Phillip Thelen on 20/11/2016.
//  Copyright © 2016 Phillip Thelen. All rights reserved.
//

#import "HRPGLoginIncentiveOverlayView.h"
#import <YYWebImage.h>
#import "KLCPopup.h"

static inline UIImage *MTDContextCreateRoundedMask(CGRect rect, CGFloat radius_tl,
                                                   CGFloat radius_tr, CGFloat radius_bl,
                                                   CGFloat radius_br) {
    CGContextRef context;
    CGColorSpaceRef colorSpace;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a bitmap graphics context the size of the image
    context = CGBitmapContextCreate(NULL, rect.size.width, rect.size.height, 8, 0, colorSpace,
                                    kCGImageAlphaPremultipliedLast);
    
    // free the rgb colorspace
    CGColorSpaceRelease(colorSpace);
    
    if (context == NULL) {
        return NULL;
    }
    
    // cerate mask
    
    CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect);
    
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 1.0, 0.0);
    CGContextAddRect(context, rect);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFill);
    
    CGContextSetGrayFillColor(context, 1.0, 1.0);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius_bl);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius_br);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius_tr);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius_tl);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFill);
    
    // Create CGImageRef of the main view bitmap content, and then
    // release that bitmap context
    CGImageRef bitmapContext = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    // convert the finished resized image to a UIImage
    UIImage *theImage = [UIImage imageWithCGImage:bitmapContext];
    // image is retained by the property setting above, so we can
    // release the original
    CGImageRelease(bitmapContext);
    
    // return the image
    return theImage;
}

@interface HRPGLoginIncentiveOverlayView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeight;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UILabel *nextUnlockLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIView *buttonSeparator;


@end

@implementation HRPGLoginIncentiveOverlayView

- (void)sizeToFit {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    CGFloat width = screenRect.size.width - 60;
    
    if (width > 500) {
        width = 500;
    }
    
    self.frame = CGRectMake(0, 0, width, 300);
    [self layoutSubviews];
    // top margin, title-image margin, image, image-notes margin, notes-buttons margin, button
    // height
    CGFloat height = 20 + 16 + self.imageViewHeight.constant + 16 + 16 + 50 + 40;
    [self.titleLabel sizeToFit];
    height = height + self.titleLabel.frame.size.height;
    [self.descriptionView sizeToFit];
    height = height + self.descriptionView.frame.size.height;
    [self.nextUnlockLabel sizeToFit];
    height = height + self.nextUnlockLabel.frame.size.height;
    
    self.frame = CGRectMake(0, 0, width, height);
    UIImage *mask = MTDContextCreateRoundedMask(self.bounds, 8.0, 8.0, 8.0, 8.0);
    CALayer *layerMask = [CALayer layer];
    layerMask.frame = self.bounds;
    layerMask.contents = (id)mask.CGImage;
    self.layer.mask = layerMask;
}

- (void)setTitleText:(NSString *)titleText {
    self.titleLabel.text = titleText;
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
}

- (void)setDescriptionText:(NSString *)descriptionText {
    _descriptionText = descriptionText;
    self.descriptionView.text = descriptionText;
    self.descriptionView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void)setNextUnlock:(NSNumber *)nextUnlock {
    if ([nextUnlock integerValue] == 1) {
        self.nextUnlockLabel.text = NSLocalizedString(@"Your next prize unlocks in 1 Check-In.", nil);
    } else {
        self.nextUnlockLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Your next prize unlocks in %@ Check-Ins", nil), nextUnlock];
    }
}

- (void)displayImageWithName:(NSString *)imageName {
    YYWebImageManager *manager = [YYWebImageManager sharedManager];
    [manager
     requestImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://"
                                               @"habitica-assets.s3."
                                               @"amazonaws.com/"
                                               @"mobileApp/images/%@",
                                               imageName]]
     options:0
     progress:nil
     transform:^UIImage *_Nullable(UIImage *_Nonnull image, NSURL *_Nonnull url) {
         return [YYImage imageWithData:[image yy_imageDataRepresentation] scale:1.0];
     }
     completion:^(UIImage *_Nullable image, NSURL *_Nonnull url, YYWebImageFromType from,
                  YYWebImageStage stage, NSError *_Nullable error) {
         if (image) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.imageView.image = image;
             });
         }
     }];
}

- (void)displayImage:(UIImage *)image {
    self.imageView.image = image;
}

- (IBAction)shareButtonPressed:(id)sender {
    if (self.shareAction) {
        self.shareAction();
    }
    [self dismissPresentingPopup];
}

- (IBAction)dismissButtonPressed:(id)sender {
    if (self.dismissAction) {
        self.dismissAction();
    }
    [self dismissPresentingPopup];
}

- (void)setImageHeight:(CGFloat)imageHeight {
    self.imageViewHeight.constant = imageHeight;
}

- (void)setImageWidth:(CGFloat)imageWidth {
    self.imageViewWidth.constant = imageWidth;
}

- (void)setDismissButtonText:(NSString *)dismissButtonText {
    [self.dismissButton setTitle:dismissButtonText forState:UIControlStateNormal];
}

- (void)hideShareButton {
    [self.shareButton setTitle:nil forState:UIControlStateNormal];
    self.buttonSeparator.hidden = YES;
}

- (void)setReward:(NSDictionary *)rewardInfo withMessage:(NSString *)message withDaysUntilNext:(NSNumber *)daysUntil {
    self.titleText = NSLocalizedString(@"You unlocked Check-In Prize!", nil);
    self.descriptionText = message;
    [self displayImageWithName:[rewardInfo[@"key"] stringByAppendingString:@".png"]];
    [self setNextUnlock:daysUntil];
}

- (void)setNoRewardWithMessage:(NSString *)message withDaysUntilNext:(NSNumber *)daysUntil {
    self.titleText = NSLocalizedString(@"Your Check-In Counter went up!", nil);
    self.descriptionText = message;
    [self displayImageWithName:@"inventory_present_11.png"];
    [self setNextUnlock:daysUntil];
    [self hideShareButton];
}

@end