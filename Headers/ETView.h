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

/** ETView is the generic view class extensively used by EtoileUI. It 
	implements several facilities in addition to the ones already provided by
	NSView. If you want to write Etoile-native UI code, you should always use
	or subclass ETView and not NSView when you need a custom view and you don't
	rely an AppKit-specific NSView subclasses.
	Take note that if you want to add subviews (or child items) you should use
	ETContainer and not ETView which throws exceptions if you try to call 
	-addSubview: directly.
	
	A key feature is additional control and flexibility over the 
	drawing process. It lets you sets a render delegate by calling 
	-setRenderer:. This delegate can implement -render:  method to avoid the 
	tedious subclassing involved by -drawRect:. 
	More importantly, -render: isn't truly a delegated version of -drawRect:. 
	This new method enables the possibility to draw directly over the subviews 
	by offering another drawing path. This drawing option is widely used in 
	EtoileUI and is the entry point of every renderer chains when they are 
	asked to render themselves on screen. See Display Tree Description if you
	want to know more. 
	
	An ETView instance is also always bound to a layout item unlike NSView 
	instances. When a view is set on a layout item, when this view isn't an
	ETView class or subclass instance, ETLayoutItem automatically wraps the
	view in an ETView making possible to apply renderers, styles etc. over the
	real view.
*/

// TODO: Implement ETTitleBarView subclass to handle the title bar as a layout
// item which can be introspected and edited at runtime. A subclass is 
// necessary to create the title bar of title bars in a lazy way, otherwise
// ETView instantiation would lead to infinite recursion on the title bar set up.

@interface ETView : NSView
{
	IBOutlet ETLayoutItem *item;
	// NOTE: May be remove the view ivars to make the class more lightweight
	NSView *_wrappedView;
	/* NOTE: _temporaryView is a weak reference (we retain it indirectly as a 
	   subview though).
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

- (id) initWithFrame: (NSRect)rect layoutItem: (ETLayoutItem *)item;
- (id) initWithLayoutView: (NSView *)layoutView;

- (NSArray *) properties;

/* Basic Accessors */

// TODO: Rename -layoutItem to -item. Will be done separately because it is a 
// pretty big change which needs to be handled very carefully.
- (id) layoutItem;
- (void) setItem: (ETUIItem *)item;
- (void) setLayoutItemWithoutInsertingView: (ETLayoutItem *)item;
- (BOOL) isFlipped;
- (void) setFlipped: (BOOL)flag;

/* Embbeded Views */

- (void) setWrappedView: (NSView *)subview;
- (NSView *) wrappedView;
- (void) setTemporaryView: (NSView *)subview;
- (NSView *) temporaryView;
- (NSView *) contentView;

/* Subclassing */

- (NSView *) mainView;
- (void) tile;

@end
