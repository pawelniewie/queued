#import <Buffered.h>
#import <Model.h>
#import <BUPendingUpdatesViewController.h>

#import "MenubarController.h"
#import "StatusItemView.h"

@implementation MenubarController

@synthesize statusItemView = _statusItemView;

#pragma mark -

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"MenubarController" owner:self topLevelObjects:nil];
         
        emptyProfiles = [NSMutableDictionary new];
        
        // Load images
        emptyQueue = [NSImage imageNamed:@"StatusBlack"];
        fullQueue = [NSImage imageNamed:@"StatusGreen"];
        
        // Install status item into the menu bar
        NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:STATUS_ITEM_VIEW_WIDTH];
        _statusItemView = [[StatusItemView alloc] initWithStatusItem:statusItem];
        _statusItemView.image = emptyQueue;
        _statusItemView.alternateImage = [NSImage imageNamed:@"StatusInverted"];
        _statusItemView.action = @selector(togglePanel:);
        _statusItemView.menu = self.menu;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profilesLoaded:) name:BUProfilesLoadedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pendingUpdatesLoaded:) name:BUPendingUpdatesLoadedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:BUProfilesLoadedNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:BUPendingUpdatesLoadedNotification];
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}

#pragma mark -
#pragma mark Public accessors

- (NSStatusItem *)statusItem
{
    return self.statusItemView.statusItem;
}

#pragma mark -

- (void)profilesLoaded:(NSNotification *) notification {
    NSArray *profiles = notification.object;
    NSMutableDictionary *newProfiles = [NSMutableDictionary new];
    if (profiles != nil) {
        for (id profile in profiles) {
            id currentState = [emptyProfiles objectForKey:[(Profile *) profile id]];
            if (currentState != nil) {
                [newProfiles setObject:currentState forKey:[(Profile *)profile id]];
            } else {
                [newProfiles setObject:[NSNumber numberWithBool:YES] forKey:[(Profile *)profile id]];
            }
        }
        [emptyProfiles removeAllObjects];
        [emptyProfiles addEntriesFromDictionary:newProfiles];
    }
}

- (void)pendingUpdatesLoaded:(NSNotification *) notification {
    NSString *profileId = [notification.userInfo objectForKey:@"profileId"];
    NSArray *updates = notification.object;
    BOOL empty = updates == nil || [updates count] == 0;
    [emptyProfiles setObject:[NSNumber numberWithBool:empty] forKey:profileId];
    [self updateStatus];
}

- (void) updateStatus {
    BOOL theresEmptyProfile = NO;
    for (id empty in [emptyProfiles allValues]) {
        if ([empty boolValue]) {
            theresEmptyProfile = YES;
            break;
        }
    }
    _statusItemView.image = theresEmptyProfile ? emptyQueue : fullQueue;
}

- (BOOL)hasActiveIcon
{
    return self.statusItemView.isHighlighted;
}

- (void)setHasActiveIcon:(BOOL)flag
{
    self.statusItemView.isHighlighted = flag;
}

@end
