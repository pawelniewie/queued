//
//  QUFriendsFetcher.m
//  Queued
//
//  Created by Pawel Niewiadomski on 11.08.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Accounts/Accounts.h>

#import <STTwitter/STTwitterAPI.h>

#import "QUFriendsFetcher.h"
#import "QUUserSuggestion.h"
#import "QUAppDelegate.h"

@interface QUFriendsFetcher()

@property (strong) ACAccount *account;
@property (strong) STTwitterAPI* twitterApi;
@property (strong) void(^friendsErrorHandler)(NSError *error);
@property (strong) void(^friendsHandler)(NSArray *friends, NSString *previousCursor, NSString *nextCursor);

@end

@implementation QUFriendsFetcher

- (void) startFetching {
    [self.twitterApi getFriendsListForUserID:nil
                           orScreenName:self.account.username
                                 cursor:nil
                             skipStatus:@(YES)
                    includeUserEntities:@(NO)
                           successBlock:self.friendsHandler errorBlock:self.friendsErrorHandler];
}

- (instancetype) initWithAccount: (ACAccount *) account {
    self = [self init];
    if (self) {
        self.account = account;
        self.twitterApi = [STTwitterAPI twitterAPIOSWithAccount:account];

        __weak QUFriendsFetcher * weakSelf = self;
        
        self.friendsErrorHandler = [^(NSError *error) {
            NSLog(@"Error downloading friends for %@: %@", weakSelf.account.username, error);
        } copy];
        
        self.friendsHandler = [^(NSArray *friends, NSString *previousCursor, NSString *nextCursor) {
            NSLog(@"Received friends for %@", weakSelf.account.username);
            if (friends != nil) {
                NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
                context.parentContext = [[QUAppDelegate instance] managedObjectContext];
                NSMutableSet *names = [NSMutableSet setWithArray:[friends valueForKey:@"screen_name"]];
                NSFetchRequest *request = [NSFetchRequest new];
                request.entity = [NSEntityDescription entityForName:@"UserSuggestion" inManagedObjectContext:context];
                request.predicate = [NSPredicate predicateWithFormat:@"(username IN %@)", names];
                request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey: @"username" ascending:YES]];
                
                NSError *error;
                NSArray *fetchedNames = [context executeFetchRequest:request error:&error];
                
                if (error == nil) {
                    NSSet *storedUsernames = [NSSet setWithArray:[fetchedNames valueForKey:@"username"]];
                    
                    [names minusSet:storedUsernames];
                    
                    [names enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                        QUUserSuggestion *userSuggestion = [NSEntityDescription
                                                            insertNewObjectForEntityForName:@"UserSuggestion"
                                                            inManagedObjectContext:context];
                        userSuggestion.username = obj;
                    }];
                    
                    NSError *error;
                    if (![context save:&error]) {
                        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                    }
                    [[QUAppDelegate instance] saveContext];
                }
            }
            
            if (nextCursor != nil && [@"0" isEqualToString:nextCursor] == NO) {
                __weak void(^weakHandler)(NSArray *friends, NSString *previousCursor, NSString *nextCursor) = weakSelf.friendsHandler;
                __weak void(^errorHandler)(NSError *error) = weakSelf.friendsErrorHandler;
                [NSTimer scheduledTimerWithTimeInterval:61 block:^(NSTimeInterval time) {
                    [weakSelf.twitterApi getFriendsListForUserID:nil
                                           orScreenName:account.username
                                                 cursor:nextCursor
                                             skipStatus:@(YES)
                                    includeUserEntities:@(NO)
                                           successBlock:weakHandler errorBlock:errorHandler];
                } repeats:NO];
            }
        } copy];
    }
    return self;
}

@end
