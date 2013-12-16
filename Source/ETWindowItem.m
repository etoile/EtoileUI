 /*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/NSInvocation+Etoile.h>
#import <EtoileFoundation/Macros.h>
#import "ETWindowItem.h"
#import "ETController.h"
#import "ETInstruments.h"
#import "ETEvent.h"
#import "ETGeometry.h"
#import "ETLayer.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "EtoileUIProperties.h"
#import "ETPickDropCoordinator.h"
#import "ETCompatibility.h"
#import "ETView.h"
#import "NSObject+EtoileUI.h"
#import "NSWindow+Etoile.h"

#define NC [NSNotificationCenter defaultCenter]

@implementation ETWindowItem

/* Factory Methods */

/** Returns a new window item to which the given concrete window gets bound. 

The returned item can be used as a decorator to wrap an existing layout item 
into a window. */
+ (ETWindowItem *) itemWithWindow: (NSWindow *)window
               objectGraphContext: (COObjectGraphContext *)aContext
{
	return AUTORELEASE([[self alloc] initWithWindow: window objectGraphContext: aContext]);
}

/** Returns a new window item to which a panel gets bound.

A panel is a utility window with a small titlebar.<br />
For the AppKit, the panel cannot become the main item (the behavior might vary in other backends).

The concrete window class used is [NSPanel]. */
+ (ETWindowItem *) panelItemWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	NSPanel *panel = AUTORELEASE([[NSPanel alloc] init]);
	[panel setStyleMask: [panel styleMask] | NSUtilityWindowMask];
	return [self itemWithWindow: panel objectGraphContext: aContext];
}

/** Returns a new window item to which a fullscreen concrete window gets bound.

The returned item can be used as a decorator to make an existing layout item 
full screen. 

The concrete window class used is [ETFullScreenWindow]. */
+ (ETWindowItem *) fullScreenItemWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	ETWindowItem *window = [self itemWithWindow: AUTORELEASE([[ETFullScreenWindow alloc] init])
	                         objectGraphContext: aContext];
	[window setShouldKeepWindowFrame: YES];
	return window;
}

/** Returns a new window item to which a fullscreen concrete window gets bound.
This window has a transparent background.
 
The returned item can be used as a decorator to make an existing layout item 
full screen. 
 
The concrete window class used is [ETFullScreenWindow]. */
+ (ETWindowItem *) transparentFullScreenItemWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	NSWindow *window = AUTORELEASE([[ETFullScreenWindow alloc] init]);
	[window setOpaque: NO];
	[window setBackgroundColor: [NSColor clearColor]];
	ETWindowItem *windowItem = [self itemWithWindow: window objectGraphContext: aContext];
	[windowItem setShouldKeepWindowFrame: YES];
	return windowItem;
}

/* Initialization */

/** <init />
Initializes and returns a new window decorator with a hard window (provided by 
the widget backend). 

Unless you write a subclass, you should never use this initializer but rather 
the factory methods.

The widget window is inserted in the responder chain between the receiver and 
-[ETLayoutItemFactory windowGroup].

If window is nil, the receiver creates a standard widget backend window. */
- (id) initWithWindow: (NSWindow *)window objectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithSupervisorView: nil objectGraphContext: aContext];
	if (self == nil)
		return nil;

	if (window != nil)
	{
		ASSIGN(_itemWindow, window);
	}
	else
	{
		_itemWindow = [[NSWindow alloc] init];
	}
	// TODO: Would be better not to break the window delegate... May be 
	// we should rather reimplement NSDraggingDestination protocol in 
	// a NSWindow category. 
	if ([_itemWindow delegate] != nil)
	{
		ETLog(@"WARNING: The window delegate %@ will be replaced by %@ "
			"-initWithWindow:", [_itemWindow delegate], self);
	}
	[_itemWindow setDelegate: (id)self];
	[_itemWindow setAcceptsMouseMovedEvents: YES];
	[_itemWindow registerForDraggedTypes: A(ETLayoutItemPboardType)];
	_usesCustomWindowTitle = ([self isUntitled] == NO);
	_shouldKeepWindowFrame = NO;
	
	ETDebugLog(@"Init item %@ with window %@ %@ at %@", self, [_itemWindow title],
		_itemWindow, NSStringFromRect([_itemWindow frame]));
	
	return self;
}

