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
 
@abstract Additions to integrate NSResponder and ETResponder. */
@interface NSResponder (ETResponderSupportAdditions)
@property (nonatomic, readonly) ETLayoutItem *candidateFocusedItem;
@end


/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSView and ETResponder. */
@interface NSView (ETResponderSupportAdditions)
@property (nonatomic, readonly) ETLayoutItem *candidateFocusedItem;
@property (nonatomic, readonly) id responder;
@end


/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSText and ETResponder. */
@interface NSText (ETResponderSupportAdditions)
@property (nonatomic, readonly) ETLayoutItem *candidateFocusedItem;
@end


/** @group AppKit Widget Backend
 
@abstract Additions to integrate NSScrollView and ETResponder. */
@interface NSScrollView (ETResponderSupportAdditions)
@property (nonatomic, readonly) id responder;
@end
