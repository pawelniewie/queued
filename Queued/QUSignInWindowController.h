//
//  QUSignInWindowController.h
//  Queued
//
//  Created by Pawel Niewiadomski on 07.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GTMOAuth2WindowController.h"

@interface QUSignInWindowController : GTMOAuth2WindowController

+ (NSString *)authNibName;

@end
