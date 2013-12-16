/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem;

/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSView and ETUIItem. */
@interface NSView (ETUIItemSupportAdditions)
+ (NSRect) defaultFrame;
- (id) init;
- (BOOL) isWidget;
- (BOOL) isSupervisorView;
- (id) owningItem;
@end

/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSText and ETResponder. */
@interface NSText (ETUIItemSupportAdditions)
- (ETLayoutItem *) candidateFocusedItem;
@end

/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSScrollView and ETResponder. */
@interface NSScrollView (ETUIItemSupportAdditions)
- (BOOL) isWidget;
- (id) cell;
@end
