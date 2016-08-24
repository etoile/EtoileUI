/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  February 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import "ETEventProcessor.h"
#import "ETDecoratorItem.h"
#import "ETGeometry.h"
#import "ETTool.h"
#import "ETEvent.h"
#import "ETLayoutItem.h"
#import "ETLayoutExecutor.h"
#import "ETApplication.h"
#import "ETView.h"
#import "ETWindowItem.h"
#import "ETWidgetBackend.h"
#import "ETCompatibility.h"

@implementation ETEventProcessor

static ETEventProcessor *sharedInstance = nil;

/** Returns the event processor that corresponds to the widget backend currently 
in use. */
+ (instancetype) sharedInstance
{
	if (sharedInstance == nil)
	{
		// TODO: Rework to look up the class to instantiate based on the 
		// linked/configured widged backend.
		sharedInstance = [[ETAppKitEventProcessor alloc] init];
	}

	return sharedInstance; 
}

/** <override-subclass />
Implements in concrete subclasses to turn each raw event emitted by the run
loop of the widget backend into an EtoileUI-native event, then invoke the 
related event method on the active tool with the new ETEvent object in 
parameter.

The implementation is expected to return YES if anEvent should be dispatched by 
the widget backend itself, otherwise NO if only EtoileUI should be in charge of 
displatching the event.

The implementation must also call -runUpdatePhases just before returning. */
- (BOOL) processEvent: (void *)backendEvent
{
	return NO;
}

/** <override-never />
Tells the receiver to run the update phases: 

<list>
<item>Item Validation (tell controllers to enable and disable items)</item>
<item>Layout Update</item>
<item>Display Update (not yet the case)</item>
</list>

A ETEventProcessorDidProcessEventNotification is posted just before the update 
phases.

See -processEvent:. */
- (void) runUpdatePhases
{
	[[NSNotificationCenter defaultCenter]
		postNotificationName: ETEventProcessorDidProcessEventNotification object: self];

	if ([ETLayoutItem isAutolayoutEnabled])
	{
		[[ETLayoutExecutor sharedInstance] execute];
	}
}

/** <override-subclass />
Implements in concrete subclasses to tell whether the current processed
event marks the beginning of an event sequence between a mouse down and mouse up 
events for an item that sends continuous actions during such a sequence. */
- (BOOL) beginContinuousActionsForItem: (ETLayoutItem *)anItem
{
	return NO;
}

/** <override-subclass />
Implements in concrete subclasses to tell whether the current processed
event marks the end of an event sequence between a mouse down and mouse up 
events for an item that sends continuous actions during such a sequence. */
- (BOOL) endContinuousActionsForItem: (ETLayoutItem *)anItem
{
	return NO;
}

- (BOOL) tryActivateItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent
{
	return NO;
}

/** Implements in concrete subclasses to have backend widgets handle events 
directly as they would do when used outside of EtoileUI.

The implementation is expected to return YES if anEvent was properly dispatched 
and handled by a widget view associated with item, and NO otherwise. */
- (BOOL) trySendEvent: (ETEvent *)anEvent toWidgetViewOfItem: (ETLayoutItem *)item
{
	return NO;
}

- (id) delegate
{
	return _delegate;
}

- (void) setDelegate: (id)aDelegate
{
	_delegate = aDelegate;
}

@end

NSString * const ETEventProcessorDidProcessEventNotification =
	@"ETEventProcessorDidProcessEventNotification";

@interface NSWindow (GNUstepCocoaPrivate)
// NOTE: This method is implemented on NSWindow, although the public API 
// only exposes it at NSPanel level.
- (BOOL) becomesKeyOnlyIfNeeded;
@end


@implementation ETAppKitEventProcessor

/** Processes AppKit NSEvent objects handed by -[NSApplication sendEvent:].

Returns YES when the event has been handled by EtoileUI, otherwise returns NO 
when the event has to be handled by the widget backend. */
- (BOOL) processEvent: (void *)theEvent
{
	ETEvent *nativeEvent = ETEVENT((__bridge NSEvent *)theEvent, nil, ETNonePickingMask);
	BOOL isHandled = NO;

	switch ([(__bridge NSEvent *)theEvent type])
	{
		case NSMouseMoved:
		case NSLeftMouseDown:
		case NSLeftMouseUp:
		case NSLeftMouseDragged:
			isHandled = [self processMouseEvent: nativeEvent];
			break;
		case NSKeyDown:
		case NSKeyUp:
		case NSFlagsChanged:
			isHandled = [self processKeyEvent: nativeEvent];
			break;
		// FIXME: Handle more event types...
		default:
			break;
	}

	[self runUpdatePhases];

	return isHandled;
}

