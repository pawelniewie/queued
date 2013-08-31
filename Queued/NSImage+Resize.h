//
//  NSImage+NSImageResize.h
//  Queued
//
//  Created by Pawel Niewiadomski on 30.08.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Resize)

- (NSImage*) resizeToSize:(NSSize)size;

@end
