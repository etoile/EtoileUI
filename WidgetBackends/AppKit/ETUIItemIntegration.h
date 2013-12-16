/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETWidget.h>

@class ETLayoutItem;

/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSView and ETUIItem. */
@interface NSView (ETUIItemSupportAdditions)

/** @taskunit Initialization */

+ (NSRect) defaultFrame;
- (id) init;

/** @taskunit UI Item Interaction */

- (BOOL) isWidget;
- (BOOL) isSupervisorView;
- (id) owningItem;

@end


/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSView and ETUIItem. */
@interface NSControl (ETUIItemSupportAdditions) <ETWidget>

/** @taskunit UI Item Interaction */

- (BOOL) isWidget;

/** @taskunit Copying */

- (id) copyWithZone: (NSZone *)zone;

@end


/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSPopUpButton and ETLayoutItem. */
@interface NSPopUpButton (ETUIItemSupportAdditions)
- (id) copyWithZone: (NSZone *)aZone;
@end


/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSTextField and ETLayoutItem. */
@interface NSTextField (ETUIItemSupportAdditions)
+ (NSRect) defaultFrame;
@end


/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSImageView and ETLayoutItem. */
@interface NSImageView (ETUIItemSupportAdditions)
- (BOOL) isWidget;
@end


/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSScrollView and ETUIItem. */
@interface NSScrollView (ETUIItemSupportAdditions)
- (BOOL) isWidget;
- (id) cell;
@end