- (id) initWithSupervisorView: (ETView *)aView objectGraphContext: (COObjectGraphContext *)aContext
{
	return [self initWithWindow: nil objectGraphContext: aContext];
}

- (void) dealloc
{
	ETDebugLog(@"Dealloc item %@ with window %@ %@ at %@", self, [_itemWindow title],
		_itemWindow, NSStringFromRect([_itemWindow frame]));

	[self removeActiveFieldEditorItem]; /* For _editedItem and _activeFieldEditorItem */

	[_itemWindow unbind: NSTitleBinding];
	/* Retain the window to be sure we can send it -isReleasedWhenClosed. We 
	   must defer the deallocation in case -close releases it and drops the
	   retain count to zero. */
	RETAIN(_itemWindow);
	[_itemWindow close];
	/* Don't release a window which is in charge of releasing itself.
	   We are usually in the middle of a window close handling and -dealloc has
	   been called as a side-effect of removing the decorated item from the 
	   window layer in -windowWillClose: notification. */
	if ([_itemWindow isReleasedWhenClosed] == NO)
	{
		RELEASE(_itemWindow);
	}
	DESTROY(_itemWindow);  /* Balance first retain call */
	DESTROY(_oldFocusedItem);

	[super dealloc];
}

- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone
{
	NSWindow *windowCopy = [_itemWindow copyWithZone: aZone];
	NSInvocation *inv = [NSInvocation invocationWithTarget: self
	                                              selector: @selector(initWithWindow:)
                                                 arguments: A(windowCopy)];
	RELEASE(windowCopy); // NOTE: We don't autorelease to simplify debugging.
	return inv;
}

- (id) copyWithCopier: (ETCopier *)aCopier
{
	ETWindowItem *newItem = [super copyWithCopier: aCopier];

	if ([aCopier isAliasedCopy])
		return newItem;

	// NOTE: The copying logic is largely handled with -initWithInvocationForCopyWithZone:

	newItem->_shouldKeepWindowFrame = _shouldKeepWindowFrame;
	newItem->_flipped = _flipped; // Probably not necessary

	return newItem;
}

/* Main Accessors */

- (BOOL) isPanel
{
	return [_itemWindow isKindOfClass: [NSPanel class]];
}

/** Returns YES when the receiver window has no title, otherwise returns NO. */
- (BOOL) isUntitled
{
	NSString *title = [[self window] title];
	return (title == nil || [title isEqual: @""] || [title isEqual: @"Window"]);
}

/* -windowWillClose: ins't appropriate because it would be called when the window 
   is sent -close on window item release/deallocation (see -dealloc). */
- (BOOL) windowShouldClose: (NSNotification *)notif
{
	ETDebugLog(@"Shoud close %@ with window %@ %@ at %@", self, [_itemWindow title],
		_itemWindow, NSStringFromRect([_itemWindow frame]));

	/* If the window doesn' t get hidden on close, we release the item 
	   we decorate by removing it from the window layer or removing ourself 
	   as a decorator. */
	if ([_itemWindow isReleasedWhenClosed])
	{
		ETLayoutItemGroup *windowGroup = [[ETLayoutItemFactory factory] windowGroup];

		if ([windowGroup containsItem: [self firstDecoratedItem]])
		{
			[windowGroup removeItem: [self firstDecoratedItem]];
		}
		else
		{
			[[self decoratedItem] setDecoratorItem: nil];
		}
	}

	return YES;
}

/** Returns the underlying hard window. */
- (NSWindow *) window
{
	return _itemWindow;
}

/** Returns YES when you have provided a custom window title, otherwise 
when returns NO when the receiver manages the window title. */
- (BOOL) usesCustomWindowTitle
{
	return _usesCustomWindowTitle;
}

/** Returns the height of the window title bar or zero when no title bar is used. */
- (CGFloat) titleBarHeight
{
	return [self decorationRect].size.height - [self contentRect].size.height;
}

/* Overriden Methods */

/** Returns YES when item can be decorated with a window by the receiver, 
otherwise returns no. */
- (BOOL) canDecorateItem: (id)item
{
	/* Will call back -[item acceptsDecoratorItem: self] */
	BOOL canDecorate = [super canDecorateItem: item];
	
	/*if (canDecorate && [item decoratorItem] != nil)
	{
		ETLog(@"To be decorated with a window, item %@ must have no existing "
			@"decorator item %@", item, [item decoratorItem]);
		canDecorate = NO;
	}*/
	if (canDecorate && [item isKindOfClass: [ETWindowItem class]])
	{
		ETLog(@"To be decorated with a window, item %@ must not be a window "
			@"item %@", item, [item decoratorItem]);
		canDecorate = NO;
	}

	return canDecorate;
}

