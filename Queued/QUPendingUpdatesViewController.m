//
//  BUPendingUpdatesViewController.m
//  Buffered
//
//  Created by Pawel Niewiadomski on 01.04.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//


#import <Buffered.h>
#import <QUPendingTableCellView.h>
#import <BUPendingUpdatesViewController.h>
#import <BUPendingUpdatesMonitor.h>

#import "QUPendingUpdatesViewController.h"
#import "QUPendingUpdatesRowView.h"
#import "QUAppDelegate.h"

@interface QUPendingUpdatesViewController ()

@end

@implementation QUPendingUpdatesViewController

static NSString *DRAG_AND_DROP_TYPE = @"Update Data";

- (id)initWithBuffered:(Buffered *)buffered andProfilesMonitor: (BUProfilesMonitor *) profilesMonitor
{
    self = [super initWithNibName:@"QUPendingUpdatesViewController" bundle:[self bufferedBundle]];
    if (self) {
        // Initialization code here.
        _updatesContent = [NSArrayController new];
        _profiles = [NSArrayController new];
        _updates = [NSMutableDictionary new];
        _buffered = buffered;
        _profilesMonitor = profilesMonitor;
        _observedVisibleItems = [NSMutableArray new];

        [[QUAppDelegate instance] addObserver:self forKeyPath:@"isLaunchAtLoginEnabled" options:NSKeyValueObservingOptionNew context:nil];
        
        __weak QUPendingUpdatesViewController * noRetain = self; // http://stackoverflow.com/questions/7853915/how-do-i-avoid-capturing-self-in-blocks-when-implementing-an-api
        _updatesHandler = ^(NSString *profileId, NSArray *pending, NSError *error) {
            QUPendingUpdatesViewController *updatesViewController = noRetain;
            if (updatesViewController != nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:BUPendingUpdatesLoadedNotification object:pending userInfo:@{ @"profileId" : profileId }];
                if (pending != nil) {
                    @synchronized(updatesViewController) {
                        NSMutableArray *copy = [NSMutableArray arrayWithArray:pending];
                        [updatesViewController.updates setObject:copy forKey:profileId];
                    }
                    [updatesViewController performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
                }
            }
        };
        
        _removeHandler = ^(NSString *profileId) {
            [noRetain.profiles.arrangedObjects enumerateObjectsUsingBlock:^(Profile* obj, NSUInteger idx, BOOL *stop) {
                if ([profileId isEqualToString:obj.id]) {
                    [obj.updatesMonitor refresh];
                    *stop = YES;
                }
            }];
        };
    }
    
    return self;
}

- (void) dealloc {
    [_profilesMonitor.profiles enumerateObjectsUsingBlock:^(Profile* obj, NSUInteger idx, BOOL *stop) {
        [obj.updatesMonitor removeObserver:self forKeyPath:@"pendingUpdates"];
    }];
    [_profilesMonitor removeObserver:self forKeyPath:@"profiles"];
    [[QUAppDelegate instance] removeObserver:self forKeyPath:@"isLaunchAtLoginEnabled"];
}

- (void) loadView {
    [super loadView];
    
    [self.updatesTable registerForDraggedTypes:@[DRAG_AND_DROP_TYPE]];
    
    [self.progress startAnimation:self];
    
    self.launchAtLoginMenuItem.state = [QUAppDelegate instance].isLaunchAtLoginEnabled ? NSOnState : NSOffState;
    
    [_profilesMonitor addObserver:self forKeyPath:@"profiles" options:NSKeyValueObservingOptionNew context:nil];
    
    if (![_buffered isSignedIn:YES]) {
        [_buffered signInSheetModalForWindow:self.view.window withCompletionHandler:^(NSError *error) {
            if (error != nil) {
                [self reportError:error];
            }
        }];
    }
}

- (NSBundle *) bufferedBundle {
#ifndef POD
    NSString *frameworkBundleID = @"com.pawelniewiadomski.Buffered";
    NSBundle *frameworkBundle = [NSBundle bundleWithIdentifier:frameworkBundleID];
    return frameworkBundle;
#else
    return nil;
#endif
}

