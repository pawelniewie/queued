//
//  QUSecrets.h
//  Queued
//
//  Created by Pawel Niewiadomski on 24.03.2016.
//  Copyright © 2016 Pawel Niewiadomski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QUSecrets : NSObject

+ (NSString *)bufferClientId;
+ (NSString *)bufferClientSecret;
+ (NSString *)hockeyAppId;

@end