/** Returns NO. A window can never be decorated. */
- (BOOL) acceptsDecoratorItem: (ETDecoratorItem *)item
{
	return NO;
}

/** Returns whether the window should keep its size when used as a 
decorator, rather than getting resized to match the decorated item size. */
- (BOOL) shouldKeepWindowFrame
{
	return _shouldKeepWindowFrame;
}

/** Sets whether the window should keep its size when used as a decorator.

This is needed for fullscreen windows, so that they fill the screen
regardless of the size of the item they decorate. */
- (void) setShouldKeepWindowFrame: (BOOL)shouldKeepWindowFrame
{
	_shouldKeepWindowFrame = shouldKeepWindowFrame;
}

/** This method is only exposed to be used internally by EtoileUI. 

Converts the given rect expressed in the EtoileUI window layer coordinate space 
to the AppKit screen coordinate space.

This method will check whether the window layer (aka window group) is flipped 
and make the necessary adjustments. */
+ (NSRect) convertRectToWidgetBackendScreenBase: (NSRect)rect
{
	ETWindowLayer *windowLayer = (ETWindowLayer *)[[ETLayoutItemFactory factory] windowGroup];
	/* We call -rootWindowFrame on ETWindowLayer and not -frame which would 
	   call back the current method and results in an endless recursion.
	   -rootWindowFrame is expressed in screen base coordinates. */
	NSRect windowLayerFrame = [windowLayer rootWindowFrame];
	CGFloat y = rect.origin.y;
	
	if ([windowLayer isFlipped])
	{
		y = windowLayerFrame.size.height - (rect.origin.y + rect.size.height);
	}

	y += windowLayerFrame.origin.y;

	return NSMakeRect(rect.origin.x, y, rect.size.width, rect.size.height);	
}

/** This method is only exposed to be used internally by EtoileUI.

Converts the given rect expressed in the AppKit screen coordinate space to the 
EtoileUI window layer coordinate space.

This method will check whether the window layer (aka window group) is flipped 
and make the necessary adjustments. */
+ (NSRect) convertRectFromWidgetBackendScreenBase: (NSRect)windowFrame
{
	ETWindowLayer *windowLayer = (ETWindowLayer *)[[ETLayoutItemFactory factory] windowGroup];
	/* We call -rootWindowFrame on ETWindowLayer and not -frame which would 
	   call back the current method and results in an endless recursion.
	   -rootWindowFrame is expressed in screen base coordinates. */
	NSRect windowLayerFrame = [windowLayer rootWindowFrame];
	CGFloat y = windowFrame.origin.y;
	
	y -= windowLayerFrame.origin.y;

	if ([windowLayer isFlipped])
	{
		y = windowLayerFrame.size.height - (y + windowFrame.size.height);
	}

	return NSMakeRect(windowFrame.origin.x, y, windowFrame.size.width, windowFrame.size.height);
}

- (void) updateWindowFrameForDecoratedView: (ETView *)decoratedView
{
	if (decoratedView == nil)
		return;

	// FIXME: Restore the position correctly, we could use...
	//[_itemWindow setContentSizeFromTopLeft: [decoratedView frame].size];
		
	if ([self shouldKeepWindowFrame] == NO)
	{
		[_itemWindow setFrame: [_itemWindow frameRectForContentRect: [decoratedView frame]] display: YES];
		//[_itemWindow setFrame: [[self class] convertRectToWidgetBackendScreenBase: [decoratedView frame]]
		//              display: YES];
	}
	
	//NSSize shrinkedItemSize = [_itemWindow contentRectForFrameRect: [_itemWindow frame]].size;
	//[decoratedView setFrameSize: shrinkedItemSize];
	/* Previous line similar to [decoratedItem setContentSize: shrinkedItemSize] */
}

- (void) didUndecorateItem: (ETUIItem *)item
{
	BOOL usesTitleBinding = ([_itemWindow infoForBinding: NSTitleBinding] != nil);

	[_itemWindow orderOut: self];
	[_itemWindow unbind: NSTitleBinding];
	if (usesTitleBinding)
	{
		[_itemWindow setTitle: @""];
	}
	[self removeActiveFieldEditorItem];
	DESTROY(_oldFocusedItem);
}