- (void) reportError: (NSError *) error {
    [self.progress stopAnimation:self];
    [self.progress setHidden:YES];
    if (self.delegate != nil) {
        [self.delegate reportError:error];
    } else {
        NSLog(@"Error updating pending updates %@", error);
    }
}

- (void) updateTable {
    NSMutableArray *newContent = [NSMutableArray new];
    for (Profile *profile in self.profiles.arrangedObjects) {
        [newContent addObject:profile];
        NSArray *updates = [self.updates objectForKey:profile.id];
        [newContent addObjectsFromArray:updates];
    }
    self.updatesContent.content = newContent;
    NSIndexSet *selectedRows = [self.updatesTable selectedRowIndexes];
    [self.updatesTable reloadData];
    [self.updatesTable selectRowIndexes:selectedRows byExtendingSelection:NO];
}

- (NSDictionary *) entityForRow: (NSInteger) row {
    return [self.updatesContent.arrangedObjects objectAtIndex:row];
}

- (Profile *)profileEntityForRow:(NSInteger)row {
    id result = row != -1 ? [self.updatesContent.arrangedObjects objectAtIndex:row] : nil;
    return [self isProfileEntity: result] ? result : nil;
}

- (BOOL) isProfileEntity: (NSObject *) object {
    return [object isKindOfClass:[Profile class]];
}

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"avatarImage"]) {
        // Find the row and reload it.
        // Note that KVO notifications may be sent from a background thread (in this case, we know they will be)
        // We should only update the UI on the main thread, and in addition, we use NSRunLoopCommonModes to make sure the UI updates when a modal window is up.
        [self performSelectorOnMainThread:@selector(_reloadRowForEntity:) withObject:object waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    } else if ([@"profiles" isEqualToString:keyPath]) {
        @synchronized(self) {
            NSArray * profiles = [change objectForKey:NSKeyValueChangeNewKey];
        
            [self.progress stopAnimation:self];
            [self.progress setHidden:YES];
        
            [self.profiles setContent:profiles];
        
            [profiles enumerateObjectsUsingBlock:^(Profile* profile, NSUInteger idx, BOOL *stop) {
                NSInteger index = profile ? [_observedVisibleItems indexOfObject:profile] : NSNotFound;
                if (index == NSNotFound) {
                    [profile.updatesMonitor addObserver:self forKeyPath:@"pendingUpdates" options:NSKeyValueObservingOptionNew context:(__bridge void *)(profile.id)];
                    [profile addObserver:self forKeyPath:@"avatarImage" options:NSKeyValueObservingOptionNew context:nil];
                    
                    [_observedVisibleItems addObject:profile];
                }

                if (profile.updatesMonitor.pendingUpdates != nil) {
                    [self.updates setObject:profile.updatesMonitor.pendingUpdates forKey:profile.id];
                }
            }];
        }
        
        [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
    } else if ([@"pendingUpdates" isEqualToString:keyPath]) {
        NSArray * updates = [change objectForKey:NSKeyValueChangeNewKey];
        _updatesHandler((__bridge NSString*) context, updates, nil);
    } else if ([@"isLaunchAtLoginEnabled" isEqualToString:keyPath]) {
        BOOL launchIsEnabled = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        self.launchAtLoginMenuItem.state = launchIsEnabled ? NSOnState : NSOffState;
    }
}
#pragma mark -
#pragma mark NSTableView
- (void)tableViewSelectionDidChange: (NSNotification *) notification {
    if (notification.object == self.updatesTable) {
        __block BOOL updateSelected = NO;
        [self.updatesTable.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            QUPendingUpdatesRowView *rowView = [self.updatesTable rowViewAtRow:idx makeIfNecessary:NO];
            if(rowView == nil || [self isProfileEntity:rowView.objectValue]) {
                *stop = YES;
                updateSelected = NO;
            } else {
                updateSelected = YES;
            }
        }];
        
        [self.removeButton setEnabled:updateSelected];
    }
}

