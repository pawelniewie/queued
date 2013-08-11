//
//  QUFriendsFetcher.h
//  Queued
//
//  Created by Pawel Niewiadomski on 11.08.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACAccount;

@interface QUFriendsFetcher : NSObject

- (instancetype) initWithAccount: (ACAccount *) account;

- (void) startFetching;

@end
