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