- (void) didDecorateItem: (ETUIItem *)item
{
	// TODO: Write a test to ensure the binding is updated when intermediate
	// decorators are bound to a new decorated item.
	if ([self usesCustomWindowTitle] == NO && [[item firstDecoratedItem] isLayoutItem])
	{
		[_itemWindow bind: NSTitleBinding
		         toObject: [item firstDecoratedItem]
		      withKeyPath: kETDisplayNameProperty
		          options: nil];
	}

	/* For a panel item, don't make it key (prevent losing the focus in a document when an inspector is shown)  */
	if ([self isPanel])
	{
		[_itemWindow orderFront: self];
	}
	else
	{
		[_itemWindow makeKeyAndOrderFront: self];
	}
	// NOTE: For a non-active application, -isMainWindow always returns NO.
	ETAssert([NSApp isActive] == NO || [_itemWindow canBecomeMainWindow] == NO || [_itemWindow isMainWindow]);
	
	[self postSelectionChangeNotificationInWindowGroup];
}

- (void) handleDecorateItem: (ETUIItem *)item 
             supervisorView: (ETView *)decoratedView 
                     inView: (ETView *)parentView 
{
	/* -handleDecorateItem:inView: will call back 
	   -[ETWindowItem setDecoratedView:] which overrides ETLayoutItem.
	   We pass nil instead of parentView because we want to move the decorated
	   item view into the window and not reinsert it once decorated into its
	   superview. Reinserting into the existing superview is the usual behavior 
	   implemented by -handleDecorateItem:inView: that works well when the 
	   decorator is a view  (box, scroll view etc.). */
	[super handleDecorateItem: item supervisorView: nil inView: nil];
		
	[self updateWindowFrameForDecoratedView: decoratedView];
	[_itemWindow setContentView: (NSView *)decoratedView];	

	// FIXME: Figure out if we really need the line below (it breaks notifications for -testActiveItemChanged)
	//if (parentView == nil)
	//	return;
}

- (void) handleUndecorateItem: (ETUIItem *)item
               supervisorView: (ETView *)decoratedView 
                       inView: (ETView *)parentView
{
	/* For calling -restoreAutoresizingMaskOfDecoratedItem: */
	[super handleUndecorateItem: item supervisorView: nil inView: nil];

	[_itemWindow setContentView: nil];
}