- (BOOL) processKeyEvent: (ETEvent *)anEvent
{
	ETTool *activeTool = [ETTool activeTool];
	
	switch ([anEvent type])
	{
		case NSKeyDown:
			[activeTool keyDown: anEvent];
			break;
		case NSKeyUp:
			[activeTool keyUp: anEvent];
			break;
		case NSFlagsChanged:
			ETDebugLog(@"Modifiers changed to %d", [anEvent modifierFlags]);
			return NO;
		default:
			return NO;
	}

	return YES;
}

- (BOOL) beginContinuousActionsForItem: (ETLayoutItem *)anItem
{
	if ([[[anItem view] ifResponds] isContinuous] == NO)
		return NO;

	BOOL isAtBeginning = (_isProcessingContinuousActionEvents == NO && _wasMouseDownProcessed);

	if (isAtBeginning)
	{
		_isProcessingContinuousActionEvents = YES;
	}
	return isAtBeginning;
}

- (BOOL) endContinuousActionsForItem: (ETLayoutItem *)anItem
{
	if ([[[anItem view] ifResponds] isContinuous] == NO)
		return NO;

	BOOL isAtEnd =
		(_isProcessingContinuousActionEvents && [[NSApp currentEvent] type] == NSLeftMouseUp);

	if (isAtEnd)
	{
		_isProcessingContinuousActionEvents = NO;
	}
	return isAtEnd;
}

- (BOOL) isMovingOrResizingWindow
{
	return (_wasMouseDownProcessed == NO);
}

/** Tests whether the event is located within the window content or rather on 
the window border/titlebar. In the latter case, the event is not pushed to the 
active instrumend and NO is returned.

Returns YES when the event has been handled by EtoileUI. */
- (BOOL) processMouseEvent: (ETEvent *)anEvent
{
	//ETLog(@"Process mouse event %@", anEvent);

	if ([anEvent isWindowDecorationEvent] || [anEvent contentItem] == nil)
	{
		ETDebugLog(@"Will push back event to widget backend %@", anEvent);
		return NO;
	}

	ETTool *initialActiveTool = [ETTool activeTool];
	ETTool *activeTool = initialActiveTool;
	/* The window item must be retained to prevent crashes if the first 
	   decorated item is removed from the item tree or moved to another part.
	   For example, see -stopEditingKeyWindowUI:. */
	ETWindowItem *windowItem = [anEvent windowItem];
	ETAssert([windowItem enclosingItem] != nil);
	BOOL hadActiveFieldEditorItem = (nil != windowItem && nil != [windowItem activeFieldEditorItem]);
	NSWindow *window = [windowItem window];

	_initialKeyWindow = [NSApp keyWindow]; /* Used by -wasKeyWindow: */
	_initialFirstResponder = [window firstResponder];

	switch ([anEvent type])
	{
		case NSMouseMoved:
			[self processMouseMovedEvent: anEvent];
			[ETTool updateCursorIfNeededForItem: [anEvent layoutItem]];
			break;
		case NSLeftMouseDown:
			_wasMouseDownProcessed = YES;
			/* Emit enter/exit events in case the event window is a new one */
			[self processMouseMovedEvent: anEvent]; 
			activeTool = [ETTool updateActiveToolWithEvent: anEvent];
			[activeTool mouseDown: anEvent];
			//NSLog(@"First responder from %@ to %@", [_initialFirstResponder primitiveDescription], [[window firstResponder] primitiveDescription]);
			break;
		case NSLeftMouseUp:
			_wasMouseDownProcessed = NO;
			[activeTool mouseUp: anEvent];
			break;
		case NSLeftMouseDragged:
			/* When the mouse moves or resizes a window not slowly, the pointer 
			   location is inside the window because the window geometry is 
			   yet to be updated to accomodate the move/resize delta. If we do 
			   not check that, a drag is initiated on the content item. */
			if ([self isMovingOrResizingWindow])
			{
				return NO;
			}
			[activeTool mouseDragged: anEvent];
			break;
		default:
			return NO;
	}

	[windowItem postFocusedItemChangeNotificationIfNeeded];

	BOOL firstResponderChanged = (_initialFirstResponder != [window firstResponder]);

	// NOTE: A better way to do that might be to use KVO on -[NSWindow firstResponder] 
	// with ETWindowItem and reacts to the change immediately.
	// However -[NSWindow firstResponder] isn't KVO-observable prior to 10.6.
	if (hadActiveFieldEditorItem && firstResponderChanged)
	{
		[activeTool tryRemoveFieldEditorItemWithEvent: anEvent];
	}

	ETAssert(initialActiveTool == activeTool || [anEvent type] == NSLeftMouseDown);
	return YES;
}


