/** <title>ETEventProcessor</title>

	<abstract>ETEventProcessor converts the events emitted by the widget backend 
	into ETEvent objects before forwarding them to the active tool.</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  February 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>

// FIXME: Don't expose NSView and NSWindow in the public API.
@class NSView, NSWindow;
@class ETEvent, ETUIItem, ETLayoutItem;

/** The active tool handles the dispatch in the layout item tree. */
@interface ETEventProcessor : NSObject
{
	@private
	id _delegate;
}

/** @taskunit Initialization */

+ (instancetype) sharedInstance;

/** @taskunit Converting Backend Event */

- (BOOL) processEvent: (void *)backendEvent;
- (void) runUpdatePhases;
- (BOOL) beginContinuousActionsForItem: (ETLayoutItem *)anItem;
- (BOOL) endContinuousActionsForItem: (ETLayoutItem *)anItem;

/** @taskunit Backend Window Activation */

- (BOOL) tryActivateItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent;

/** @taskunit Widget View Event Delivery */

- (BOOL) trySendEvent: (ETEvent *)anEvent toWidgetViewOfItem: (ETLayoutItem *)item;

/** @taskunit Delegate */

@property (nonatomic, assign) id delegate;

@end

@interface NSObject (ETEventProcessorDelegate)
/** Tells the receiver to send the event to the given widget view.

Should return whether the event has been sent to the view. When NO is returned,
the event processor is responsible to send the event to the view.

The view is the widget view in -[ETEventProcessor trySendEvent:toWidgetViewOfItem:].

The delegate method is usually implemented as below:

<example>
if ([aView isSpecialView] == NO)
	return NO;

// We hand ETEvent objects to the view, so the view must implement event methods 
// that don't overlap with NSResponder methods expecting NSEvent.
switch ([anEvent type])
{
	case NSLeftMouseDown:
		[aView sendMouseDown: anEvent];
		break;
	case NSLeftMouseDragged:
		[aView sendMouseDragged: anEvent];
		break;
	default:
		break;
}
return YES;
</example> */
- (BOOL) eventProcessor: (ETEventProcessor *)eventProcessor 
              sendEvent: (ETEvent *)anEvent 
                 toView: (NSView *)aView;
@end

extern NSString * const ETEventProcessorDidProcessEventNotification;


@interface ETAppKitEventProcessor : ETEventProcessor
{
	@private
	ETLayoutItem *_lastHoveredItem;
	NSWindow *_initialKeyWindow;
	id _initialFirstResponder;
	BOOL _wasMouseDownProcessed;
	BOOL _isProcessingContinuousActionEvents;
}

/** @taskunit Converting Backend Event */

- (BOOL) processMouseEvent: (ETEvent *)anEvent;
- (void) processMouseMovedEvent: (ETEvent *)anEvent;
- (BOOL) processKeyEvent: (ETEvent *)anEvent;
- (ETEvent *) synthetizeMouseEnteredEvent: (ETEvent *)anEvent;
- (ETEvent *) synthetizeMouseExitedEvent: (ETEvent *)anEvent;

@end
