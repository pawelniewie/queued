//
//  QUProfilesCollectionViewItemViewController.m
//  Queued
//
//  Created by Pawel Niewiadomski on 16.07.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "QUProfilesCollectionViewItem.h"
#import "QUProfileView.h"
#import "QUSelectableImageView.h"

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
@end