/** Synthetizes NSMouseEntered and NSMouseExited events when the mouse enters 
and exits layout items, and pushes them to the active tool.

For each mouse moved event, the receiver will emit new events:
<enum>
<item>-mouseMoved:</item>
<item>-mouseExited: (only if needed)</item>
<item>-mouseEntered: (onlt if needed)</item>
</enum>

Here is an example that shows which events you should expect by moving the 
pointer along the bullet line from W to D. W, A, B, D are layout items and W 
is the root item which contains both A and D.
<deflist>
<term>W (lauch time)</term><desc>Enter W</desc>
<term>W to A</term><desc>Enter A</desc>
<term>A to B</term><desc>Enter B</desc>
<term>B to D</term><desc>Exit B, Exit A, Enter D</desc>
</deflist>
          -------------------
          |                 |    |---------|
          |        |--------|    |         |
   W •••••|•• A •••|••• B ••|••••|••• D    |
          |        |--------|    |         |
          |                 |    |---------|
          -------------------
*/
- (void) processMouseMovedEvent: (ETEvent *)anEvent
{
	ETTool *tool = [ETTool activeTool];
	ETLayoutItem *hitItem =
		[[ETTool toolWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]]
			hitTestWithEvent: anEvent];

	//ETLog(@"Will process mouse move on %@ and hovered item stack\n %@", 
	//	hitItem, [tool hoveredItemStackForItem: hitItem]);

	[anEvent setLayoutItem: hitItem];
	/* We send move event before enter and exit events as AppKit does, we could 
	   have choosen to do the reverse though. */
	if ([anEvent type] == NSMouseMoved)
		[tool mouseMoved: anEvent];

	/* We call -synthetizeMouseExitedEvent: first because the exited item must 
	   be popped from the hovered item stack before a new one can be pushed. */
	ETEvent *exitEvent = [self synthetizeMouseExitedEvent: anEvent];
	ETEvent *enterEvent = [self synthetizeMouseEnteredEvent: anEvent];

	NSParameterAssert([[ETTool hoveredItemStackForItem: hitItem] firstObject] == [tool hitItemForNil]);

	/* Exit must be handled before enter because enter means the active 
	   tool might change and the new one may have a very different
	   dispatch than the tool attached to the area we exit. 
	   Different dispatch means the item on which the exit action will be 
	   invoked is unpredictable. */
	if (exitEvent != nil)
	{
		NSParameterAssert([exitEvent type] == NSMouseExited);

		/* We exit the area attached to the current active tool, hence 
		   we hand the dispatch to the previously active one. */
		[tool mouseExited: exitEvent];
	}
	if (enterEvent != nil)
	{
		NSParameterAssert([enterEvent type] == NSMouseEntered);

		/* The new active tool is attached to the area we enter in, hence 
		   we hand the dispatch to it. */
		[(ETTool *)[ETTool activeTool] mouseEntered: enterEvent];
	}

	//ETLog(@"Did process mouse move and hovered item stack\n %@", [ETTool hoveredItemStackForItem: hitItem]);
}

