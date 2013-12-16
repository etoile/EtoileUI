/**
	<abstract>NSCell additions.</abstract>

	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2010
	License: Modified BSD (see COPYING)
 */


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSCell and ETLayoutItem. */
@interface NSCell (ETUIItemCellSupportAdditions)
- (id) objectValueForObject: (id)anObject;
- (id) objectValueForCurrentValue: (id)aValue;
- (id) currentValueForObjectValue: (id)aValue;
// NOTE: We might need to make the same changes to NSControl.
- (void) willChangeValueForKey: (NSString *)aKey;
- (void) didChangeValueForKey: (NSString *)aKey;
@end


/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSImageCell and ETLayoutItem. */
@interface NSImageCell (ETUIItemCellSupportAdditions)
- (id) objectValueForObject: (id)anObject;
@end


/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSPopUpButtonCell and ETLayoutItem. */
@interface NSPopUpButtonCell (ETUIItemCellSupportAdditions)
- (id) objectValueForCurrentValue: (id)aValue;
- (id) currentValueForObjectValue: (id)aValue;
@end
