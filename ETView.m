/* <title>ETView.m</title>
	
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
#import <EtoileUI/GNUstep.h>

#define NC [NSNotificationCenter defaultCenter]

NSString *ETViewTitleBarViewPrototypeDidChangeNotification = @"ETViewTitleBarViewPrototypeDidChangeNotification";

#ifndef GNUSTEP
@interface NSView (CocoaPrivate)
- (void) _recursiveDisplayAllDirtyWithLockFocus: (BOOL)lockFocus visRect: (NSRect)aRect;
@end
#endif

@interface ETView (Private)
- (void) titleBarViewPrototypeDidChange: (NSNotification *)notif;
@end


@implementation ETView

/* Title bar */

static ETView *barViewPrototype = nil;

+ (void) initialize
{
	if ([self class] == [ETView class])
	{
		barViewPrototype = 
			[[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)];
		[barViewPrototype setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	}
}

+ (void) setTitleBarViewPrototype: (NSView *)barView
{
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
		[self setTitleBarView: [ETView titleBarViewPrototype]];
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
	DESTROY(_wrappedView);
	DESTROY(_titleBarView);
	
	[super dealloc];
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

- (BOOL) usesCustomTitleBar
{
	return _usesCustomTitleBar;
}

- (void) titleBarViewPrototypeDidChange: (NSNotification *)notif
{
	[self setTitleBarView: nil];
}

- (void) setTitleBarView: (NSView *)barView
{
	NSRect titleBarFrame = [_titleBarView frame];
	
	[_titleBarView removeFromSuperview];
	
	if (barView != nil)
	{
		ASSIGN(_titleBarView, barView);
		_usesCustomTitleBar = YES;
	}
	else
	{
		ASSIGN(_titleBarView, [[ETView titleBarViewPrototype] copy]);
		RELEASE(_titleBarView);
		_usesCustomTitleBar = NO;
	}
	
	/* Don't sync the height of the new bar view */
	titleBarFrame.size.height = [_titleBarView height];
	[_titleBarView setFrame: titleBarFrame];
	[self addSubview: _titleBarView];
}

- (NSView *) titleBarView
{
	return _titleBarView;
}

- (void) setWrappedView: (NSView *)view
{
	[self setAutoresizesSubviews: YES];
	
	if (view != nil)
	{
		[view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		[self addSubview: view];
		ASSIGN(_wrappedView, view);
	}
	else
	{
		[_wrappedView removeFromSuperview];
		ASSIGN(_wrappedView, nil);
	}
}

- (NSView *) wrappedView
{
	return _wrappedView;
}

/** Sets whether the title bar should be visible or not. 
	When the title bar view is displayed, the receiver becomes disclosable 
	usually by clicking on disclosure indicator. */
- (void) setDisclosable: (BOOL)flag
{
	_disclosable = flag;
	
	if (_disclosable)
	{
		if ([[self titleBarView] superview] == nil)
		{
			[self addSubview: [self titleBarView]];
		}
	}
	else
	{
	
	}
}

/** Returns whether the title bar is visible, thereby disclosable or not. */
- (BOOL) isDisclosable
{
	return _disclosable;
}

/* Actions */

- (void) collapse: (id)sender
{
	if ([self isDisclosable])
	{
		[[self wrappedView] removeFromSuperview];
		[self setFrame: [[self titleBarView] frame]];
	}
}

- (void) expand: (id)sender
{
	NSRect prevFrame = [[self titleBarView] frame];
	
	if ([self isDisclosable] == NO)
		ETLog(@"WARNING: View %@ isn't disclosable, yet it is presently collapsed", self);
	
	prevFrame.size.height += [[self wrappedView] height];
	prevFrame.size.width = [[self wrappedView] width];
	[self setFrame: prevFrame];
	[self addSubview: [self wrappedView]];
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
	return [NSArray arrayWithObjects: @"disclosable"];
}

/* Live Development */

/*- (BOOL) isEditingUI
{
	return _isEditingUI;
}*/

/* Rendering Tree */

- (void) displayIfNeeded
{
	NSLog(@"-displayIfNeeded");
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
