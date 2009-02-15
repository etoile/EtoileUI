/*  <title>ETView</title>
	
	ETView.m
	
	<abstract>NSView replacement class with extra facilities like delegated drawing.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileUI/ETView.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCompatibility.h>
#import <EtoileUI/ETFlowLayout.h>
#import <EtoileUI/ETContainer.h>
#define NC [NSNotificationCenter defaultCenter]

NSString *ETViewTitleBarViewPrototypeDidChangeNotification = @"ETViewTitleBarViewPrototypeDidChangeNotification";

#ifndef GNUSTEP
@interface NSView (CocoaPrivate)
- (void) _recursiveDisplayAllDirtyWithLockFocus: (BOOL)lockFocus visRect: (NSRect)aRect;
- (void) _recursiveDisplayRectIfNeededIgnoringOpacity: (NSRect)aRect 
	isVisibleRect: (BOOL)isVisibleRect rectIsVisibleRectForView: (BOOL)isRectForView topView: (BOOL)isTopView;
@end
#endif

@interface ETView (Private)
- (void) titleBarViewPrototypeDidChange: (NSNotification *)notif;
- (void) setContentView: (NSView *)view temporary: (BOOL)temporary;
- (void) _setTitleBarView: (NSView *)barView;
@end


@implementation ETView

/* Title bar */

static ETView *barViewPrototype = nil;

