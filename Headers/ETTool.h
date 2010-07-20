/** <title>ETTool</title>

	<abstract>An tool represents an interaction mode to handle and 
	dispatch events turned into actions in the layout item tree .</abstract>

	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETEvent, ETLayoutItem, ETLayoutItemGroup, ETLayout;

@protocol ETFirstResponderSharingArea
- (ETLayoutItem *) activeFieldEditorItem;
- (ETLayoutItem *) editedItem;
- (void) setActiveFieldEditorItem: (ETLayoutItem *)anItem 
                       editedItem: (ETLayoutItem *)anItem;
- (void) removeActiveFieldEditorItem;
@end

/** Action Handlers are bound to layout items.
    Tool are bound to layouts.

A main tool is set by default for the entire layout item tree. This main 
tool is an ETArrowTool instance attached the root item layout. 
Tools can be attached to any other layouts in the layout item tree. In 
this way, layouts can override the main tool and the tools attached 
to the layouts of their ancestor items.

You can also define an editor tool and a set of target layout items, usually 
your document items. Each time, -setEditorTool: is 
called, this tool is attach to the layout of these items.

When the mouse enters in a layout item frame, it checks the layout bound to
to it and activates the attached tool if there is one.
	
If -selection doesn't return nil, the selection object is inserted in front of 
the responder chain, right before the first responder. By default, it 
forwards the actions to all the selected objects it contains. If they cannot 
handle an action, the action is passed to their next responders. 

The tool attached to a layout controls how tools attached to child 
layouts are activated. By default, they got activated on mouse enter and 
deactivated on mouse exit. However some intruments such as ETSelectTool 
implement a custom policy: the tools of child layouts are activated on 
double-click and deactivated on a mouse click outside of their layout boundaries
(see -setDeactivateOn:). */
@interface ETTool : NSResponder <NSCopying>
{
	@private
	NSMutableArray *_hoveredItemStack; /* Lazily initialized, never access directly */
	ETLayoutItem *_targetItem;
	ETLayout *_layoutOwner;
	NSCursor *_cursor;
	
	id _firstKeyResponder; /** The last key responder set */
	id _firstMainResponder; /** The last main responder set */

	BOOL _customActivation; /* Not yet used... */
}

/* Registering Tools */

+ (void) registerAspects;
+ (void) registerTool: (ETTool *)anTool;
+ (NSSet *) registeredTools;
+ (NSSet *) registeredToolClasses;

+ (void) show: (id)sender;

/* Tool Activation */

+ (ETTool *) updateActiveToolWithEvent: (ETEvent *)anEvent;
+ (void) updateCursorIfNeeded;

/* Factory Methods */

+ (id) activeTool;
+ (void) setActiveTool: (ETTool *)toolToActivate;
+ (id) activatableTool;
+ (id) mainTool;
+ (void) setMainTool: (id)aTool;

+ (id) tool;

/* Initialization */

- (id) init;

- (id) copyWithZone: (NSZone *)aZone;

- (BOOL) isTool;

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

- (id <ETFirstResponderSharingArea>) editionCoordinatorForItem: (ETLayoutItem *)anItem;

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
- (BOOL) tryRemoveFieldEditorItemWithEvent: (ETEvent *)anEvent;
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
- (ETTool *) lookUpToolInHoveredItemStack;
- (void) rebuildHoveredItemStackIfNeededForEvent: (ETEvent *)anEvent;

- (void) setLayoutOwner: (ETLayout *)aLayout;
- (ETLayout *) layoutOwner;

// FIXME: Remove... clang complains about -[NSResponder performKeyEquivalent:] 
// whose argument is NSEvent * and misses the declaration in the private category.
// #pragma clang diagnostic ignored "-Wall" also doesn't work.
- (BOOL) performKeyEquivalent: (ETEvent *)anEvent;

@end

// TODO: Evaluate... Not yet implemented.
@interface NSObject (ETToolDelegate)
- (BOOL) tool: (ETTool *)anTool shouldDeactivateWithEvent: (ETEvent *)anEvent;
- (ETTool *) toolToActivateWithEvent: (ETEvent *)anEvent;
@end


/** An ETFirstResponderProxy instance is passed to 
-[NSWindow makeFirstResponder:], when you call -setFirstKeyResponder: or 
-setFirstMainResponder: on ETTool with an object that is not an 
NSResponder. For example, ETLayoutItem does not inherit from NSResponder, hence 
it cannot be directly declared as the window first responder.

You should not be concerned about this class which is mostly an implementation 
detail. The only case where you might have to deal with it is when you use 
-[NSWindow firstResponder]. Yet you should avoid NSWindow API, and rather 
interact with the first responder through the active tool only.

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
