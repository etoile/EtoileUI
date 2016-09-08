/*
	Copyright (C) 2016 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  August 2016
	License:  Modified BSD  (see COPYING)
 */

#import "ETFlippableView.h"

@implementation ETFlippableView

/** This method is only exposed to be used internally by EtoileUI.<br />
You must never call this method but -[ETLayoutItem isFlipped:].

Returns whether the receiver uses flipped coordinates or not.

Default returned value is YES. */
- (BOOL) isFlipped
{
#ifdef USE_NSVIEW_RFLAGS
 	return _rFlags.flipped_view;
#else
	return _flipped;
#endif
}

/** This method is only exposed to be used internally by EtoileUI.<br />
You must never call this method but -[ETLayoutItem setFlipped:].

Unlike NSView, ETView uses flipped coordinates by default.

You can revert to non-flipped coordinates by passing NO to this method. */
- (void) setFlipped: (BOOL)flag
{
#ifdef USE_NSVIEW_RFLAGS
	_rFlags.flipped_view = flag;
	[self _invalidateCoordinates];
	[self _rebuildCoordinates];
#else
	_flipped = flag;
#endif
}

@end