//- (void)tableView:(NSTableView *)tableView didRemoveRowView:(QUPendingUpdatesRowView *)rowView forRow:(NSInteger)row {
//    if (tableView == self.updatesTable) {
//        // Stop observing visible things
//        NSObject *entity = [rowView objectValue];
//        NSInteger index = entity ? [_observedVisibleItems indexOfObject:entity] : NSNotFound;
//        if (index != NSNotFound) {
//            [entity removeObserver:self forKeyPath:@"avatarImage"];
//            [((Profile *)entity).updatesMonitor removeObserver:self forKeyPath:@"pendingUpdates"];
//            [_observedVisibleItems removeObjectAtIndex:index];
//        }
//        if ([self isProfileEntity:entity]) {
//            Profile *profile = (Profile *) entity;
//            [profile.updatesMonitor stopPoolling];
//        }
//    }
//}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    // Make the row view keep track of our main model object
    QUPendingUpdatesRowView *result = [[QUPendingUpdatesRowView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    result.objectValue = [self.updatesContent.arrangedObjects objectAtIndex:row];
    return result;
}

- (void)_reloadRowForEntity:(id)object {
    NSInteger row = [self.updatesContent.arrangedObjects indexOfObject:object];
    if (row != NSNotFound) {
        Profile *entity = [self profileEntityForRow:row];
        QUPendingTableCellView *cellView = [self.updatesTable viewAtColumn:0 row:row makeIfNecessary:NO];
        if (cellView) {
            cellView.imageView.image = [self resizeImage:entity.avatarImage size:[cellView.imageView bounds].size];
        }
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *entity = [self entityForRow:row];
    if (![self isProfileEntity:entity]) {
        QUUpdateTableCellView *cell = [tableView makeViewWithIdentifier:@"Update" owner:self];
        
        [cell.dayText setToolTip:[NSString stringWithFormat:@"%@ at %@", [entity objectForKey:@"day"], [entity objectForKey:@"due_time"]]];
        
        return cell;
    } else {
        QUPendingTableCellView *cell = [tableView makeViewWithIdentifier:@"Profile" owner:self];
        Profile *profile = (Profile *) entity;
        
        if (profile.avatarImage != nil) {
            [cell.imageView setImage:[self resizeImage:profile.avatarImage size:[cell.imageView bounds].size]];
        } else {
            // KVO will update the avatar when it's loaded
            [profile loadAvatar];
        }
        return cell;
    }
}

- (NSImage*) resizeImage:(NSImage*)sourceImage size:(NSSize)size
{
    NSRect targetFrame = NSMakeRect(0, 0, size.width, size.height);
    NSImage*  targetImage = [[NSImage alloc] initWithSize:size];
    
    [targetImage lockFocus];
    
    [sourceImage drawInRect:targetFrame
                   fromRect:NSZeroRect       //portion of source image to draw
                  operation:NSCompositeCopy  //compositing operation
                   fraction:1.0              //alpha (transparency) value
             respectFlipped:YES              //coordinate system
                      hints:@{NSImageHintInterpolation:
     [NSNumber numberWithInt:NSImageInterpolationMedium]}];
    
    [targetImage unlockFocus];
    
    return targetImage;
}

// We want to make "group rows" for the folders
- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    return [self isProfileEntity:[self entityForRow:row]];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    if ([self isProfileEntity:[self entityForRow:row]]) {
        return 30;
    } else {
        return 30;
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.updatesContent.arrangedObjects count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.updatesTable) {
        return [self.updatesContent.arrangedObjects objectAtIndex:row];
    }
    return nil;
}
#pragma mark -
#pragma mark Drag and Drop
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    if ([rowIndexes indexPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        QUPendingUpdatesRowView *rowView = [self.updatesTable rowViewAtRow:idx makeIfNecessary:NO];
        return rowView != nil && [self isProfileEntity:rowView.objectValue];
    }] == NSNotFound) {
        // Copy the row numbers to the pasteboard.
        NSData *zNSIndexSetData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
        [pboard declareTypes:[NSArray arrayWithObject:DRAG_AND_DROP_TYPE] owner:self];
        [pboard setData:zNSIndexSetData forType:DRAG_AND_DROP_TYPE];
        return YES;
    }
    return NO;
}

