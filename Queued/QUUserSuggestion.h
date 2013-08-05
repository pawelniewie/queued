//
//  UserSuggestions.h
//  Queued
//
//  Created by Pawel Niewiadomski on 05.08.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface QUUserSuggestion : NSManagedObject

@property (nonatomic, retain) NSString * username;

@end