/** Always calls -synthetizeMouseExitedEvent: first because the exited item 
must be popped from the hovered item stack before a new one can be pushed. It 
also ensures the hovered item stack is valid. */
- (ETEvent *) synthetizeMouseEnteredEvent: (ETEvent *)anEvent
{
	// TODO: Evaluate whether we should rather do...
	//if (_lastWindowNumber != [anEvent windowNumber])
	//	return anEvent;
	if (nil == [anEvent window])
		return nil;

	/* The previously hovered item will have already been "popped" by
	   -synthetizeMouseExitedEvent: when an item is exited. Which means 
	   lastHoveredItem is usually not the previously hovered item but its parent. */
	ETLayoutItem *hoveredItem = [anEvent layoutItem];

	NSAssert([[ETTool hoveredItemStackForItem: hoveredItem] count] > 0,
		@"Hovered item stack must never be empty");

	/* See -processMouseMovedEvent: illustation example in the method doc. */
	BOOL onlyExit = (hoveredItem == _lastHoveredItem);
	BOOL noEnter = onlyExit;
	
	if (noEnter)
		return nil;

	_lastHoveredItem = hoveredItem;
	
	ETDebugLog(@"Synthetize mouse enters item %@", hoveredItem);

	return [ETEvent enterEventWithEvent: anEvent];
}

/** See -synthetizeMouseEnteredEvent:. */
- (ETEvent *) synthetizeMouseExitedEvent: (ETEvent *)anEvent
{
	// TODO: See -synthetizeMouseEnteredEvent:
	if (nil == [anEvent window])
		return nil;

	/* On an exit event, the hovered item is not the same than the last time
	   this method was called. */
	ETLayoutItem *hoveredItem = [anEvent layoutItem];

	NSAssert([[ETTool hoveredItemStackForItem: hoveredItem] count] > 0,
		@"Hovered item stack must never be empty");

	/* See -processMouseMovedEvent: illustation example in the method doc. */
	BOOL noExit = (_lastHoveredItem == hoveredItem || _lastHoveredItem == (id)[hoveredItem parentItem]);
	
	if (noExit)
		return nil;

	ETDebugLog(@"Synthetize mouse exits item %@", lastHoveredItem);

	ETEvent *exitEvent =  [ETEvent exitEventWithEvent: anEvent layoutItem: _lastHoveredItem];

	_lastHoveredItem = hoveredItem;

	return exitEvent;
}

/** Unlike other -processXXX methods, this one is called back by 
-[ETTool mouseDown:] where the active tool is responsible to choose 
the responder (layout item or widget view) on which the event is expected to be 
dispatched. */
- (BOOL) tryActivateItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent
{
	NSEvent *evt = [anEvent backendEvent];
	NSWindow *window = [evt window]; // FIXME: When item is not nil, should be [item window]...

	if (window == nil)
		return NO;

#ifdef GNUSTEP
	BOOL refusesKey = ([window level] == NSDesktopWindowLevel);
	BOOL refusesActivate = ([window styleMask] & (NSIconWindowMask | NSMiniWindowMask));
#else
	BOOL refusesKey = NO;
	BOOL refusesActivate = NO;
#endif

	/* Key window update */
	BOOL needsBecomeKey = ([window becomesKeyOnlyIfNeeded] == NO
		|| [[item view] needsPanelToBecomeKey]);

	if (refusesKey || needsBecomeKey == NO)
		return NO;

	[window makeKeyWindow];
	[window makeKeyAndOrderFront: self];
	/*if ([NSApp isActive])
		NSParameterAssert([NSApp keyWindow] == window);*/

	/* Active application update */
	if (refusesActivate || [NSApp isActive])
		return NO;
	
	[NSApp activateIgnoringOtherApps: YES];

	return YES;
}

- (BOOL) wasKeyWindow: (NSWindow *)aWindow
{
	return [aWindow isEqual: _initialKeyWindow];
}

