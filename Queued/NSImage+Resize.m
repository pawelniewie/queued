//
//  NSImage+NSImageResize.m
//  Queued
//
//  Created by Pawel Niewiadomski on 30.08.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "NSImage+Resize.h"

@implementation NSImage (Resize)

- (NSImage*) resizeToSize:(NSSize)size
{
    NSRect targetFrame = NSMakeRect(0, 0, size.width, size.height);
    NSImage*  targetImage = [[NSImage alloc] initWithSize:size];
    
    [targetImage lockFocus];
    
    [self drawInRect:targetFrame
                   fromRect:NSZeroRect       //portion of source image to draw
                  operation:NSCompositeCopy  //compositing operation
                   fraction:1.0              //alpha (transparency) value
             respectFlipped:YES              //coordinate system
                      hints:@{NSImageHintInterpolation:
                                  @(NSImageInterpolationMedium)}];
    
    [targetImage unlockFocus];
    
    return targetImage;
}

@end
