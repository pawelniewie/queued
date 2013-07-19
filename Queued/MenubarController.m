#import <Buffered.h>
#import <Model.h>

#import "MenubarController.h"
#import "StatusItemView.h"
#import "QUPendingUpdatesViewController.h"

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

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profilesLoaded:) name:QUProfilesLoadedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pendingUpdatesLoaded:) name:QUPendingUpdatesLoadedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
            NSString *profileId = (NSString *) (BUProfile *) profile[@"id"];
            id currentState = emptyProfiles[profileId];
            if (currentState != nil) {
                newProfiles[profileId] = currentState;
            } else {
                newProfiles[profileId] = @YES;
            }
        }
        [emptyProfiles removeAllObjects];
        [emptyProfiles addEntriesFromDictionary:newProfiles];
    }
}

- (void)pendingUpdatesLoaded:(NSNotification *) notification {
    NSString *profileId = (notification.userInfo)[@"profileId"];
    NSArray *updates = notification.object;
    BOOL empty = updates == nil || [updates count] == 0;
    emptyProfiles[profileId] = @(empty);
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
