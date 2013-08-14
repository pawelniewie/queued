//
//  QUPostUpdateTextView.m
//  Queued
//
//  Created by Pawel Niewiadomski on 03.08.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import "QUPostUpdateTextView.h"

@interface QUPostUpdateTextView()

@property (assign) BOOL textInAutocomplete;

@end

@implementation QUPostUpdateTextView

-  (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(NSInteger)movement isFinal:(BOOL)flag {
//    NSLog(@"Movement %ld, isFinal %ld, textInAutocomplete %ld", (long)movement, (long)flag, (long)self.textInAutocomplete);

    // If we suggest completions whilst typing, don't insert the completion unless the user has specifically chosen it!
	if (self.textInAutocomplete)
	{
		if (flag == NO || (flag == YES && movement == NSOtherTextMovement))
			return;
	}
    
    return [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
}

- (void) complete:(id)sender {
    self.textInAutocomplete = YES;
    @try {
        return [super complete:sender];
    } @finally {
        self.textInAutocomplete = NO;
    }
}

//- (NSRange) rangeForUserCompletion {
//    NSRange range = [super rangeForUserCompletion];
//    NSUInteger newLocation = range.location;
//    NSUInteger newLength = range.length;
//    while(newLocation != NSNotFound && newLocation !=0) {
//        if ([@"@" isEqualTo:[self.string substringWithRange:NSMakeRange(newLocation - 1, 1)]]) {
//            newLocation--;
//            newLength++;
//        }
//        break;
//    }
//    return NSMakeRange(newLocation, newLength);
//}

@end
