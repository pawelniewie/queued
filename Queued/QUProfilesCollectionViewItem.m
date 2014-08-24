//
//  QUProfilesCollectionViewItemViewController.m
//  Queued
//
//  Created by Pawel Niewiadomski on 16.07.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "Buffered.h"

#import "QUProfilesCollectionViewItem.h"
#import "QUProfileView.h"
#import "QUSelectableImageView.h"
#import "NSImage+Resize.h"

@interface QUProfilesCollectionViewItem ()

@end

@implementation QUProfilesCollectionViewItem

- (void)setSelected:(BOOL)flag
{
    [super setSelected:flag];
    ((QUProfileView *)self.view).selected = flag;
    ((QUSelectableImageView *) self.imageView).selected = flag;
    [self.view setNeedsDisplay:YES];
}

- (void) dealloc {
    [self.representedObject removeObserver:self forKeyPath:@"avatarImage"];
}

- (void) setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    BUProfile * profile = representedObject;
    [profile addObserver:self forKeyPath:@"avatarImage" options:NSKeyValueObservingOptionNew context:nil];
    
    if (profile.avatarImage != nil) {
        self.imageView.image = [profile.avatarImage resizeToSize:self.imageView.bounds.size];
    } else {
        [profile loadAvatar];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"avatarImage" isEqualToString:keyPath]) {
        BUProfile * profile = object;
        self.imageView.image = [profile.avatarImage resizeToSize:self.imageView.bounds.size];
    }
}

@end