- (void) saveAndOverrideAutoresizingMaskOfDecoratedItem: (ETUIItem *)item
{
	_oldDecoratedItemAutoresizingMask = [[item supervisorView] autoresizingMask];
	[[item supervisorView] setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
}

- (void) restoreAutoresizingMaskOfDecoratedItem: (ETUIItem *)item
{
	[[item supervisorView] setAutoresizingMask: _oldDecoratedItemAutoresizingMask];
}

/** Returns nil. */
- (ETView *) supervisorView
{
	ETAssert([super supervisorView] == nil);
	return nil;
}

/** Returns the window content view. */
- (NSView *) view
{
	return [_itemWindow contentView];
}

/** Returns the window frame in the window layer coordinate base which is 
flipped by default.

See also -[ETItemFactory windowGroup]. */
- (NSRect) decorationRect
{
	return [[self class] convertRectFromWidgetBackendScreenBase: [_itemWindow frame]];
}

/** Returns the content view bounds. */
- (NSRect) visibleRect
{
	return [[_itemWindow contentView] bounds];
}

/** Returns the content view rect expressed in the window coordinate space. 

This coordinate space includes the window decoration (titlebar etc.).  */
- (NSRect) contentRect
{
	NSRect windowFrame = [_itemWindow frame];
	NSRect rect = [_itemWindow contentRectForFrameRect: windowFrame];

	NSParameterAssert(rect.size.width <= windowFrame.size.width 
		&& rect.size.height <= windowFrame.size.height);

	rect.origin.x = rect.origin.x - windowFrame.origin.x;
	rect.origin.y = rect.origin.y - windowFrame.origin.y;

	if ([self isFlipped])
	{
		rect.origin.y = windowFrame.size.height - (rect.origin.y + rect.size.height);	
	}

	NSParameterAssert(rect.origin.x >= 0 && rect.origin.y >= 0);

	return rect;
	// TODO: Use [_itemWindow contentRectInFrame];
}

// NOTE: At this point, we lost the item position (aka the implicit frame 
// origin of the first decorated item). That means the item will have a "random" 
// position when the window decorator is removed.
- (void) handleSetDecorationRect: (NSRect)rect
{
	 /* Will be called back when the window is resized, but -setFrame:display: 
	    will do nothing then. In this case, the call stack looks like:
		-[ETDecoratorItem handleSetDecorationRect:]
		-[ETDecorator decoratedItemRectChanged:]
		-[ETLayoutItem setContentBounds:]
		... 
		-[ETView setFrame:] -- the window content view
		-[NSWindow setFrame:display:]
		
		 What is explained above holds when there is no NSToolbar in use, 
		 otherwise -decorationSizeForContentSize: computes the size wrongly 
		 because the NSWindow state is not consistent, so we check -inLiveResize
		 to return immediately when:
		 - the user is resizing the window
		 - the resize is animated (see -setFrame:display:animate:) */

	if ([_itemWindow inLiveResize] || [self shouldKeepWindowFrame])
		return;

	[_itemWindow setFrame: [[self class] convertRectToWidgetBackendScreenBase: rect] 
	              display: YES];
}

- (NSRect) frameForDecoratedItemFrame: (NSRect)aFrame
{
	ETAssert([self decoratedItem] != nil);
	return [_itemWindow frameRectForContentRect: aFrame];
}

- (NSRect) frameForUndecoratedItemFrame: (NSRect)aFrame
{
	ETAssert([self decoratedItem] != nil);
	return [_itemWindow contentRectForFrameRect: aFrame];
}

- (BOOL) isFlipped
{
	return _flipped;
}

- (void) setFlipped: (BOOL)flipped
{
	_flipped = flipped;
	[_decoratorItem setFlipped: flipped];	
}

/* First Responder Sharing Area */

- (void) prepareInitialFocusedItem
{
	ETAssert([ETTool activeTool] != nil);
	
	ETUIItem *item = [self firstDecoratedItem];

	if ([item isLayoutItem] == NO && [item isGroup] == NO)
		return;

	ETLayoutItem *initialFocusedItem =
		[[(ETLayoutItemGroup *)item controller] initialFocusedItem];
	BOOL usesDefaultInitialFocusedItem = (initialFocusedItem == nil);

	if (usesDefaultInitialFocusedItem)
	{
		initialFocusedItem = (ETLayoutItem *)item;
	}

	ETLog(@"Prepare initial focused item %@", initialFocusedItem);

	[[ETTool activeTool] makeFirstResponder: (id)initialFocusedItem];
	// FIXME: ETAssert([self focusedItem] == initialFocusedItem);
}

- (ETLayoutItem *) windowBackedItemBoundToActiveTool
{
	ETLayoutItem *targetItem = [[ETTool activeTool] targetItem];
	ETLayoutItem *windowBackedItemBoundToActiveTool = [targetItem windowBackedAncestorItem];
	BOOL isWindowGroupTargeted =
		([targetItem isEqual: [[ETLayoutItemFactory factory] windowGroup]]);

	ETAssert(windowBackedItemBoundToActiveTool != nil || isWindowGroupTargeted
		|| [[ETTool activeTool] isEqual: [ETTool mainTool]]);
		
	return windowBackedItemBoundToActiveTool;
}

/** When a window becomes key, we look up and activate a tool in the new key 
window (this is done either by the event processor or this method).

When it is due to a user click, the event processor does update the active tool 
just before processing the mouse down (this updates the key window, and 
-windowDidBecomeKey: can be called).

When the window becomes key through another action than a click (e.g. a menu 
action or at lauch), no mouse down event occurs, so we must update the active 
tool here.
 
For an utility window (e.g. an inspector or picker), the panel can appear 
frontmost and yet the main window tool can still be the active tool (a panel 
doesn't become key unless the user clicks the titlebar or an editable widget). */
- (void) windowDidBecomeKey: (NSNotification *)notification
{
	BOOL isWindowVisibleForFirstTime = (_oldFocusedItem == nil);

	NSLog(@"Old focused Item %@", _oldFocusedItem);

	if (isWindowVisibleForFirstTime)
	{
		/* -[NSWindow becomeKeyWindow] has just set up its initial first responder,
	       we override it */
		[self prepareInitialFocusedItem];
	}

	// TODO: Move the tool activation into -[ETTool makeFirstResponder:inWindow:]
	if ([[[self windowBackedItemBoundToActiveTool] windowItem] isEqual: self])
		return;

	[ETTool setActiveTool: [ETTool activatableToolForItem: [self focusedItem]]];
}

- (void) postSelectionChangeNotificationInWindowGroup
{
	BOOL isDecorationUnderway = ([[self firstDecoratedItem] isLayoutItem] == NO);

	/* When the main window status is resigned, we post nothing, we just let the new main window 
	   posts the ETItemGroupSelectionDidChangeNotification */
	if (isDecorationUnderway || [_itemWindow isMainWindow] == NO)
		return;

	ETLayoutItemGroup *windowGroup = [(ETLayoutItem *)[self firstDecoratedItem] parentItem];

	/* Tell the window group to post a ETItemGroupSelectionDidChangeNotification */
	[windowGroup setSelectionIndex: [windowGroup indexOfItem: [self firstDecoratedItem]]];
}

- (void) windowDidBecomeMain: (NSNotification *)notification
{
	[self postSelectionChangeNotificationInWindowGroup];
}

- (ETLayoutItem *) focusedItem
{
	// NOTE: NSResponder conforms to ETResponder (see ETResponder.m)
	return [[_itemWindow firstResponder] candidateFocusedItem];
}

- (void) postFocusedItemChangeNotificationIfNeeded
{
	BOOL isUnused = ([[self firstDecoratedItem] isLayoutItem] == NO);

	if (isUnused)
	{
		ETAssert(_oldFocusedItem == nil);
		return;
	}

	ETLayoutItem *newFocusedItem = [self focusedItem];

	if (_oldFocusedItem == newFocusedItem)
		return;

	/* For a field editor, the delegate is the edited text view, so we retrieve 
	   the focused item using -[NSText focusedItem] on this delegate. */
	[[_oldFocusedItem editionCoordinator] didResignFocusedItem: _oldFocusedItem];
	[[newFocusedItem editionCoordinator] didBecomeFocusedItem: newFocusedItem];

	ETDebugLog(@"Changing focused item from %@ to %@", _oldFocusedItem, newFocusedItem);

	ASSIGN(_oldFocusedItem, newFocusedItem);

	ETAssert(_oldFocusedItem != nil);
}

/** Returns the item owning the field editor which has the first responder 
status, or nil when no text editing is underway in the window. */
- (ETLayoutItem *) activeFieldEditorItem
{
	return _activeFieldEditorItem;
}

/** Returns the item on which the text editing was initiated. */
- (ETLayoutItem *) editedItem
{
	return _editedItem;
}

/** Inserts the editor item which provides text editing in the window and makes 
it the first responder.

Any existing active field editor item is removed first.

An NSInvalidArgumentException is raised when any given item is nil. */
- (void) setActiveFieldEditorItem: (ETLayoutItem *)editorItem
                       editedItem: (ETLayoutItem *)editedItem
{
	NILARG_EXCEPTION_TEST(editedItem);
	[self removeActiveFieldEditorItem];

	ASSIGN(_activeFieldEditorItem, editorItem);
	ASSIGN(_editedItem, editedItem);

	if (editorItem == nil)
		return;

	/* We must be sure the field editor won't be repositionned by its parent 
	   item layout, that's why we don't use -addItem: (or -insertItem:atIndex:) 
	   but -addSubview:.
	   In -hitTestWithEvent:, we start with -hitTestFieldEditorWithEvent: then 
	   only we try a hit test in the item tree. When a field editor is in use, 
	   we can be sure it is returned by the hit test. 
	   -hitTestFieldEditorWithEvent: and -addSubview: ensures we don't depend 
	   on the item hit test order. Take note that -subviews are back-to-front
	   and -items are front-to-back.
	   -trySendEventToWidgetView: delivers the events to the field editor view. */
	[[[self window] contentView] addSubview: [editorItem supervisorView]];
	[editorItem setParentItem: [self firstDecoratedItem]];

	/* Start to delegate text editing events to the text view with a basic tool.
	   We have no dedicated tool and it is not very important because we 
	   handle the raw events with a text widget provided by the widget backend. */
	[ETTool setActiveTool: [ETTool tool]];
	[[ETTool activeTool] makeFirstResponder: [editorItem view]];
}

/** Removes the item which provides text editing in the window.

Does nothing when there is no active field editor item in the window. */
- (void) removeActiveFieldEditorItem
{
	DESTROY(_editedItem);

	if (nil == _activeFieldEditorItem)
		return;

	ETLayoutItemGroup *contentItem = [_activeFieldEditorItem parentItem];
	NSRect editorFrame = [_activeFieldEditorItem frame];

	ETAssert(nil != contentItem);

	[[_activeFieldEditorItem supervisorView] removeFromSuperview];
	DESTROY(_activeFieldEditorItem);

	/* Redraws recursively the item tree portion which was covered by the editor */
	[contentItem setNeedsDisplayInRect: editorFrame];
}

/** Returns the active field editor item if there is one located where the 
event occured, otherwise returns nil. */
- (ETLayoutItem *) hitTestFieldEditorWithEvent: (ETEvent *)anEvent
{
	NSParameterAssert([[anEvent windowItem] isEqual: self]);

	if (nil == _activeFieldEditorItem)
		return nil;

	NSEvent *backendEvent = (NSEvent *)[anEvent backendEvent];
	NSPoint pointInContentView = [[[self window] contentView] 
		convertPoint: [backendEvent locationInWindow] fromView: nil];
	
	if (nil == [[_activeFieldEditorItem supervisorView] hitTest: pointInContentView])
	{
		return nil;
	}

	ETLayoutItem *contentItem = [self firstDecoratedItem];
	NSRect rectInContentItem = ETMakeRect([anEvent locationInWindowContentItem], NSZeroSize);
	NSPoint pointInEditorItem = [_activeFieldEditorItem convertRect: rectInContentItem
	                                                       fromItem: (id)contentItem].origin;

	[anEvent setLayoutItem: _activeFieldEditorItem];
	[anEvent setLocationInLayoutItem: pointInEditorItem];

	return _activeFieldEditorItem;
}

/* Actions */

/** Forwards the action to the underlying window object. */
- (IBAction) performClose:(id)sender
{
	[_itemWindow performClose: sender];
}

/** Forwards the action to the underlying window object. */
- (IBAction) performMiniaturize:(id)sender
{
	[_itemWindow performMiniaturize: sender];
}

/** Forwards the action to the underlying window object. */
- (IBAction) performZoom:(id)sender
{
	[_itemWindow performZoom: sender];
}

/* Dragging Destination (as Window delegate) */

/* This method can be called on the receiver when a drag exits. */
- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Drag enter receives in dragging destination %@", self);
	return [[ETPickDropCoordinator sharedInstance] draggingEntered: drag];
}

