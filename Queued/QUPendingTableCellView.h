//
//  BUPendingTableCellView.h
//  Buffered
//
//  Created by Pawel Niewiadomski on 17.03.2013.
//  Copyright (c) 2013 Pawel Niewiadomski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QUPendingTableCellView : NSTableCellView

@property (assign) IBOutlet NSProgressIndicator *avatarLoadingIndicator;
@property (assign) IBOutlet NSProgressIndicator *inProgressIndicator;

@end

@interface QUUpdateTableCellView : NSTableCellView {
@private
    NSTrackingArea *trackingArea;
}

@property (assign) IBOutlet NSTextField *dayText;
@property (assign) IBOutlet NSButton *removeButton;
@property (assign, readonly) BOOL mouseInside;

@end