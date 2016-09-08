/**
	Copyright (C) 2016 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  August 2016
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSView.h>

#ifdef GNUSTEP
// NOTE: This hack is needed because GNUstep doesn't retrieve -isFlipped in a 
// consistent way. For example in -[NSView _rebuildCoordinates] doesn't call 
// -isFlipped and instead retrieve it directly from the rFlags structure.
#define USE_NSVIEW_RFLAGS
#endif

/** @abstract A view that supports flipping its coordinate system orientation. */
@interface ETFlippableView : NSView
{
	@private
#ifndef USE_NSVIEW_RFLAGS
	BOOL _flipped;
#endif
}

/** This property is only exposed to be used internally by EtoileUI.

Whether the receiver uses flipped coordinates or not.

You must never use this property but -[ETLayoutItem isFlipped] and 
-[ETLayoutItem setFlipped:]. */
@property (nonatomic, getter=isFlipped, readwrite) BOOL flipped;

@end