- (NSDragOperation) draggingUpdated: (id <NSDraggingInfo>)drag
{
	//ETLog(@"Drag update receives in dragging destination %@", self);
	return [[ETPickDropCoordinator sharedInstance] draggingUpdated: drag];
}

- (void) draggingExited: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Drag exit receives in dragging destination %@", self);
	[[ETPickDropCoordinator sharedInstance] draggingExited: drag];
}

- (void) draggingEnded: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Drag end receives in dragging destination %@", self);
	[[ETPickDropCoordinator sharedInstance] draggingEnded: drag];
}

/* Will be called when -draggingEntered and -draggingUpdated have validated the drag
   This method is equivalent to -validateDropXXX data source method.  */
- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Prepare drag receives in dragging destination %@", self);
	return [[ETPickDropCoordinator sharedInstance] prepareForDragOperation: drag];	
}

/* Will be called when -draggingEntered and -draggingUpdated have validated the drag
   This method is equivalent to -acceptDropXXX data source method.  */
- (BOOL) performDragOperation: (id <NSDraggingInfo>)dragInfo
{
	ETDebugLog(@"Perform drag receives in dragging destination %@", self);
	return [[ETPickDropCoordinator sharedInstance] performDragOperation: dragInfo];
}

/* This method is called in replacement of -draggingEnded: when a drop has 
   occured. That's why it's not enough to clean insertion indicator in
   -draggingEnded:. Both methods called -handleDragEnd:forItem: on the 
   drop target item. */
- (void) concludeDragOperation: (id <NSDraggingInfo>)dragInfo
{
	ETDebugLog(@"Conclude drag receives in dragging destination %@", self);
	[[ETPickDropCoordinator sharedInstance] concludeDragOperation: dragInfo];
}

@end
