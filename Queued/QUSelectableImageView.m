//
//  QUSelectableImageView.m
//  Queued
//
//  Created by Pawel Niewiadomski on 16.07.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "QUSelectableImageView.h"

@implementation QUSelectableImageView

- (void)drawRect:(NSRect)dirtyRect
{
    self.isSelected ? [[NSColor alternateSelectedControlColor] set] : [[NSColor clearColor] set];
    [NSBezierPath setDefaultLineWidth:4.0];
    if (self.isSelected) {
        [super drawRect:dirtyRect];
        [NSBezierPath strokeRect:NSInsetRect(dirtyRect, 2, 2)]; // will give a 2 pixel wide border
    } else {
        [NSBezierPath fillRect:dirtyRect];
        [super drawRect:dirtyRect];
    }
}

@end
