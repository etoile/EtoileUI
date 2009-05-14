/** <title>ETInstrument</title>

	<abstract>An instrument represents an interaction mode to handle and 
	dispatch events turned into actions in the layout item tree .</abstract>

	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETEvent, ETLayoutItem, ETLayoutItemGroup, ETLayout;

/** Action Handlers are bound to layout items.
    Instrument are bound to layouts.

A main instrument is set by default for the entire layout item tree. This main 
instrument is an ETArrowTool instance attached the root item layout. 
Instruments can be attached to any other layouts in the layout item tree. In 
this way, layouts can override the main instrument and the instruments attached 
to the layouts of their ancestor items.

You can also define an editor instrument and a set of target layout items, usually 
your document items. Each time, -setEditorInstrument: is 
called, this instrument is attach to the layout of these items.

When the mouse enters in a layout item frame, it checks the layout bound to
to it and activates the attached instrument if there is one.
	
If -selection doesn't return nil, the selection object is inserted in front of 
the responder chain, right before the first responder. By default, it 
forwards the actions to all the selected objects it contains. If they cannot 
handle an action, the action is passed to their next responders. 

The instrument attached to a layout controls how instruments attached to child 
layouts are activated. By default, they got activated on mouse enter and 
deactivated on mouse exit. However some intruments such as ETSelectTool 
implement a custom policy: the instruments of child layouts are activated on 
double-click and deactivated on a mouse click outside of their layout boundaries
(see -setDeactivateOn:). */
@interface ETInstrument : NSResponder
{
	NSMutableArray *_hoveredItemStack; /* Lazily initialized, never access directly */
	ETLayoutItem *_targetItem;
	ETLayout *_layoutOwner;
	NSCursor *_cursor;
	
	id _firstKeyResponder; /** The last key responder set */
	id _firstMainResponder; /** The last main responder set */

	BOOL _customActivation; /* Not yet used... */
}

/* Registering Instruments */

+ (void) registerInstrumentClass: (Class)instrumentClass;
+ (NSSet *) registeredInstrumentClasses;

+ (NSArray *) registeredInstruments;
+ (void) show: (id)sender;

/* Instrument Activation */

+ (ETInstrument *) updateActiveInstrumentWithEvent: (ETEvent *)anEvent;
+ (void) updateCursorIfNeeded;

/* Factory Methods */

+ (id) activeInstrument;
+ (id) activatableInstrument;
+ (id) mainInstrument;
+ (void) setMainInstrument: (id)anInstrument;

+ (id) instrument;

/* Initialization */

- (id) init;

/* Activation Hooks */

- (void) didBecomeActive;
- (void) didBecomeInactive;

- (ETLayoutItem *) targetItem;
- (void) setTargetItem: (ETLayoutItem *)anItem;

/* Actions */

- (BOOL) makeFirstResponder: (id)aResponder;
- (BOOL) makeFirstKeyResponder: (id)aResponder;
- (BOOL) makeFirstMainResponder: (id)aResponder;
- (id) firstKeyResponder;
- (id) firstMainResponder;
- (ETLayoutItem *) keyItem;
- (ETLayoutItem *) mainItem;

/* Hit Test */

- (ETLayoutItem *) hitItemForNil;
- (ETLayoutItem *) hitTestWithEvent: (ETEvent *)anEvent;
- (ETLayoutItem *) hitTest: (NSPoint)itemRelativePoint 
                 withEvent: (ETEvent *)anEvent 
				    inItem: (ETLayoutItem *)anItem;
- (ETLayoutItem *) willHitTest: (NSPoint)itemRelativePoint 
                     withEvent: (ETEvent *)anEvent 
				        inItem: (ETLayoutItem *)anItem
                   newLocation: (NSPoint *)returnedItemRelativePoint;
- (BOOL) shouldContinueHitTest: (NSPoint)itemRelativePoint 
                     withEvent: (ETEvent *)anEvent 
				        inItem: (ETLayoutItem *)anItem
				   wasReplaced: (BOOL)wasItemReplaced;

/* Events */

- (BOOL) tryActivateItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent;
- (void) trySendEventToWidgetView: (ETEvent *)anEvent;
- (void) tryPerformKeyEquivalentAndSendKeyEvent: (ETEvent *)anEvent 
                                    toResponder: (id)aResponder;

- (void) mouseDown: (ETEvent *)anEvent;
- (void) mouseUp: (ETEvent *)anEvent;
- (void) mouseDragged: (ETEvent *)anEvent;
- (void) mouseMoved: (ETEvent *)anEvent;
- (void) mouseEntered: (ETEvent *)anEvent;
- (void) mouseExited: (ETEvent *)anEvent;
- (void) mouseEnteredChild: (ETEvent *)anEvent;
- (void) mouseExitedChild: (ETEvent *)anEvent;
- (void) keyDown: (ETEvent *)anEvent;
- (void) keyUp: (ETEvent *)anEvent;

- (BOOL) isFirstResponderProxy;

/* Cursor */

- (void) setCursor: (NSCursor *)aCursor;
- (NSCursor *) cursor;

/* UI Utility */

- (NSMenu *) menuRepresentation;

/* Framework Private */

- (NSMutableArray *) hoveredItemStack;
- (ETInstrument *) lookUpInstrumentInHoveredItemStack;
- (void) rebuildHoveredItemStackIfNeededForEvent: (ETEvent *)anEvent;

- (void) setLayoutOwner: (ETLayout *)aLayout;
- (ETLayout *) layoutOwner;

@end

// TODO: Evaluate... Not yet implemented.
@interface NSObject (ETInstrumentDelegate)
- (BOOL) instrument: (ETInstrument *)anInstrument shouldDeactivateWithEvent: (ETEvent *)anEvent;
- (ETInstrument *) instrumentToActivateWithEvent: (ETEvent *)anEvent;
@end

/** An ETFirstResponderProxy instance is passed to 
-[NSWindow makeFirstResponder:], when you call -setFirstKeyResponder: or 
-setFirstMainResponder: on ETInstrument with an object that is not an 
NSResponder. For example, ETLayoutItem does not inherit from NSResponder, hence 
it cannot be directly declared as the window first responder.

You should not be concerned about this class which is mostly an implementation 
detail. The only case where you might have to deal with it is when you use 
-[NSWindow firstResponder]. Yet you should avoid NSWindow API, and rather 
interact with the first responder through the active instrument only.

This class is specific to the AppKit backend. */
@interface ETFirstResponderProxy : NSResponder
{
	id _object;
}

+ (ETFirstResponderProxy *) responderProxyWithObject: (id)anObject;
- (BOOL) isEqual: (id)anObject;
- (BOOL) isFirstResponderProxy;
- (BOOL) isLayoutItem;
- (id) object;

- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

@end
