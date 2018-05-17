//
//  ChatImageUtil.m
//  chat21
//
//  Created by Andrea Sponziello on 07/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatImageUtil.h"
#import <QuartzCore/QuartzCore.h>

@implementation ChatImageUtil

// from http://stackoverflow.com/questions/538041/uiimagepickercontroller-camera-preview-is-portrait-in-landscape-app
+(UIImage *)adjustEXIF:(UIImage *)image {
    // Code from: http://discussions.apple.com/thread.jspa?messageID=7949889
    //    int kMaxResolution = 640; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    //    if (width > kMaxResolution || height > kMaxResolution) {
    //        CGFloat ratio = width/height;
    //        if (ratio > 1) {
    //            bounds.size.width = kMaxResolution;
    //            bounds.size.height = roundf(bounds.size.width / ratio);
    //        }
    //        else {
    //            bounds.size.height = kMaxResolution;
    //            bounds.size.width = roundf(bounds.size.height * ratio);
    //        }
    //    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

+(CGSize)fitSize:(CGSize)size intoSize:(CGSize)newSize {
    //    - (UIImage*) scaleImage:(UIImage*)image toSize:(CGSize)newSize {
    CGSize scaledSize = size;
    
    // first scale on width
    float hScaleFactor;
    if (scaledSize.width > newSize.width) {
        hScaleFactor = newSize.width / size.width;
        scaledSize.width = size.width * hScaleFactor;
        scaledSize.height = size.height * hScaleFactor;
    }
    
    // then scale on height
    float vScaleFactor;
    if (scaledSize.height > newSize.height) {
        vScaleFactor = newSize.height / scaledSize.height;
        scaledSize.height = scaledSize.height * vScaleFactor;
        //        scaledSize.width = newSize.width / vScaleFactor;
        scaledSize.width = scaledSize.width * vScaleFactor;
    }
    return scaledSize;
    
    //        UIGraphicsBeginImageContextWithOptions( scaledSize, NO, 0.0 );
    //        CGRect scaledImageRect = CGRectMake( 0.0, 0.0, scaledSize.width, scaledSize.height );
    //        [image drawInRect:scaledImageRect];
    //        UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    //        UIGraphicsEndImageContext();
    //
    //        return scaledImage;
}


+(CGSize)fitSizeWidth:(CGSize)size intoSize:(CGSize)newSize {
    CGSize scaledSize = size;
    //NSLog(@"scaledSize NW: %f - %f",scaledSize.width, scaledSize.height);
    //NSLog(@"newSize NW: %f - %f",newSize.width, newSize.height);
    if(scaledSize.height<=0){
        scaledSize.width = newSize.width;
        scaledSize.height = newSize.height;
    }
    else{
        scaledSize.height = size.height * newSize.width / size.width;
        scaledSize.width = newSize.width;
        //NSLog(@"scaledSize NW: %f - %f",scaledSize.width, scaledSize.height);
        if (scaledSize.height > newSize.height) {
            //       scaledSize.height = newSize.height;
            //        vScaleFactor = newSize.height / scaledSize.height;
            //        scaledSize.height = scaledSize.height * vScaleFactor;
            //        //        scaledSize.width = newSize.width / vScaleFactor;
            //        scaledSize.width = scaledSize.width * vScaleFactor;
        }
    }
    //NSLog(@":::::: scaledSize :::::: %f - %f", scaledSize.width, scaledSize.height);
    return scaledSize;
}


//ATTENZIONE SE è RETINA DISPLAY DEVO RADDOPPIARE I PX
//float imgW = [[UIScreen mainScreen] bounds].size.width * (int)[UIScreen mainScreen].scale;
//float imgH = [[UIScreen mainScreen] bounds].size.height * (int)[UIScreen mainScreen].scale;
//newSize = CGSizeMake(imgW, imgH);


//+(CGSize)imageSizeForProduct:(SHPProduct *)p constrainedInto:(CGSize)size {
//    //NSLog(@"PRODUCT IMAGE HEIGHT %f, %f",p.imageWidth, p.imageHeight);
//    CGSize originalImageSize = CGSizeMake(p.imageWidth, p.imageHeight);
//
//    //ATTENZIONE SIZE E' ESPRESSO IN PUNTI E A ME SERVONO PIXEL
//    CGSize nwSize = CGSizeMake(size.width/2, size.height/2);
//
//    CGSize resized = [SHPImageUtil  fitSizeWidth:originalImageSize intoSize:nwSize]; //fitSize
//     //NSLog(@"RESIZE IMAGE HEIGHT %f, %f",resized.width, resized.height);
//
//    return resized;
//}

+(UIImage *)scaleImage:(UIImage*)image toSize:(CGSize)size {
    CGSize newSizeWithAspectRatio = [ChatImageUtil fitSize:image.size intoSize:size];
    
    UIGraphicsBeginImageContext(newSizeWithAspectRatio);
    //    UIGraphicsBeginImageContextWithOptions(newSizeWithAspectRatio, NO, 1);
    [image drawInRect:CGRectMake(0, 0, newSizeWithAspectRatio.width, newSizeWithAspectRatio.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+(UIImage *)previewThumbOnImage:(UIImage *)thumb image:(UIImage *)image {
    // begin a graphics context of sufficient size
    UIGraphicsBeginImageContext(thumb.size);
    
    // draw original image into the context
    [image drawAtPoint:CGPointZero];
    // blend modes in CGContext reference
    // http://developer.apple.com/library/ios/#documentation/GraphicsImaging/Reference/CGContext/Reference/reference.html#//apple_ref/doc/c_ref/CGBlendMode
    [thumb drawAtPoint:CGPointZero blendMode:kCGBlendModeMultiply alpha:0.5];
    //    // get the context for CoreGraphics
    //    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //
    //    // set stroking color and draw circle
    //    [[UIColor redColor] setStroke];
    //
    //    // make circle rect 5 px from border
    //    CGRect circleRect = CGRectMake(0, 0,
    //                                   image.size.width,
    //                                   image.size.height);
    //    circleRect = CGRectInset(circleRect, 5, 5);
    //
    //    // draw circle
    //    CGContextStrokeEllipseInRect(ctx, circleRect);
    
    // make image out of bitmap context
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // free the context
    UIGraphicsEndImageContext();
    
    return retImage;
}

+(UIImage *)tintImage:(UIImage *)image withColor:(UIColor *)tintColor {
    
    static CGFloat scale = -1.0;
    if (scale<0.0) {
        UIScreen *screen = [UIScreen mainScreen];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.0) {
            scale = [screen scale];
        }
        else {
            scale = 0.0;    // mean use old api
        }
    }
    if (scale>0.0) {
        UIGraphicsBeginImageContextWithOptions(image.size, NO, scale);
    }
    else {
        UIGraphicsBeginImageContext(image.size);
    }
    
    // load the image
    // begin a new image context, to draw our colored image onto
    //    UIGraphicsBeginImageContext(image.size);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    [tintColor setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // set the blend mode to color burn, and the original image
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextDrawImage(context, rect, image.CGImage);
    //    [image drawAtPoint:CGPointZero];
    
    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    CGContextClipToMask(context, rect, image.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return the color-burned image
    return coloredImg;
    
    
    
    //    UIGraphicsBeginImageContext(image.size);
    //    CGContextRef context = UIGraphicsGetCurrentContext();
    //
    //    CGContextTranslateCTM(context, 0, image.size.height);
    //    CGContextScaleCTM(context, 1.0, -1.0);
    //
    //    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    //
    //    // image drawing code here
    //
    //    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    //    // draw black background to preserve color of transparent pixels
    //    CGContextSetBlendMode(context, kCGBlendModeNormal);
    //    [[UIColor blackColor] setFill];
    //    CGContextFillRect(context, rect);
    //
    //    // draw original image
    //    CGContextSetBlendMode(context, kCGBlendModeNormal);
    //    CGContextDrawImage(context, rect, image.CGImage);
    //
    //    // tint image (loosing alpha) - the luminosity of the original image is preserved
    //    CGContextSetBlendMode(context, kCGBlendModeColor);
    //    [tintColor setFill];
    //    CGContextFillRect(context, rect);
    //
    //    // mask by alpha values of original image
    //    CGContextSetBlendMode(context, kCGBlendModeDestinationIn);
    //    CGContextDrawImage(context, rect, image.CGImage);
    //    UIGraphicsEndImageContext();
    //    return coloredImage;
    
    //    UIGraphicsBeginImageContextWithOptions(image.size, NO, 1.0);
    //    CGContextRef context = UIGraphicsGetCurrentContext();
    //    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    //
    //    // draw original image
    //    [image drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0f];
    //
    //    // tint image (loosing alpha).
    //    // kCGBlendModeOverlay is the closest I was able to match the
    //    // actual process used by apple in navigation bar
    //    CGContextSetBlendMode(context, kCGBlendModeOverlay);
    //    [tintColor setFill];
    //    CGContextFillRect(context, rect);
    //
    //    // mask by alpha values of original image
    //    [image drawInRect:rect blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    //
    //    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    //    UIGraphicsEndImageContext();
    //    return tintedImage;
}

+(void)drawViewShadow:(UIView *)view {
    CALayer * layer = [view layer];
    layer.masksToBounds = NO;
    layer.shadowOffset = CGSizeMake(0, 1);
    layer.shadowRadius = 1;
    layer.shadowOpacity = 0.5;
    layer.shouldRasterize = YES;
    [layer setShadowPath:[[UIBezierPath
                           bezierPathWithRect:view.bounds] CGPath]];
    layer.rasterizationScale = [UIScreen mainScreen].scale;
}

//+(UIImage *)imageWithColor:(UIColor *)tintColor withRect:(CGRect)drawRect {
////    UIGraphicsBeginImageContextWithOptions(drawRect.size, NO, [[UIScreen mainScreen] scale]);
//////    CGRect drawRect = CGRectMake(0, 0, self.size.width, self.size.height);
//////    [self drawInRect:size];
////    [tintColor set];
////    UIRectFillUsingBlendMode(drawRect, kCGBlendModeSourceAtop);
////    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
////    UIGraphicsEndImageContext();
////    return tintedImage;
//
//    // Create a new bitmap context based on the current image's size and scale, that has opacity
//    UIGraphicsBeginImageContextWithOptions(drawRect.size, NO, [[UIScreen mainScreen] scale]);
//    // Get a reference to the current context (which you just created)
//    CGContextRef c = UIGraphicsGetCurrentContext();
//    CGContextSetFillColorWithColor(c, [tintColor CGColor]);
//    UIRectFill(drawRect);
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    // Draw your image into the context we created
////    [image drawInRect:drawRect];
//    UIGraphicsEndImageContext();
//    return image;
////    // This sets the blend mode, which is not super helpful. Basically it uses the your fill color with the alpha of the image and vice versa. I'll include a link with more info.
////    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
////    // Now you apply the color and blend mode onto your context.
////    CGContextFillRect(c, drawRect);
////    // You grab the result of all this drawing from the context.
////    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
////    // And you return it.
////    return result;
//}

+(UIImage *)imageWithColor:(UIColor *)color withRect:(CGRect)drawRect {
    //Create a context of the appropriate size
    UIGraphicsBeginImageContext(drawRect.size);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    //Build a rect of appropriate size at origin 0,0
    CGRect fillRect = CGRectMake(0,0,drawRect.size.width,drawRect.size.height);
    
    //Set the fill color
    CGContextSetFillColorWithColor(currentContext, color.CGColor);
    
    //Fill the color
    CGContextFillRect(currentContext, fillRect);
    
    //Snap the picture and close the context
    UIImage *retval = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return retval;
}

+ (UIColor *)colorWithHexString:(NSString *)colorString
{
    colorString = [colorString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (colorString.length == 3)
        colorString = [NSString stringWithFormat:@"%c%c%c%c%c%c",
                       [colorString characterAtIndex:0], [colorString characterAtIndex:0],
                       [colorString characterAtIndex:1], [colorString characterAtIndex:1],
                       [colorString characterAtIndex:2], [colorString characterAtIndex:2]];
    
    if (colorString.length == 6)
    {
        int r, g, b;
        sscanf([colorString UTF8String], "%2x%2x%2x", &r, &g, &b);
        return [UIColor colorWithRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:1.0];
    }
    return nil;
}

+ (UIColor *)colorWithHexValue:(int)hexValue
{
    float red   = ((hexValue & 0xFF0000) >> 16)/255.0;
    float green = ((hexValue & 0xFF00) >> 8)/255.0;
    float blue  = (hexValue & 0xFF)/255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

+(void)arroundImage:(float)borderRadius borderWidth:(float)borderWidth layer:(CALayer *)layer
{
    CALayer * l = layer;
    [l setMasksToBounds:YES];
    [l setBorderColor:[UIColor lightGrayColor].CGColor];
    [l setBorderWidth:borderWidth];
    [l setCornerRadius:borderRadius];
}

+(void)customIcon:(UIImageView *)iconImage{
    iconImage.layer.cornerRadius = iconImage.frame.size.height/2;
    iconImage.layer.masksToBounds = YES;
    iconImage.layer.borderWidth = 0.1;
}

//+(UIImage *)circleImage:(UIImage *)image {
//    UIImage* circle_image;
//    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
//    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0);
//    float radius = image.size.height / 2;
//    // Add a clip before drawing anything, in the shape of an rounded rect
//    [[UIBezierPath bezierPathWithRoundedRect:rect
//                                cornerRadius:radius] addClip];
//    // Draw your image
//    [image drawInRect:rect];
//
//    // Get the image, here setting the UIImageView image
//    circle_image = UIGraphicsGetImageFromCurrentImageContext();
//
//    // Lets forget about that we were drawing
//    UIGraphicsEndImageContext();
//    return circle_image;
//
//
//    //    UIGraphicsBeginImageContext(self.frame.size);
//    //    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    //    CGFloat height = self.bounds.size.height;
//    //    CGContextTranslateCTM(ctx, 0.0, height);
//    //    CGContextScaleCTM(ctx, 1.0, -1.0);
//    //    CGContextAddArc(ctx, self.frame.size.width/2, self.frame.size.height/2, 50, 0, 2*M_PI, 0);
//    //    CGContextClosePath(ctx);
//    //    CGContextSaveGState(ctx);
//    //    CGContextClip(ctx);
//    //    CGContextDrawImage(ctx, CGRectMake(0,0,self.frame.size.width, self.frame.size.height), image.CGImage);
//    //    CGContextRestoreGState(ctx);
//    //    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
//    //    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
//}

+(UIImage *)circleImage:(UIImage *)image {
    //    NSLog(@"ORIGINAL SIZE: W: %f H: %f", image.size.width, image.size.height);
    UIImage* circle_image;
    float min_side = image.size.height;
    if (image.size.width < min_side) {
        min_side = image.size.width;
    }
    float radius = min_side / 2.0;
    //    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    //    CGFloat size = radius;
    //    image = [SHPImageUtil squareImageFromImage:image scaledToSize:size];
    //    NSLog(@"NEW SIZE w: %f h: %f", image.size.width, image.size.height);
    
    CGRect rect = CGRectMake(0, 0, radius, radius);
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(rect.size);
    }
    //    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0);
    
    // Add a clip before drawing anything, in the shape of an rounded rect
    [[UIBezierPath bezierPathWithRoundedRect:rect
                                cornerRadius:radius] addClip];
    // Draw your image
    [image drawInRect:rect];
    
    // Get the image, here setting the UIImageView image
    circle_image = UIGraphicsGetImageFromCurrentImageContext();
    
    // Lets forget about that we were drawing
    UIGraphicsEndImageContext();
    return circle_image;
    
    
    //    UIGraphicsBeginImageContext(self.frame.size);
    //    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //    CGFloat height = self.bounds.size.height;
    //    CGContextTranslateCTM(ctx, 0.0, height);
    //    CGContextScaleCTM(ctx, 1.0, -1.0);
    //    CGContextAddArc(ctx, self.frame.size.width/2, self.frame.size.height/2, 50, 0, 2*M_PI, 0);
    //    CGContextClosePath(ctx);
    //    CGContextSaveGState(ctx);
    //    CGContextClip(ctx);
    //    CGContextDrawImage(ctx, CGRectMake(0,0,self.frame.size.width, self.frame.size.height), image.CGImage);
    //    CGContextRestoreGState(ctx);
    //    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    //    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
}


+(void)rotateImageView:(UIImageView *)imageView angle:(float)angle{
    imageView.transform = CGAffineTransformMakeRotation(angle*M_PI/180);
}

+(void)rotateImageViewWithAnimation:(UIImageView *)imageView duration:(float)duration angle:(float)angle{
    
    [UIView animateWithDuration: duration
                          delay: 0.5
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{
                         imageView.transform = CGAffineTransformMakeRotation(angle*M_PI/180);
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:duration animations:^{
                             //imageView.transform = CGAffineTransformMakeRotation(angle*M_PI/180);
                         }];
                     }];
}


+(UIImage *)squareImageFromImage:(UIImage *)image scaledToSize:(CGFloat)newSize {
    CGAffineTransform scaleTransform;
    CGPoint origin;
    if (image.size.width > image.size.height) {
        CGFloat scaleRatio = newSize / image.size.height;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
        
        origin = CGPointMake(-(image.size.width - image.size.height) / 2.0f, 0);
    } else {
        CGFloat scaleRatio = newSize / image.size.width;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
        
        origin = CGPointMake(0, -(image.size.height - image.size.width) / 2.0f);
    }
    CGSize size = CGSizeMake(newSize, newSize);
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, scaleTransform);
    [image drawAtPoint:origin];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)blur:(UIImage*)theImage radius:(CGFloat)radius
{
    // ***********If you need re-orienting (e.g. trying to blur a photo taken from the device camera front facing camera in portrait mode)
    // theImage = [self reOrientIfNeeded:theImage];
    
    // create our blurred image
    if(!radius){
        radius = 15.0f;
    }
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:theImage.CGImage];
    
    // setting up Gaussian Blur (we could use one of many filters offered by Core Image)
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    // CIGaussianBlur has a tendency to shrink the image a little,
    // this ensures it matches up exactly to the bounds of our original image
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
    
    UIImage *returnImage = [UIImage imageWithCGImage:cgImage];//create a UIImage for this function to "return" so that ARC can manage the memory of the blur... ARC can't manage CGImageRefs so we need to release it before this function "returns" and ends.
    CGImageRelease(cgImage);//release CGImageRef because ARC doesn't manage this on its own.
    
    return returnImage;
    
    // *************** if you need scaling
    // return [[self class] scaleIfNeeded:cgImage];
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
