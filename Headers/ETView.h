/** <title>ETView</title>
	
	<abstract>Supervisor view class used to build view-backed items.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem, ETUIItem;

#ifdef GNUSTEP
// NOTE: This hack is needed because GNUstep doesn't retrieve -isFlipped in a 
// consistent way. For example in -[NSView _rebuildCoordinates] doesn't call 
// -isFlipped and instead retrieve it directly from the rFlags structure.
#define USE_NSVIEW_RFLAGS
#endif

/** ETView is the generic view class extensively used by EtoileUI and whose 
instance are named 'supervisor view'.

An ETView instance is bound to a layout item or a decorator item unlike NSView 
instances. ETLayoutItem automatically wraps any view you set with -setView: into 
a supervisor view.
	
The supervisor view is a wrapper that allows EtoileUI to intercept the drawing 
process. ETView delegates the drawing to its item in the -render:  method.<br />
More importantly, -render: isn't truly a delegated version of -drawRect:. 
This method makes possible to draw directly over the subviews rather than 
beneath. This drawing path is widely used in EtoileUI.
	
You must not subclass ETView.

Take note that we plan to eliminate ETView and the supervisor view concept in a 
next EtoileUI release. */
@interface ETView : NSView
{
	IBOutlet ETUIItem *item;
	// NOTE: May be remove the view ivars to make the class more lightweight
	NSView *_wrappedView;
	/* _temporaryView is a weak reference (we retain it indirectly as a subview 
	   though).
	   We are owned by our layout item which retains its layout which itself 
	   retains the layout view. Each time the layout is switched on -layoutItem, 
	   we must update _temporaryView with -setLayoutView: otherwise the ivar
	   might reference a freed object. See -[ETLayoutItem setLayout:]. */
	NSView *_temporaryView;
#ifndef USE_NSVIEW_RFLAGS
	BOOL _flipped;
#endif
#ifndef GNUSTEP
	BOOL _wasJustRedrawn;
#endif
	NSRect _rectToRedraw;
}

- (id) initWithFrame: (NSRect)rect item: (ETUIItem *)item;
- (id) initWithLayoutView: (NSView *)layoutView;

- (NSArray *) properties;

/* Basic Accessors */

// TODO: Rename -layoutItem to -item. Will be done separately because it is a 
// pretty big change which needs to be handled very carefully.
- (id) layoutItem;
- (void) setItemWithoutInsertingView: (ETUIItem *)item;
- (BOOL) isFlipped;
- (void) setFlipped: (BOOL)flag;

/* Embbeded Views */

- (void) setWrappedView: (NSView *)subview;
- (NSView *) wrappedView;
- (void) setTemporaryView: (NSView *)subview;
- (NSView *) temporaryView;
- (NSView *) contentView;

@end
