/**
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETResponder.h>
#import <EtoileUI/ETUIObject.h>

@class COObjectGraphContext;
@class ETEvent, ETLayoutItem, ETLayoutItemGroup, ETLayout;

/** @group Tools

@abstract A tool represents an interaction mode to handle and dispatch events 
turned into actions in the layout item tree.

Action Handlers are bound to layout items. Tool are bound to layouts.

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
@interface ETTool : ETUIObject <ETResponder>
{
	@private
	ETLayoutItem *_targetItem;
	NSString *_cursorName;
}

/** @taskunit Registering Tools */

+ (void) registerAspects;
+ (void) registerTool: (ETTool *)anTool;
+ (NSSet *) registeredTools;
+ (NSSet *) registeredToolClasses;

/** @taskunit Tool Activation */

+ (ETTool *) updateActiveToolWithEvent: (ETEvent *)anEvent;
+ (void) updateCursorIfNeededForItem: (ETLayoutItem *)anItem;
+ (id) activatableToolForItem: (ETLayoutItem *)anItem;

/** @taskunit Active and Main Tools */

+ (id) activeTool;
+ (ETTool *) setActiveTool: (ETTool *)toolToActivate;
+ (id) mainTool;
+ (void) setMainTool: (id)aTool;

/** @taskunit Initialization */

+ (instancetype) toolWithObjectGraphContext: (COObjectGraphContext *)aContext;
- (instancetype) initWithObjectGraphContext: (COObjectGraphContext *)aContext NS_DESIGNATED_INITIALIZER;

/** @taskunit Type Querying */

@property (nonatomic, readonly) BOOL isTool;

/** @taskunit Targeted Item */

@property (nonatomic, strong) ETLayoutItem *targetItem;

/** @taskunit Activation Hooks */

- (void) didBecomeActive;
- (void) didBecomeInactive;
- (BOOL) shouldActivateTool: (ETTool *)foundTool
             attachedToItem: (ETLayoutItem *)anItem;

/** @taskunit Hit Test */

@property (nonatomic, readonly) ETLayoutItem *hitItemForNil;

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

/** @taskunit Event Handler Requests */

- (BOOL) tryActivateItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent;
- (void) trySendEventToWidgetView: (ETEvent *)anEvent;
- (BOOL) tryRemoveFieldEditorItemWithEvent: (ETEvent *)anEvent;
- (void) tryPerformKeyEquivalentAndSendKeyEvent: (ETEvent *)anEvent 
                                    toResponder: (id)aResponder;

/** @taskunit Event Handlers */

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

/** @taskunit Cursor */

@property (nonatomic, copy) NSString *cursorName;

/** @taskunit UI Utility */

+ (void) show: (id)sender;

@property (nonatomic, readonly) NSMenu *menuRepresentation;

/** @taskunit Framework Private */

+ (ETUUID *) activeToolUUID;
+ (NSMutableArray *) hoveredItemStackForItem: (ETLayoutItem *)anItem;
- (void) validateLayoutOwner: (ETLayout *)aLayout;

@property (nonatomic, readonly, weak) ETLayout *layoutOwner;
@property (nonatomic, readonly, strong) NSCursor *cursor;

// FIXME: Remove... clang complains about -[NSResponder performKeyEquivalent:] 
// whose argument is NSEvent * and misses the declaration in the private category.
// #pragma clang diagnostic ignored "-Wall" also doesn't work.
- (BOOL) performKeyEquivalent: (ETEvent *)anEvent;

@end

extern NSString * const kETToolCursorNameArrow;
extern NSString * const kETToolCursorNameOpenHand;
extern NSString * const kETToolCursorNamePointingHand;