- (NSDragOperation)tableView:(NSTableView*)tv
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)operation {
    
    if( [info draggingSource] == tv) {
		if( operation == NSTableViewDropOn ) {
			[tv setDropRow:row dropOperation:NSTableViewDropAbove];
        }
		return NSDragOperationMove;
	} else {
		return NSDragOperationNone;
	}
}

// RSRTVArrayController.m
//
// RSRTV stands for Red Sweater Reordering Table View Controller.
//
// Based on code from Apple's DragNDropOutlineView example, which granted
// unlimited modification and redistribution rights, provided Apple not be held legally liable.
//
// Differences between this file and the original are © 2006 Red Sweater Software.
//
// You are granted a non-exclusive, unlimited license to use, reproduce, modify and
// redistribute this source code in any form provided that you agree to NOT hold liable
// Red Sweater Software or Daniel Jalkut for any damages caused by such use.
//
- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    if (row < 0)
	{
		row = 0;
	}
    
    // if drag source is self, it's a move or copy
    if ([info draggingSource] == tableView)
    {
        NSPasteboard *pasteboard = [info draggingPasteboard];
        NSData *rowData = [pasteboard dataForType:DRAG_AND_DROP_TYPE];
        NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
        
		[self moveObjectsInArrangedObjectsFromIndexes:rowIndexes toIndex:row];
        
        // set selected rows to those that were just moved
        // Need to work out what moved where to determine proper selection...
        NSInteger rowsAbove = [self rowsAboveRow:row inIndexSet:rowIndexes];
		
		NSRange range = NSMakeRange(row - rowsAbove, [rowIndexes count]);
		rowIndexes = [NSIndexSet indexSetWithIndexesInRange:range];
		[self.updatesContent setSelectionIndexes:rowIndexes];
		[self.updatesTable reloadData];
        NSDictionary * updatedProfile = [self updatesForRow:row];
        [_buffered reorderPendingUpdatesForProfile:[[updatedProfile allKeys] objectAtIndex:0] withOrder:[[updatedProfile allValues] objectAtIndex:0] withCompletionHandler:_updatesHandler];
		return YES;
    }
	
    return NO;
}

/*
 * Returns all updates for the profile the given row is associated with
 */
- (NSDictionary*)updatesForRow:(NSUInteger)row
{
    NSMutableArray * updates = [NSMutableArray new];
    Profile * profile = nil;
    for (NSInteger i = row; i >= 0; --i) {
        NSObject *rowContent = [[self.updatesContent arrangedObjects] objectAtIndex:i];
        if ([self isProfileEntity:rowContent]) {
            profile = (Profile *) rowContent;
            break;
        } else {
            [updates addObject:[(NSDictionary *)rowContent objectForKey: @"id"]];
        }
    }
    updates = [NSMutableArray arrayWithArray:[[updates reverseObjectEnumerator] allObjects]];
    if (row + 1 < [[self.updatesContent arrangedObjects] count]) {
        for (NSInteger i = row + 1, s = [[self.updatesContent arrangedObjects] count]; i < s; ++i) {
            NSObject *rowContent = [[self.updatesContent arrangedObjects] objectAtIndex:i];
            if ([self isProfileEntity:rowContent]) {
                break;
            } else {
                [updates addObject:[(NSDictionary *)rowContent objectForKey: @"id"]];
            }
        }
    }
    return @{[profile id] : updates};
}

