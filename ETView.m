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

#import <EtoileUI/ETView.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCompatibility.h>

#define NC [NSNotificationCenter defaultCenter]

NSString *ETViewTitleBarViewPrototypeDidChangeNotification = @"ETViewTitleBarViewPrototypeDidChangeNotification";

#ifndef GNUSTEP
@interface NSView (CocoaPrivate)
- (void) _recursiveDisplayAllDirtyWithLockFocus: (BOOL)lockFocus visRect: (NSRect)aRect;
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
		if (item != nil)
		{
			[self setLayoutItem: item];
		}
		else
		{
			_layoutItem = [[ETLayoutItem alloc] initWithView: self];
		}
		[self setRenderer: nil];
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

- (void) dealloc
{
	[NC removeObserver: self];

	DESTROY(_layoutItem);
	DESTROY(_renderer);
	DESTROY(_temporaryView);
	DESTROY(_wrappedView);
	DESTROY(_titleBarView);
	
	[super dealloc];
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
- (ETLayoutItem *) layoutItem
{
	NSAssert1(_layoutItem != nil, @"Layout item of %@ must never be nil", self);
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
	ASSIGN(_layoutItem, item);
}

- (void) setRenderer: (id)renderer
{
	ASSIGN(_renderer, renderer);
}

- (id) renderer
{
	return _renderer;
}

- (void) drawRect: (NSRect)rect
{
	[super drawRect: rect];

	/* Now we must draw layout items without view... using either a cell or 
	   their own renderer. Layout item are smart enough to avoid drawing their
	   view when they have one. */
	// FIXME: Turned off this invocation of the rendering chain to avoid drawing
	// selection out of bounds because the selected view doesn't receive 
	// -lockFocus
	//if ([[self renderer] respondsToSelector: @selector(render:)])
		//[[self renderer] render: nil];
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

- (void) displayIfNeeded
{
	//NSLog(@"-displayIfNeeded");
	[super displayIfNeeded];
}

- (void) displayIfNeededInRect:(NSRect)aRect
{
	NSLog(@"-displayIfNeededInRect:");
	[super displayIfNeededInRect: aRect];
}

- (void) displayIfNeededInRectIgnoringOpacity:(NSRect)aRect
{
	NSLog(@"-displayIfNeededInRectIgnoringOpacity:");
	[super displayIfNeededInRectIgnoringOpacity: aRect];
}

- (void) display
{	
	NSLog(@"-display");
	[super display];
}

- (void) displayRect:(NSRect)aRect
{
	NSLog(@"-displayRect:");
	[super displayRect: aRect];
}

- (void) displayRectIgnoringOpacity:(NSRect)aRect
{
	NSLog(@"-displayRectIgnoringOpacity:");
	[super displayRectIgnoringOpacity: aRect];
}

#ifdef GNUSTEP
- (void) displayRectIgnoringOpacity: (NSRect)aRect 
                          inContext: (NSGraphicsContext *)context
{
	NSLog(@"-displayRectIgnoringOpacity:inContext:");
	[super displayRectIgnoringOpacity: aRect inContext: context];

	/* We always composite the rendering chain on top of each view -drawRect: 
	   drawing sequence. */
	if ([[self renderer] respondsToSelector: @selector(render:)])
		[[self renderer] render: nil];
}

#else

// FIXME: This isn't really safe because Cocoa may use other specialized 
// methods to update the display. They are named _recursiveDisplayXXX.
// NOTE: Very often NSView instance which has been sent a display message will 
// call this method on its subviews. These subviews will do the same with their own 
// subviews. Here is the other method often used in the same way:
//_recursiveDisplayRectIfNeededIgnoringOpacity:isVisibleRect:rectIsVisibleRectForView:topView:
// The previous method usually follows the message on next line:
//_displayRectIgnoringOpacity:isVisibleRect:rectIsVisibleRectForView:
- (void) _recursiveDisplayAllDirtyWithLockFocus: (BOOL)lockFocus visRect: (NSRect)aRect
{
	//NSLog(@"-_recursiveDisplayAllDirtyWithLockFocus:visRect:");
	[super _recursiveDisplayAllDirtyWithLockFocus: lockFocus visRect: aRect];
	
	/* We always composite the rendering chain on top of each view -drawRect: 
	   drawing sequence (triggered by display-like methods). */
	if ([[self renderer] respondsToSelector: @selector(render:)])
		[[self renderer] render: nil];
}
#endif

@end

@implementation ETScrollView : ETView

- (NSView *) wrappedView
{
	return [(NSScrollView *)_wrappedView documentView]; 
}

- (void) setWrappedView: (NSView *)view
{
	NSAssert2([_wrappedView isKindOfClass: [NSScrollView class]], 
		@"_wrappedView %@ of %@ must be an NSScrollView instance", 
		_wrappedView, self);

	/* Retain the view in case it must be removed from a superview and nobody
	   else retains it */
	RETAIN(view);

	/* Ensure the view has no superview set */
	if ([view superview] != nil)
	{
		ETLog(@"WARNING: New wrapped view %@ of %@ should have no superview",
			view, self);
		[view removeFromSuperview];
	}
	
	/* Embed the wrapped view inside the receiver scroll view */
	[(NSScrollView *)_wrappedView setDocumentView: view];
	
	RELEASE(view);
}

@end