+ (void) initialize
{
	if (self == [ETView class])
	{
		barViewPrototype = 
			[[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)];
		[barViewPrototype setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	}
}

+ (void) setTitleBarViewPrototype: (NSView *)barView
{
	if (barView == nil)
	{
		[NSException raise: NSInvalidArgumentException format: @"For ETView, "
			@"+setTitleBarViewPrototype: parameter must be never be nil"];
	}
	ASSIGN(barViewPrototype, barView);
	[NC postNotificationName: ETViewTitleBarViewPrototypeDidChangeNotification
		              object: self
					userInfo: nil];
}

+ (NSView *) titleBarViewPrototype
{
	return barViewPrototype;
}

- (id) initWithFrame: (NSRect)frame
{
	return [self initWithFrame: frame layoutItem: nil];
}

/* <init /> */
- (id) initWithFrame: (NSRect)frame layoutItem: (ETLayoutItem *)item
{
	self = [super initWithFrame: frame];
	
	if (self != nil)
	{
		/* In both cases, the item will be set by calling 
		   -setLayoutItemWithoutInsertingView: that creates a retain cycle by
		    retaining it. */
		if (item != nil)
		{
			[self setLayoutItem: item];
		}
		else
		{
			_layoutItem = [[ETLayoutItem alloc] initWithView: self];
			/* -initWithView: has called back -setLayoutItemWithoutInsertingView:
			   which retained _layoutItem, so we release it.

			   We could alternatively do:
			   _layoutItem = [[ETLayoutItem alloc] init];
			   [_layoutItem setView: self];
			   RELEASE(_layoutItem);
			   In any cases, we avoid to call +layoutItem (and eliminate the 
			   last line RELEASE as a byproduct) in order to simplify the 
			   testing of the retain cycle with 
			   GSDebugAllocationCount([ETLayoutItem class]). By not creating an 
			   autoreleased instance, we can ensure that releasing the receiver 
			   will dealloc the layout item immediately and won't delay it until 
			   the autorelease pool is deallocated.
			 */
			RELEASE(_layoutItem);
		}
		[self setRenderer: nil];
		//[self setFlipped: YES];
		[self setTitleBarView: nil]; /* Sets up a +titleBarViewPrototype clone */
		[self setDisclosable: NO];
		[self setAutoresizesSubviews: YES];	/* NSView set up */
		
		[NC addObserver: self 
		       selector: @selector(titleBarViewPrototypeDidChange:) 
			       name: ETViewTitleBarViewPrototypeDidChangeNotification
				 object: nil];
	}
	
	return self;
}

// NOTE: Mac OS X doesn't always update the ref count returned by 
// NSExtraRefCount if the memory management methods aren't overriden to use
// the extra ref count functions.
#ifndef GNUSTEP
- (id) retain
{
	NSIncrementExtraRefCount(self);
	return self;
}

- (unsigned int) retainCount
{
	return NSExtraRefCount(self) + 1;
}
#endif

- (oneway void) release
{
	BOOL hasRetainCycle = (_layoutItem != nil);
	/* Memorize whether the next release call will deallocate the receiver, 
	   because once the receiver is deallocated you have no way to safely learn 
	   if self is still valid or not.
	   Take note the retain count is NSExtraRefCount plus one. */
	int refCountWas = NSExtraRefCount(self);

	/* Dealloc if only retained by ourself (ref count equal to zero), otherwise 
	   decrement ref count. */
#ifdef GNUSTEP
	[super release];
#else
	if (NSDecrementExtraRefCountWasZero(self))
		[self dealloc];
#endif

	/* Exit if we just got deallocated above. 
	   In that case, self and _layoutItem are now both deallocated and invalid 
	   and we must never use them (by sending a message for example). */
	BOOL isDeallocated = (refCountWas == 0);
	if (isDeallocated)
		return;

	/* Tear down the retain cycle owned by the layout item.
	   If we are only retained by our layout item which is also retained only 
	   by us, DESTROY(_layoutItem) will call -[ETLayoutItem dealloc] which in 
	   turn will call back -[ETView release] and result this time in our 
	   deallocation. */	
	BOOL isGarbageCycle = (hasRetainCycle 
		&& NSExtraRefCount(self) == 0 && NSExtraRefCount(_layoutItem) == 0);
	if (isGarbageCycle)
		DESTROY(_layoutItem);
}

- (void) dealloc
{
	[NC removeObserver: self];

	// NOTE: _layoutItem (our owner) is destroyed by -release
	DESTROY(_renderer);
	DESTROY(_temporaryView);
	DESTROY(_wrappedView);
	DESTROY(_titleBarView);
	
	[super dealloc];
}

/* Archiving */

- (void) encodeWithCoder: (NSCoder *)coder
{
	if ([coder allowsKeyedCoding] == NO)
	{	
		[NSException raise: NSInvalidArgumentException format: @"ETView only "
			@"supports keyed archiving"];
	}

	[super encodeWithCoder: coder];

	//[coder encodeObject: nil forKey: @"ETLayoutItem"];	
	// FIXME: Replace by
	// [coder encodeLateBoundObject: [self renderer] forKey: @"ETRenderer"];
	[coder encodeObject: [self renderer] forKey: @"ETRenderer"];
	[coder encodeObject: [self titleBarView] forKey: @"ETTitleBarView"];
	[coder encodeObject: [self wrappedView] forKey: @"ETWrappedView"];	
	[coder encodeObject: [self temporaryView] forKey: @"ETTemporaryView"];
	[coder encodeBool: [self isDisclosable] forKey: @"ETDisclosable"];
	[coder encodeBool: [self usesCustomTitleBar] forKey: @"ETUsesCustomTitleBar"];
}

- (id) initWithCoder: (NSCoder *)coder
{
	self = [super initWithCoder: coder];
	
	if ([coder allowsKeyedCoding] == NO)
	{	
		[NSException raise: NSInvalidArgumentException format: @"ETView only "
			@"supports keyed unarchiving"];
		return nil;
	}
	
	// NOTE: Don't use accessors, they involve a lot of set up logic and they
	// would change the subviews in relation with their call order.
	_usesCustomTitleBar = [coder decodeBoolForKey: @"ETUsesCustomTitleBar"];	
	_disclosable = [coder decodeBoolForKey: @"ETDisclosable"];
	ASSIGN(_titleBarView, [coder decodeObjectForKey: @"ETTitleBarView"]);
	ASSIGN(_wrappedView, [coder decodeObjectForKey: @"ETWrappedView"]);
	ASSIGN(_temporaryView, [coder decodeObjectForKey: @"ETTemporaryView"]);

	//[coder decodeObjectForKey: @"ETRenderer"];
	//[coder decodeObjectForKey: @"ETLayoutItem"];

	return self;
}

- (NSString *) displayName
{
	// FIXME: Trim the angle brackets out.
	NSString *desc = @"<";
	
	if ([self wrappedView] != nil)
		desc = [desc stringByAppendingFormat: @"%@ in ", [[self wrappedView] className]];
	desc = [desc stringByAppendingFormat: @"%@>", [super description]];
	return desc;
}

- (BOOL) acceptsFirstResponder
{
	//ETLog(@"%@ accepts first responder", self);
	return YES;
}

/* Basic Accessors */

/** Returns the layout item representing the receiver in the layout item 
	tree. 
	Never returns nil. */
- (id) layoutItem
{
	// NOTE: We must use -primitiveDescription not to enter an infinite loop
	// with -description calling -layoutItem
	/*NSAssert1(_layoutItem != nil, @"Layout item of %@ must never be nil", [self primitiveDescription]);*/
	if (_layoutItem == nil)
		ETLog(@"Layout item of %@ must never be nil", [self primitiveDescription]);
	return _layoutItem;
}

/** Sets the layout item representing the receiver view in the layout item
	tree. When the layout item has an ancestor layout item which represents a
	view, then the receiver is added as a subview to this view. So by binding 
	a new layout item to a view, you may move the view to a different place in
	the view hierarchy.
	Throws an exception when item parameter is nil. */
- (void) setLayoutItem: (ETLayoutItem *)item
{
	[self setLayoutItemWithoutInsertingView: item];
	[_layoutItem setView: self];
}

/** You should never need to call this method. */
- (void) setLayoutItemWithoutInsertingView: (ETLayoutItem *)item
{	
	if (item == nil)
	{
		[NSException raise: NSInvalidArgumentException format: @"For ETView, "
			@"-setLayoutItem: parameter %@ must be never be nil", item];
	}	
	ASSIGN(_layoutItem, item); // NOTE: Retain cycle (see -release)
}

- (void) setRenderer: (id)renderer
{
	ASSIGN(_renderer, renderer);
}

- (id) renderer
{
	//return _renderer;
	return [self layoutItem];
}

/** Returns whether the receiver uses flipped coordinates or not.

Default returned value is YES. */
- (BOOL) isFlipped
{
#ifdef USE_NSVIEW_RFLAGS
 	return _rFlags.flipped_view;
#else
	return _flipped;
#endif
}

/** Unlike NSView, ETContainer uses flipped coordinates by default in order to 
simplify layout computation.

You can revert to non-flipped coordinates by passing NO to this method. */
- (void) setFlipped: (BOOL)flag
{
#ifdef USE_NSVIEW_RFLAGS
	_rFlags.flipped_view = flag;
#else
	_flipped = flag;
#endif
}

/* Embbeded Views */

/** Recomputes the positioning of both the main view and the title bar view
	depending on whether they are visible or not. */
- (void) tile
{
	id mainView = [self mainView];
	id titleBarView = [self titleBarView];
	
	/* Reset main view frame to fill the receiver */
	[mainView setFrameOrigin: NSZeroPoint];
	[mainView setFrameSize: [self frame].size];
	
	/* Reset autoresizing */
	[mainView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[titleBarView setAutoresizingMask: NSViewWidthSizable];
	[self setAutoresizesSubviews: YES];
	
	/* Position and size both title bar view and main view to fill the receiver
	   in a stack-like layout */
	if ([self isTitleBarVisible])
	{
		if (mainView != nil)
		{
			[mainView setHeightFromBottomLeft: [mainView height] - [titleBarView height]];
			[titleBarView setFrameOrigin: [mainView topLeftPoint]];
		}
		else
		{
			// TODO: This is a bit convoluted, we may be better getting rid of
			// this flipping dependent code.
			if ([self isFlipped])
			{
				[titleBarView setFrameOrigin: NSZeroPoint];
			}
			else
			{
				[titleBarView setFrameOrigin: 
					NSMakePoint(0, [self height] - [titleBarView height])];
			}
		}
		[titleBarView setWidth: [self width]];
	}
	/*else
	{
		if (mainView != nil)
			[mainView setHeightFromBottomLeft: [self height]];
	}*/
}

- (BOOL) isTitleBarVisible
{
	return ([[self titleBarView] superview] != nil);
}

- (BOOL) usesCustomTitleBar
{
	return _usesCustomTitleBar;
}

- (void) titleBarViewPrototypeDidChange: (NSNotification *)notif
{
	if ([self usesCustomTitleBar] == NO)
		[self setTitleBarView: nil];
}

- (void) setTitleBarView: (NSView *)barView
{
	if (barView != nil)
	{
		[self _setTitleBarView: barView];
		_usesCustomTitleBar = YES;
	}
	else
	{
		id barViewProto = AUTORELEASE([[ETView titleBarViewPrototype] copy]);
		[self _setTitleBarView: barViewProto];		
		_usesCustomTitleBar = NO;
	}
}

		 /* barView will be the initially inserted title bar view.
			ETView instance initialization is the most common case. */
- (void) _setTitleBarView: (NSView *)barView
{
	BOOL prevTitleBarVisible = [self isTitleBarVisible];
	
	if (_titleBarView != nil)
	{
		NSRect titleBarFrame = [_titleBarView frame];
		
		/* Sync old and new title bar frame except the height of the new bar 
		   view */
		titleBarFrame.size.height = [barView height];
		[barView setFrame: titleBarFrame];

		/* Remove previous title bar when visible */
		if (prevTitleBarVisible)
			[_titleBarView removeFromSuperview];
	}
	
	ASSIGN(_titleBarView, barView);
	
	/* Inserts possibly the new title bar */
	if (prevTitleBarVisible)
	{
		[self addSubview: _titleBarView];
		[self tile];
	}
}

- (NSView *) titleBarView
{
	return _titleBarView;
}

- (void) setWrappedView: (NSView *)view
{
	// NOTE: Next lines must be kept in this precise order and -tile not moved
	// into -setContentView:temporary:
	[self setContentView: view temporary: NO];
	ASSIGN(_wrappedView, view);
	[self tile]; /* Update view layout */
}

- (NSView *) wrappedView
{
	return _wrappedView;
}

/** Sets the view to be used  temporarily as a wrapped view. When such a view 
	is set, this view is displayed in place of -wrappedView.
	If you pass nil, the displayed wrapped view is reverted to the view
	originally set on -setWrappedView: call. */
- (void) setTemporaryView: (NSView *)subview
{
	// NOTE: Next lines must be kept in this precise order and -tile not moved
	// into -setContentView:temporary:
	[self setContentView: subview temporary: YES];
	ASSIGN(_temporaryView, subview);
	[self tile]; /* Update view layout */
}

/** Returns the wrapped view temporarily overriding the default wrapped view or 
	nil if there is none. When such a view is set, this view is displayed in 
	place of -wrappedView. */
- (NSView *) temporaryView
{
	return _temporaryView;
}

/** You must override this method in subclasses. */
- (void) setContentView: (NSView *)view temporary: (BOOL)temporary
{
	/* Ensure the resizing of all subviews is handled automatically */
	[self setAutoresizesSubviews: YES];
	[self setAutoresizingMask: [view autoresizingMask]];
	
	if (temporary) /* Temporary view setter */
	{
		if (view != nil)
		{
			[view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
			[self addSubview: view];
			[[self wrappedView] setHidden: YES];
		}
		else /* Passed a nil temporary view */
		{
			/* Restore autoresizing mask */
			[[self temporaryView] setAutoresizingMask: [self autoresizingMask]];
			[[self temporaryView] removeFromSuperview];
			[[self wrappedView] setHidden: NO];
		}
	}
	else /* Wrapped view setter */
	{
		if (view != nil)
		{
			[view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
			[self addSubview: view];
		}
		else /* Passed a nil wrapped view */
		{
			/* Restore autoresizing mask */
			[[self wrappedView] setAutoresizingMask: [self autoresizingMask]];
			[[self wrappedView] removeFromSuperview];
		}	
	}
}

/** Returns the current content view which is either the wrapped view or 
	the temporary view. The wrapped view is returned when -temporaryView
	is nil. When a temporary view is set, it overrides the wrapped view
	in the role of content view. 
	Take note that as long as -temporaryView returns a non nil value, 
	calling -setWrappedView: has no effect on -contentView, the method
	will continue to return the temporary view.  */
- (NSView *) contentView
{
	NSView *contentView = [self temporaryView];
	
	if (contentView == nil)
		contentView = [self wrappedView];
	
	return contentView;
}

/** Sets whether the title bar should be visible or not. 
	When the title bar view is displayed, the receiver becomes disclosable 
	usually by clicking on disclosure indicator. */
- (void) setDisclosable: (BOOL)flag
{
	NSView *titleBarView = [self titleBarView];

	_disclosable = flag;

	/* Hide or show title bar */
	if (_disclosable && [self isTitleBarVisible] == NO)
	{
		[self addSubview: titleBarView];
	}
	else if (_disclosable == NO && [self isTitleBarVisible])
	{
		[titleBarView removeFromSuperview];
	}
	[self tile]; /* Update view layout */
}

/** Returns whether the title bar is visible, thereby disclosable or not. */
- (BOOL) isDisclosable
{
	return _disclosable;
}

/** Returns whether the content view is visible or not. When the receiver is
	expanded, only the title bar can remain visible. */
- (BOOL) isExpanded
{
	return ([[self mainView] superview] == nil);
}

/* Actions */

- (void) collapse: (id)sender
{
	if ([self isDisclosable])
	{
		NSAssert1([self isTitleBarVisible], @"View %@ cannnot be correctly "
			@"collapsed because title bar view hasn't been inserted", self);
		
		[[self wrappedView] removeFromSuperview];
	}
	else
	{
		ETLog(@"WARNING: View %@ isn't disclosable, yet it is asked to "
			@"collapse", self);	
	}
}

- (void) expand: (id)sender
{
	if ([self isDisclosable])
	{
		/* If already expanded, nothing to do */
		if ([[self subviews] containsObject: [self mainView]])
			return;
		
		if ([self mainView] != nil) /* No content view is set (init case)*/
			[self addSubview: [self mainView]];
		[self tile]; /* Update view layout */
	}
	else
	{
		ETLog(@"WARNING: View %@ isn't disclosable, yet it is presently "
			"collapsed and asked to expand", self);
	}
}

/* Property Value Coding */

- (id) valueForProperty: (NSString *)key
{
	id value = nil;

	if ([[self properties] containsObject: key])
		value = [self valueForKey: key];
		
	if (value == nil)
		ETLog(@"WARNING: Found no value for property %@ in view %@", key, self);
		
	return value;
}

- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	if ([[self properties] containsObject: key])
	{
		[self setValue: value forKey: key];
		return YES;
	}
	else
	{
		ETLog(@"WARNING: Trying to set value %@ for property %@ missing in "
			@"immutable property collection of view %@", value, key, self);
		return NO;
	}
}

- (NSArray *) properties
{
	// NOTE: We may expose other properties in future
	id properties = [NSArray arrayWithObjects: @"disclosable", nil];
	
	return [[super properties] arrayByAddingObjectsFromArray: properties];
}

/* Live Development */

/*- (BOOL) isEditingUI
{
	return _isEditingUI;
}*/

/* Subclassing */

/** Returns the direct subview of the receiver which is displayed right under 
	the title bar. The returned value is identical to -wrappedView. 
	If you write an ETView subclass where the wrapped view is put inside another
	view (like a scroll view), you must override this method to return this 
	superview. 
	This method should never be called directly, uses -contentView, -wrappedView
	or -temporaryView instead. */
- (NSView *) mainView
{
	return [self wrappedView];
}

/* Rendering Tree */

/* INTERLEAVED_DRAWING must always be enabled. 
   You might want to disable it for debugging how the control of the drawing is 
   handed by ETView to the layout item tree.
   
   With INTERLEAVED_DRAWING, the drawing of the layout item follows the drawing
   of the view its represents and all related subviews. This view is called the 
   supervisor view and is an ETView instance. The supervisor view can embed a 
   subview that is returned by -[ETLayoutItem view] and -[ETView wrappedView].
   Hence the layout item is able to draw its style (border, selection indicators 
   etc.) on top of the wrapped view.

   Without INTERLEAVED_DRAWING, the drawing of the layout item only occurs 
   within -drawRect: and precedes the drawing of the view its represents and all 
   related subviews. Thereby the drawing of the style of an item will be covered 
   by the drawing of its view. If the item has no view, the issue doesn't exist. 
   This view is a subview of our closest ancestor view where the item style is 
   drawn through -drawRect:, but a superview -drawRect: is followed by the 
   -drawRect: of subviews, that's why the item style cannot be drawn properly 
   in such cases. */
#define INTERLEAVED_DRAWING 1

#ifndef INTERLEAVED_DRAWING

/** Now we must let layout items handles their custom drawing through their 
style object. For example, by default an item with or without a view has a style 
to draw its selection state. 

In addition, this style implements the logic to draw layout items without 
view that plays a role similar to cell.

Layout items are smart enough to avoid drawing their view when they have one. */
- (void) drawRect: (NSRect)rect
{
	[super drawRect: rect];

	/* We always composite the rendering chain on top of each view -drawRect: 
	   drawing sequence (triggered by display-like methods). */
	if ([[self renderer] respondsToSelector: @selector(render:dirtyRect:inView:)])
	{
		[[self renderer] render: nil dirtyRect: rect inView: self];
	}
}

#else

- (void) displayIfNeeded
{
	//ETLog(@"-displayIfNeeded");
	[super displayIfNeeded];
}

- (void) displayIfNeededInRect:(NSRect)aRect
{
	//ETLog(@"-displayIfNeededInRect:");
	[super displayIfNeededInRect: aRect];
}

- (void) displayIfNeededInRectIgnoringOpacity:(NSRect)aRect
{
	//ETLog(@"-displayIfNeededInRectIgnoringOpacity:");
	[super displayIfNeededInRectIgnoringOpacity: aRect];
}

- (void) display
{	
	//ETLog(@"-display");
	[super display];
}

- (void) displayRect:(NSRect)aRect
{
	//ETLog(@"-displayRect:");
	[super displayRect: aRect];
}

- (void) displayRectIgnoringOpacity:(NSRect)aRect
{
	//ETLog(@"-displayRectIgnoringOpacity:");
	[super displayRectIgnoringOpacity: aRect];
}

#ifdef GNUSTEP

/* Main and canonical method which is used to take control of the drawing on 
GNUstep and pass it to the layout item tree as needed. */
- (void) displayRectIgnoringOpacity: (NSRect)aRect 
                          inContext: (NSGraphicsContext *)context
{
	//ETLog(@"-displayRectIgnoringOpacity:inContext:");
	[super displayRectIgnoringOpacity: aRect inContext: context];
	
	[self lockFocus];

	/* We always composite the rendering chain on top of each view -drawRect: 
	   drawing sequence (triggered by display-like methods). */
	if ([[self renderer] respondsToSelector: @selector(render:dirtyRect:inView:)])
	{
		[[self renderer] render: nil dirtyRect: aRect inView: self];
	}

	[self unlockFocus];
}

#else

// NOTE: Very often NSView instance which has been sent a display message will 
// call this method on its subviews. These subviews will do the same with their own 
// subviews. Here is the other method often used in the same way:
//_recursiveDisplayRectIfNeededIgnoringOpacity:isVisibleRect:rectIsVisibleRectForView:topView:
// The previous method usually follows the message on next line:
//_displayRectIgnoringOpacity:isVisibleRect:rectIsVisibleRectForView:

/* First canonical method which is used to take control of the drawing on 
Cocoa and pass it to the layout item tree as needed. */
- (void) _recursiveDisplayAllDirtyWithLockFocus: (BOOL)lockFocus visRect: (NSRect)aRect
{
	ETDebugLog(@"-_recursiveDisplayAllDirtyWithLockFocus:visRect: %@", self);
	[super _recursiveDisplayAllDirtyWithLockFocus: lockFocus visRect: aRect];

	/* Most of the time, the focus isn't locked. In this case, aRect is a 
	   portion of the content view frame and no clipping is done either. */
	if (lockFocus == YES)
	{
		[self lockFocus];
	}

#ifdef DEBUG_DRAWING
	//if ([self respondsToSelector: @selector(layout)] && [[(ETContainer *)self layout] isKindOfClass: [ETFlowLayout class]])
	{
		[[NSColor blackColor] set];
		[NSBezierPath setDefaultLineWidth: 6.0];
		[NSBezierPath strokeRect: aRect];
	}
#endif

	/* We always composite the rendering chain on top of each view -drawRect: 
	   drawing sequence (triggered by display-like methods). */
	if ([[self renderer] respondsToSelector: @selector(render:dirtyRect:inView:)])
	{
		[[self renderer] render: nil dirtyRect: aRect inView: self];
	}

	if (lockFocus == YES)
		[self unlockFocus];
		
	_wasJustRedrawn = YES;
}

/* Second canonical method which is used to take control of the drawing on 
Cocoa and pass it to the layout item tree as needed. */
- (void) _recursiveDisplayRectIfNeededIgnoringOpacity: (NSRect)aRect 
	isVisibleRect: (BOOL)isVisibleRect rectIsVisibleRectForView: (BOOL)isRectForView topView: (BOOL)isTopView
{
	_wasJustRedrawn = NO;

	[super _recursiveDisplayRectIfNeededIgnoringOpacity: aRect 
		isVisibleRect: isVisibleRect rectIsVisibleRectForView: isRectForView topView: isTopView];

	ETDebugLog(@"-_recursiveDisplayRectIfNeededIgnoringOpacity:XXX %@ %@", self, NSStringFromRect(aRect));
	
	/* From what I have observed, _recursiveDisplayAllDirtyXXX was only called 
	   when isVisibleRect and isRectForView are both NO, or when live resize 
	   was underway (in that case the invalidated area was the entire view).
	   If we don't make the check below _recursiveDisplayAllDirtyXXX  will draw 
	   and this method will then draw another time in the same view/receiver with 
	   with -render:dirtyRect:inView:. 
	   The next line works pretty well... 
	   BOOL needsRedraw = (isVisibleRect && isRectForView && [self needsDisplay] && [self inLiveResize]);
	   ... but we rather use the _wasJustRedrawn flag which is a safer way to 
	   check whether _recursiveDisplayAllDirtyXXX was called by the call to 
	   super at the beginning of this method or not. */
	BOOL needsRedraw = (isVisibleRect && isRectForView && [self needsDisplay] && _wasJustRedrawn == NO);

	if (needsRedraw)
	{
		[self lockFocus];

		/* We always composite the rendering chain on top of each view -drawRect: 
		   drawing sequence (triggered by display-like methods). */
		if ([[self renderer] respondsToSelector: @selector(render:dirtyRect:inView:)])
		{
			[[self renderer] render: nil dirtyRect: aRect inView: self];
		}

		[self unlockFocus];
	}

	_wasJustRedrawn = NO;
}

#endif

#endif /* INTERLEAVED_DRAWING */

@end

@implementation ETScrollView : ETView

- (id) initWithFrame: (NSRect)frame layoutItem: (ETLayoutItem *)item
{
	NSScrollView *realScrollView = [[NSScrollView alloc] initWithFrame: frame];

	self = [self initWithMainView: realScrollView layoutItem: item];
	RELEASE(realScrollView);
	
	return self;
}

/** <init /> */
- (id) initWithMainView: (id)scrollView layoutItem: (ETLayoutItem *)item
{
	self = [super initWithFrame: [scrollView frame] layoutItem: item];
	
	if (self != nil)
	{
		[self setAutoresizingMask: [scrollView autoresizingMask]];
		[scrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

		/* Will be destroy in -[ETView dealloc] */
		ASSIGN(_mainView, scrollView);
		[self addSubview: _mainView];
		[self tile];
	}
	
	return self;	
}

- (void) dealloc
{
	DESTROY(_mainView);
	
	[super dealloc];
}

- (NSView *) mainView
{
	return _mainView;
}

- (NSView *) wrappedView
{
	return [(NSScrollView *)[self mainView] documentView]; 
}

/* Embed the wrapped view inside the receiver scroll view */
- (void) setContentView: (NSView *)view temporary: (BOOL)temporary
{
	NSAssert2([[self mainView] isKindOfClass: [NSScrollView class]], 
		@"_mainView %@ of %@ must be an NSScrollView instance", 
		[self mainView], self);

	if (view != nil)
	{
		[self setAutoresizingMask: [view autoresizingMask]];
	}
	else
	{
		/* Restore autoresizing mask */
		[[(NSScrollView *)[self mainView] documentView] 
			setAutoresizingMask: [self autoresizingMask]];	
	}

	/* Retain the view in case it must be removed from a superview and nobody
	   else retains it */
	RETAIN(view);
	[(NSScrollView *)[self mainView] setDocumentView: view];
	RELEASE(view);
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL)selector
{
	return [[self mainView] methodSignatureForSelector: selector];
}

- (BOOL) respondsToSelector: (SEL)selector
{
	BOOL isInstanceMethod = [super respondsToSelector: selector];
	
	if (isInstanceMethod == NO)
		return [[self mainView] respondsToSelector: selector];
	
	return isInstanceMethod;
}

- (void) forwardInvocation: (NSInvocation *)inv
{
    SEL selector = [inv selector];
	id realScrollView = [self mainView];
 
    if ([realScrollView respondsToSelector: selector])
	{
        [inv invokeWithTarget: realScrollView];
	}
    else
	{
        [self doesNotRecognizeSelector: selector];
	}
}

@end

#if 0
@implementation NSScrollView (EtoileDebug)
- (void) setAutoresizingMask: (unsigned int)mask
{
	ETLog(@"--- Resizing mask from %d to %d %@ %@", [self autoresizingMask], mask, self, [self documentView]);
	[super setAutoresizingMask: mask];
}
@end
#endif