// RSRTVArrayController.m
//
// RSRTV stands for Red Sweater Reordering Table View Controller.
//
// Based on code from Apple's DragNDropOutlineView example, which granted
// unlimited modification and redistribution rights, provided Apple not be held legally liable.
//
// Differences between this file and the original are © 2006 Red Sweater Software.
//
// You are granted a non-exclusive, unlimited license to use, reproduce, modify and
// redistribute this source code in any form provided that you agree to NOT hold liable
// Red Sweater Software or Daniel Jalkut for any damages caused by such use.
//

- (NSUInteger)rowsAboveRow:(NSUInteger)row inIndexSet:(NSIndexSet *)indexSet
{
    NSUInteger currentIndex = [indexSet firstIndex];
    NSInteger i = 0;
    while (currentIndex != NSNotFound)
    {
		if (currentIndex < row) { i++; }
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}

// RSRTVArrayController.m
//
// RSRTV stands for Red Sweater Reordering Table View Controller.
//
// Based on code from Apple's DragNDropOutlineView example, which granted
// unlimited modification and redistribution rights, provided Apple not be held legally liable.
//
// Differences between this file and the original are © 2006 Red Sweater Software.
//
// You are granted a non-exclusive, unlimited license to use, reproduce, modify and
// redistribute this source code in any form provided that you agree to NOT hold liable
// Red Sweater Software or Daniel Jalkut for any damages caused by such use.
//

-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet toIndex:(NSUInteger)insertIndex
{
    NSArray	*objects = [self.updatesContent arrangedObjects];
	NSUInteger thisIndex = [indexSet lastIndex];
	
    NSInteger aboveInsertIndexCount = 0;
    id object;
    NSInteger removeIndex;
	
    while (NSNotFound != thisIndex)
	{
		if (thisIndex >= insertIndex)
		{
			removeIndex = thisIndex + aboveInsertIndexCount;
			aboveInsertIndexCount += 1;
		}
		else
		{
			removeIndex = thisIndex;
			insertIndex -= 1;
		}
		
		// Get the object we're moving
		object = [objects objectAtIndex:removeIndex];
        
		// In case nobody else is retaining the object, we need to keep it alive while we move it
		[self.updatesContent removeObjectAtArrangedObjectIndex:removeIndex];
		[self.updatesContent insertObject:object atArrangedObjectIndex:insertIndex];
		
		thisIndex = [indexSet indexLessThanIndex:thisIndex];
    }
}
#pragma mark -
#pragma mark Actions
-(IBAction)removeSelectedUpdates:(id)sender {
    NSMutableArray *updatesToRemove = [NSMutableArray new];
    NSIndexSet *rowsToRemove = self.updatesTable.selectedRowIndexes;
    [rowsToRemove enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        QUPendingUpdatesRowView *rowView = [self.updatesTable rowViewAtRow:idx makeIfNecessary:NO];
        if (rowView != nil && ![self isProfileEntity:rowView.objectValue]) {
            [updatesToRemove addObject:rowView.objectValue];
        }
    }];
    
    [updatesToRemove enumerateObjectsUsingBlock:^(NSDictionary *update, NSUInteger idx, BOOL *stop) {
        [_buffered removeUpdate:update withCompletionHandler:_removeHandler];
    }];
}
-(IBAction)updateOperationButtonClicked:(id)sender {
    NSInteger row = [self.updatesTable rowForView:sender];
    NSInteger col = [self.updatesTable columnForView:sender];
    QUPendingUpdatesRowView *rowView = [self.updatesTable rowViewAtRow:row makeIfNecessary:NO];
    QUUpdateTableCellView *cellView = [self.updatesTable viewAtColumn:col row:row makeIfNecessary:NO];
    if (rowView != nil && cellView != nil) {
        NSDictionary *update = rowView.objectValue;
        if (cellView.removeButton == sender) {
            [_buffered removeUpdate:update withCompletionHandler:_removeHandler];
        } else if (cellView.publishButton == sender) {
            [_buffered shareUpdate:update withCompletionHandler:_removeHandler];
        }
    }
}
#pragma mark -
@end