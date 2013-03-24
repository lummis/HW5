//
//  PhotoVC.m
//  SPoT HW4
//
//  Created by Robert Lummis on 3/13/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import "PhotoVC.h"

@interface PhotoVC ()  <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic) BOOL userHasZoomed; //set to NO on new photo, YES the first time user zooms
@property (nonatomic, strong) UIPopoverController *urlPopover;
@end

@implementation PhotoVC


-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ( [identifier isEqualToString:@"Show URL"] ) {
        return self.imageURL && !!!self.urlPopover.popoverVisible ? YES : NO;
    } else {
        return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ( [segue.identifier isEqualToString:@"Show URL"] ) {
        if ( [segue.destinationViewController isKindOfClass:[AttributedStringVC class]] ) {
            AttributedStringVC *asvc = (AttributedStringVC *)segue.destinationViewController;
            asvc.text = [[NSAttributedString alloc] initWithString:[self.imageURL description]];
            if ( [segue isKindOfClass:[UIStoryboardPopoverSegue class]] ) {
                self.urlPopover = ((UIStoryboardPopoverSegue *)segue).popoverController;
            }
        }
    }
}

- (void) setImageURL:(NSURL *)imageURL {
    _imageURL = imageURL;
    [self resetImage];
}

- (void) viewDidLayoutSubviews {
    [self adjustFrame];
}

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void) adjustFrame {  //zoom so all of photo fits on screen and set origin so photo is centered
    if (self.userHasZoomed) return;   //once user zooms we don't adjust any more
    CGFloat viewWidth = self.view.frame.size.width;
    CGFloat viewHeight = self.view.frame.size.height;
    CGFloat widthRatio = self.imageView.image.size.width / viewWidth;
    CGFloat heightRatio = self.imageView.image.size.height / viewHeight;

    CGFloat imageWidth;
    CGFloat imageHeight;
    CGFloat x;  //upper left corner of the photo within view
    CGFloat y;
    if (widthRatio >= heightRatio) {    //squeeze photo horizontally
        imageWidth = self.imageView.image.size.width / widthRatio;
        imageHeight = self.imageView.image.size.height / widthRatio;
        x = 0;
        y = 0.5 * (viewHeight - imageHeight);
    } else {
        imageWidth = self.imageView.image.size.width / heightRatio;
        imageHeight = self.imageView.image.size.height / heightRatio;
        x = 0.5 * (viewWidth - imageWidth);
        y = 0;
    }
    self.imageView.frame = CGRectMake(x, y, imageWidth, imageHeight);
}

- (void) scrollViewDidZoom:(UIScrollView *)scrollView {
    self.userHasZoomed = YES;
}

- (void) resetImage {
    if (self.scrollView) {
        self.scrollView.contentSize = CGSizeZero;   //is set below but only if we get a valid image
        self.imageView.image = nil;
        
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:self.imageURL];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        if (image) {
            self.scrollView.zoomScale = 1.0;
            self.scrollView.contentSize = image.size;
            self.imageView.image = image;
            self.userHasZoomed = NO;
            [self adjustFrame];
        }
    }
}

- (UIImageView *) imageView {
    if (!!!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _imageView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        //    [UIApplication sharedApplication].statusBarHidden = YES;  //this messes up subsequent tableviews
	[self.scrollView addSubview:self.imageView];
    self.scrollView.minimumZoomScale = 0.25;
    self.scrollView.maximumZoomScale = 4.0;
    self.scrollView.delegate = self;
    [self.scrollView flashScrollIndicators];
    self.scrollView.backgroundColor = [UIColor darkGrayColor];
    [self resetImage];      //handles case when setImageURL is called before view is loaded (e.g. in prepareForSegue)
}

@end