- (void) sendMouseDown: (NSEvent *)evt toView: (NSView *)aView
{
	NSAssert([[evt window] isEqual: [aView window]], @"");

	/* First responder update
	   TODO: Try to remove, on Mac OS X, each control is responsible to decide 
	   whether it becomes first responder or not on mouse down */
#ifdef GNUSTEP
	/* A button must not become first responder on a click, otherwise it 
	   won't be able to send its action to the current first responder. */
	if ([aView isKindOfClass: [NSButton class]] == NO)
	{
	  	/* Prevent the mouse down when the view refuses the first responder 
	   	   status, however let the mouse down be sent to the view in case it 
	   	   returns NO for -acceptsFirstResponder. e.g. NSScroller returns NO 
	   	   but we still expect it to handle the mouse click. */
		if ([aView acceptsFirstResponder] 
		 && [[evt window] makeFirstResponder: aView] == NO)
		{
			return;
		}
	}
#endif

	/* Click-through support */
	if ([self wasKeyWindow: [evt window]] || [aView acceptsFirstMouse: evt])
	{
		[aView mouseDown: evt];
	}
}

/* This is similar to the logic implemented by -[NSWindow sendEvent:]. */
- (void) sendEvent: (ETEvent *)event toView: (NSView *)aView
{
	BOOL sent = [[[self delegate] ifResponds] eventProcessor: self 
	                                               sendEvent: event 
	                                                  toView: aView];

	if (sent)
		return;

	NSEvent *evt = (NSEvent *)[event backendEvent];

	switch ([evt type])
	{
		case NSLeftMouseDown:
			[self sendMouseDown: evt toView: aView];
			break;
		case NSLeftMouseUp:
			[aView mouseUp: evt];
			break;
		case NSLeftMouseDragged:
			[aView mouseDragged: evt];
			break;
		default:
			break;
	}
}

// TODO: Would be nice to eliminate that... 
- (NSView *) viewForHitTestWithItem: (ETUIItem *)anItem
{
	if ([anItem isWindowItem])
	{
		return [[(ETWindowItem *)anItem window] contentView];
	}
	else
	{
		return [anItem supervisorView];
	}
}

/** Tries to send an event to a view bound to the given item and returns whether 
the event was sent. The item view must returns YES to -isWidgetView, otherwise 
the event won't be sent.

If the event is located on a decorator item bound to the item, this method will 
try to send it to the widget view that makes up the decorator.

If item is nil, returns NO immediately. */
- (BOOL) trySendEvent: (ETEvent *)anEvent toWidgetViewOfItem: (ETLayoutItem *)item
{
	if (item == nil)
		return NO;

	NSPoint eventLoc = [anEvent locationInLayoutItem]; /* In the argument item coordinate space */
	
	/* We ignore events that occur outside of the layout item frame 
	   e.g. hit in the bounding box extended area. */
	if ([item pointInside: eventLoc useBoundingBox: NO] == NO)
		return NO;

	ETUIItem *hitItem = [item decoratorItemAtPoint: eventLoc]; 
	NSParameterAssert([anEvent layoutItem] == item);
	NSParameterAssert(hitItem != nil);

	/* Convert eventLoc to hitItem coordinate space */
	id decorator = [item lastDecoratorItem];
	NSPoint relativeLoc = eventLoc;

	while (decorator != hitItem)
	{
		relativeLoc = [decorator convertDecoratorPointToContent: relativeLoc];
		decorator = [decorator decoratedItem];
	}

	/* Try to send the event */
	if ([hitItem usesWidgetView])
	{
		/* The hit test view is the hit item supervisor view or equivalent and 
		   not the widget view itself. 
		   The hit test point is thus in the coordinate space of the 
		   superview of the supervisor view or equivalent (-[NSView hitTest:] 
		   takes a point expressed in the superview coordinate space).
		   Note that the window view is never flipped, even when the window 
		   item is, that's why we do the point conversion with a NSView method. */
		NSView *hitTestView = [self viewForHitTestWithItem: hitItem];
		NSPoint hitTestLoc = [hitTestView convertPoint: relativeLoc 
		                                        toView: [hitTestView superview]];
		NSView *widgetSubview = [hitTestView hitTest: hitTestLoc];

		ETDebugLog(@"Hit test widget subview %@ at %@ in %@", widgetSubview, 
			NSStringFromPoint(hitTestLoc), hitItem);

		BOOL isVisibleSubview = ([widgetSubview window] != nil);
		if (isVisibleSubview) /* For opaque layout that cover item views */
		{
			[self sendEvent: anEvent toView: widgetSubview];
			return YES;
		}
	}

	return NO;
}


@end
