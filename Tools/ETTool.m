/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETTool.h"
#import "ETArrowTool.h"
#import "ETEvent.h"
#import "ETEventProcessor.h"
#import "ETGeometry.h"
#import "ETActionHandler.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETApplication.h"
#import "ETLayout.h"
#import "ETView.h"
#import "ETWindowItem.h"
// FIXME: Move related code to the Appkit widget backend (perhaps in a category)
#import "ETWidgetBackend.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"

#pragma GCC diagnostic ignored "-Wprotocol"

@interface ETTool (Private)
- (BOOL) performKeyEquivalent: (ETEvent *)anEvent;
@end


@implementation ETTool

static ETUUID *initialToolUUID = nil;
static ETUUID *mainToolUUID = nil;
static ETUUID *activeToolUUID = nil;
static COObjectGraphContext *activeToolContext = nil;

+ (void) initialize
{
	if (self != [ETTool class])
		return;
	
	[self applyTraitFromClass: [ETResponderTrait class]];

    initialToolUUID = [ETUUID new];
    mainToolUUID = [initialToolUUID copy];
    activeToolUUID = [initialToolUUID copy];
}

/** For recreating the initial tools, between tests in the test suite. */
+ (void) resetTools
{
    if ([mainToolUUID isEqual: initialToolUUID] && [activeToolUUID isEqual: initialToolUUID])
		return;

	mainToolUUID = initialToolUUID;
	activeToolUUID = initialToolUUID;
	activeToolContext = nil;
}

#pragma mark Registering Tools -

static NSMutableSet *toolPrototypes = nil;

/** Registers a prototype for every ETTool subclasses.

The implementation won't be executed in the subclasses but only the abstract 
base class.

You should never need to call this method.

See also NSObject(ETAspectRegistration). */
+ (void) registerAspects
{
	toolPrototypes = [NSMutableSet set];

	FOREACH([self allSubclasses], subclass, Class)
	{
		[self registerTool: [[subclass alloc] initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]]];
	}
}

+ (NSString *) baseClassName
{
	return @"Tool";
}

/** Makes the given prototype available to EtoileUI facilities (inspector, etc.) 
that allow to change an tool at runtime.

Also publishes the prototype in the shared aspect repository (not yet implemented). 

Raises an invalid argument exception if anTool class isn't a subclass of 
ETTool. */
+ (void) registerTool: (ETTool *)anTool
{
	if ([anTool isKindOfClass: [ETTool class]] == NO)
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Prototype %@ must be a subclass of ETTool to get "
		                    @"registered as an tool prototype.", anTool];
	}

	[toolPrototypes addObject: anTool];
	// TODO: Make a class instance available as an aspect in the aspect 
	// repository.
}

/** Returns all the tool prototypes directly available for EtoileUI 
facilities that allow to transform the UI at runtime. */
+ (NSSet *) registeredTools
{
	return [toolPrototypes copy];
}

/** Returns all the tool classes directly available for EtoileUI facilities 
that allow to transform the UI at runtime.

These tool classes are a subset of the registered tool prototypes since 
several prototypes might share the same class. */
+ (NSSet *) registeredToolClasses
{
	return (NSSet *)[[toolPrototypes mappedCollection] class];
}

#pragma mark Tool Activation -

/** <override-never />
Updates the cursor with the one provided by the activatable tool.

You should never to call this method, only ETEventProcessor is expected to use 
it. */
+ (void) updateCursorIfNeededForItem: (ETLayoutItem *)anItem
{
	[[(ETTool *)[self activatableToolForItem: anItem] cursor] set];
}

/** <override-never />
Updates the active tool with a new one looked up in the active tool 
hovered item stack, and returns the resulting active tool.

You should never to call this method, only ETEventProcessor is expected to use 
it. */
+ (ETTool *) updateActiveToolWithEvent: (ETEvent *)anEvent
{
	BOOL isFieldEditorEvent = ([[anEvent windowItem] hitTestFieldEditorWithEvent: anEvent] != nil);

	if (isFieldEditorEvent)
	{
		return [self activeTool];
	}

	ETTool *toolToActivate = [self activatableToolForItem: [anEvent layoutItem]];
	return [self setActiveTool: toolToActivate];
}

/* Returns the hovered item stack that is used to look up the tool to activate. See +activatableToolForItem:.

The item at the top (index == count - 1) is the deepest descendant hovered by 
the cursor, while the item at bottom is the highest ancestor in the item tree 
(it is the root item, and always the window group currently).

When the cursor is over a handle, the hovered item stack contains items that 
don't belong to the item tree rooted in the window group. Handles, separators, 
etc. belong to -[ETLayout layerItem] and layer items have their parent item set,
but -[ETLayoutItemGroup items] never include a layer item.

You should never need to use this method. */
+ (NSArray *) hoveredItemStackForItem: (ETLayoutItem *)aHitItem
{
	NSParameterAssert(aHitItem != nil);

	ETLayoutItem *item = aHitItem;
	NSMutableArray *newStack = [NSMutableArray array];
	
	do
	{
		[newStack insertObject: item atIndex: 0];
		item = [item parentItem];
	} while (item != nil);

	// FIXME: Work around inspectors and other windows whose content view 
	// has a layout item with no parent, when it should be a window layer child.
	// We can probably remove this workaround now.
	if ([newStack firstObject] != [[ETLayoutItemFactory factory] windowGroup])
	{
		[newStack insertObject: [[ETLayoutItemFactory factory] windowGroup] atIndex: 0];
	}

	return newStack;
}

/** Looks up and returns the tool to be activated in the current hovered 
item stack.

The stack is traversed upwards to the root item. The traversal ends on the 
first layout with a tool attached to it.

The stack is never empty because the pointer never exits the root item which 
covers the whole screen. 

For a nil item, raises a NSInvalidArgumentException.

You should rarely need to override this method. */
+ (ETTool *) activatableToolForItem: (ETLayoutItem *)anItem;
{
	NILARG_EXCEPTION_TEST(anItem);
	ETTool *foundTool = nil;

	/* The last/top object is the tool at the lowest/deepest level in the item tree among the items in the stack */
	for (ETLayoutItem *item in [[self hoveredItemStackForItem: anItem] reverseObjectEnumerator])
	{
		ETDebugLog(@"Look up tool at level %@ in hovered item stack", item);

		/* The top item can be an ETLayoutItem instance */
		if ([item isGroup] == NO)
			continue;
		
		foundTool = [[item layout] attachedTool];

		/* Don't activate tool bound to a widget layout (see also +setActiveTool:) */
		if ([[self activeTool] shouldActivateTool: foundTool attachedToItem: item])
			break;
	}

	// TODO: We could forbid setting a nil tool on the root item.
	BOOL overRootItem = (foundTool == nil);

	foundTool = (overRootItem ? [[self class] mainTool] : foundTool);
	ETAssert(foundTool != nil);
	return foundTool;
}

#pragma mark Active and Main Tools -

+ (ETTool *) toolForUUID: (ETUUID *)aToolUUID
      objectGraphContext: (COObjectGraphContext *)aContext
{
	COObjectGraphContext *context =
		(aContext != nil ? aContext : [ETUIObject defaultTransientObjectGraphContext]);
    ETTool *tool = [context loadedObjectForUUID: aToolUUID];
        
	if (tool != nil || [aToolUUID isEqual: mainToolUUID] == NO)
        return tool;

    ETEntityDescription *entity =
        [[context modelDescriptionRepository] entityDescriptionForClass: [ETArrowTool class]];
        
    return [[ETArrowTool alloc] initWithEntityDescription: entity
                                                     UUID: aToolUUID
                                       objectGraphContext: context];
}

/** Returns the last active tool UUID, even if the active tool has been unloaded. 

This can be used to check the active tool identity when objects get discarded, 
without recreating it by calling +activeTool. */
+ (ETUUID *) activeToolUUID
{
    return activeToolUUID;
}

/** Returns the active tool through which the events are dispatched in the 
layout item tree. 
 
By default, returns the mail tool.

Unless +mainTool is returned, the returned tool target item is not nil. See 
explanations in +mainTool. 

See +setActiveTool:, -targetItem and -layoutOwner. */
+ (id) activeTool
{
    ETTool *activeTool = [self toolForUUID: activeToolUUID
                        objectGraphContext: activeToolContext];

#if 0
	ETAssert([activeTool targetItem] != nil || [activeTool isEqual: [self mainTool]]);

	// TODO: If an item is detached in the item tree, and the active tool is
	// bound to a descendant item, we could update the active tool using:
	//
	// if ([detachedItem isAncestorOfItem: itemOwningActiveTool])
	// {
	//   [[ETTool setActiveTool: [ETTool activatableToolForItem: [detachedItem parentItem]]
	// }
	//
	// We could put this code in -[ETLayout setUp], -[ETLayout tearDown],
	// -[ETLayoutItemGrup detachItem:] or -[ETLayoutItemGrup detachItem:].
	BOOL mustHaveValidLayoutOwner = (activeTool != mainTool);

	if (mustHaveValidLayoutOwner)
	{
		NSAssert([(id)[[activeTool layoutOwner] layoutContext] rootItem] == [ETApp rootItem],
			@"The active tool must remain rooted in the main item tree (the application UI presently in use)");
	}
#endif

	return activeTool;
}

+ (void) notifyOfChangeFromTool: (ETTool *)oldTool 
                         toTool: (ETTool *)newTool
{
	// TODO: Post a notification
}

/** Sets the active tool through which the events are dispatched in the 
layout item tree.

Take a look at -didBecomeActive and -didBecomeInactive to react to activation 
and deactivation in your ETTool subclasses.
 
If the tool has become active, returns the tool passed in argument, otherwise 
returns the previously active tool. A tool bound to an item that returns YES 
to -[ETLayoutItem usesWidgetView] cannot become active.

For a nil tool or tool not attached to a layout (the main tool puts aside), 
raises an NSInvalidArgumentException.

For a tool not attached to the item tree rooted in -[ETApplication rootItem], 
raises an NSInvalidArgumentException.

You should rarely need to invoke this method since EtoileUI usually 
automatically activates tools in response to the user's click with 
-updateActiveToolWithEvent:. */
+ (ETTool *) setActiveTool: (ETTool *)toolToActivate
{
	NILARG_EXCEPTION_TEST(toolToActivate);
	if ([toolToActivate isEqual: [ETTool mainTool]] == NO)
	{
		INVALIDARG_EXCEPTION_TEST(toolToActivate, [toolToActivate layoutOwner]);
		INVALIDARG_EXCEPTION_TEST(toolToActivate,
			[[[toolToActivate targetItem] rootItem] isEqual: [ETApp rootItem]]);
	}

	/* -layoutOwner can be nil at this point e.g. for the default main tool or
	   if the user sets a custom tool not bound to any layout.
	   See also +activatableToolForItem: */
	if ([[toolToActivate layoutOwner] isWidget])
		 return [self activeTool];

	/* Prevent the user to set a tool on an item using a widget view */
	NSParameterAssert([[(id)[[toolToActivate layoutOwner] layoutContext] ifResponds] usesWidgetView] == NO);

	ETTool *toolToDeactivate = [self activeTool];

	if ([toolToActivate isEqual: toolToDeactivate])
		return [self activeTool];

	ETDebugLog(@"Update active tool to %@", toolToActivate);
	
	activeToolUUID = [toolToActivate UUID];
	activeToolContext = [toolToActivate objectGraphContext];

	[toolToDeactivate didBecomeInactive];
	[toolToActivate didBecomeActive];
	[self notifyOfChangeFromTool: toolToDeactivate 
	                      toTool: toolToActivate];

	return toolToActivate;
}

/** Returns the tool to be used as active tool when no other tools can be looked 
up and activated.

The main tool is not explicitly attached to the root item in the layout item 
tree, since the window group bounds doesn't include the menu area, and we want 
to process events in this area too.

This tool is never persistent.

In the future, the root item should be an item that encloses the window group 
area and the menu area (we could then state that +activeTool always return a 
tool whose -layoutOwner is not nil). */
+ (id) mainTool
{
    return [self toolForUUID: mainToolUUID
          objectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
}

/** Sets the tool to be be used as active tool, when no other tools can be 
looked up and activated.

For a nil tool or a tool that doesn't belong to 
-[ETUIObject defaultTransientObjectGraphContext], raises an 
NSInvalidArgumentException.

If the main tool was the active tool, the active tool is changed too.

See also -mainTool. */
+ (void) setMainTool: (id)aTool
{
	NILARG_EXCEPTION_TEST(aTool);
    INVALIDARG_EXCEPTION_TEST(aTool,
        [aTool objectGraphContext] == [ETUIObject defaultTransientObjectGraphContext]);

	ETAssert([self activeTool] != nil);
	BOOL wasPreviousMainToolActive = [[self activeTool] isEqual: [self mainTool]];

	mainToolUUID = [aTool UUID];

	if (wasPreviousMainToolActive)
	{
		[self setActiveTool: [self mainTool]];
	}
}

#pragma mark Initialization -

/** Returns a new autoreleased tool instance. */
+ (id) toolWithObjectGraphContext: (COObjectGraphContext *)aContext;
{
	return [[self alloc] initWithObjectGraphContext: aContext];
}

- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	[self setCursorName: kETToolCursorNameArrow];
	return self;
}

- (BOOL) respondsToSelector: (SEL)aSelector
{
	if ([super respondsToSelector: aSelector])
		return YES;
	
	return [[ETActionHandler sharedFallbackResponder] respondsToSelector: aSelector];
}

- (id) forwardingTargetForSelector: (SEL)aSelector
{
	if ([[ETActionHandler sharedFallbackResponder] respondsToSelector: aSelector])
	{
		return [ETActionHandler sharedFallbackResponder];
	}
	else
	{
		return [super forwardingTargetForSelector: aSelector];
	}
}

/* Returns nil or the candidate focused item from the target item. */
- (ETLayoutItem *) candidateFocusedItem
{
	return [[self nextResponder] candidateFocusedItem];
}

/** Returns YES. */
- (BOOL) isTool
{
	return YES;
}

#pragma mark Targeted Item -

/** Returns the layout item on which the receiver is currently acting.

The target item is very often different from the hit item returned by 
-hitTestWithEvent:. For example, when you select layout items with a selection 
rectangle (see ETSelectTool), the target item is where the mouse down occured, 
but as the selection rectangle is resized by the dragging, the mouse might enter 
and exit descendant items. Each time a descendant items is hovered or the mouse 
is outside of the boundaries of the target item, the hit item won't match the 
target item.

By default, the target item is the item bound to the -ownerLayout. This bound 
item is named the layout context in ETLayout.

The target item can be nil, when the tool is not bound to a layout, or when 
this layout is not bound to an item (as a layout context).

See also -setTargetItem:. */
- (ETLayoutItem *) targetItem
{
	ETLayoutItem *targetItem = _targetItem;

	if (_targetItem == nil)
	{
		[self validateLayoutOwner: [self layoutOwner]];
		targetItem = (ETLayoutItem *)[[self layoutOwner] layoutContext];
	}

	ETAssert(targetItem != nil || [[self layoutOwner] layoutContext] == nil);
	return targetItem;
}

/** Sets the layout item on which the receiver is currently acting.

If you write a tool subclass which interprets mouse move or drag events in its 
own way, descendant items might be entered and exited. By setting a target item 
at the beginning of the motion, you can track what is the background item 
targeted by the tool and the event coordinates relative to this target item. 
For example, a brush tool can create a stroke that crosses one or several layout 
items, yet every stroke dabs must normally be applied/drawn in only one target 
item. In case the stroke motion ends elsewhere than in the target item, the 
stroke should similarly still be inserted in the target item (where the brush 
stroke started with the mouse down event).

You easily set a target item by overriding -hitTestWithEvent:inItem:.

If the target item is the same than the item owning the tool, or is not a 
descendant item, raises NSInvalidArgumentException. To reset the the target item 
to the item owning the tool, pass nil.

The target item is reset on -[ETLayout setAttachedTool:].

See also -targetItem. */
- (void) setTargetItem: (ETLayoutItem *)anItem
{
	/* To prevent a retain cycle in the diagram below, we prevent _targetItem
	   and [_layoutOwner layoutContext] to point to the same object.

	   layout context ---> layout ---> tool
	         |                           |
			 v                           |
	   child/target item <----------------
		
	    If the targetItem is set to nil, -targetItem returns -layoutOwner.
	 */
	if (anItem != nil)
	{
		INVALIDARG_EXCEPTION_TEST(anItem, anItem != (id)[[self layoutOwner] layoutContext]);
		INVALIDARG_EXCEPTION_TEST(anItem, [(id)[[self layoutOwner] layoutContext] isDescendantItem: anItem]);
	}
	//ETLog(@"Change target item to %@ in %@", anItem, self);

	if ([anItem isEqual: _targetItem])
		return;

	_targetItem = anItem;
}

- (void) validateLayoutOwner: (ETLayout *)aLayout
{
	if ([aLayout layoutContext] != nil && [(id)[aLayout layoutContext] isLayoutItem] == NO)
	{
		[NSException raise: NSInternalInconsistencyException
		            format: @"You cannot have a tool attached to a secondary layout "
					         "(usually a computed layout set on some other layout)"];
	}
}

/** Returns the layout to which the tool is attached to. 

aLayout has ownership over the receiver, so it won't be retained.

Changing the layout owner resets -targetItem to return 
<code>[[self layoutOwner] layoutContext]</code>. */
- (ETLayout *) layoutOwner
{
	return [self valueForVariableStorageKey: @"layoutOwner"];
}

#pragma mark Activation Hooks -

/** <override-dummy />
Called when the tool becomes active, usually when the pointer enters in an
area that falls under the control of a layout, to which this tool is attached to.
 
This method is also called for the new active tool on -setActiveTool:.
 
You must call the superclass implementation if you override this method. */
- (void) didBecomeActive
{
	ETDebugLog(@"Tool %@ did become active", self);
}

/** <override-dummy />
Called when the tool becomes inactive, usually when the pointer exists the
area that falls under the control of a layout, to which this tool is attached to.
 
This method is also called for the previous active tool on -setActiveTool:.
 
You must call the superclass implementation if you override this method. */
- (void) didBecomeInactive
{
	ETDebugLog(@"Tool %@ did become inactive", self);
}

/** <override-dummy />
Returns whether the tool should considered activatable by 
+activatableToolForItem:.

You must call the superclass implementation if you override this method, and 
test whether the superclass implementation returns NO, and return NO in this case.  */
- (BOOL) shouldActivateTool: (ETTool *)foundTool attachedToItem: (ETLayoutItem *)anItem
{
	/* Don't activate tool bound to a widget layout (see also +setActiveTool:) */
	return (foundTool != nil && [[foundTool layoutOwner] isWidget] == NO);
}

#pragma mark Hit Test -

/** Returns the root item that -hitTestWithEvent: is expected to return when 
the mouse is not within in a window area. For now, return -windowGroup as 
-[ETApplication layoutItem] does. */
- (ETLayoutItem *) hitItemForNil
{
	return [[ETLayoutItemFactory factory] windowGroup];
}

/** Returns the layout item hovered at the mouse location reported by anEvent.

Never returns nil. If the mouse isn't over a window, the layout item that 
plays the role of the local root item is returned. If the mouse is over a 
window whose content view isn't bound to a layout item, then this window is 
ignored and the local root item is also returned. */
- (ETLayoutItem *) hitTestWithEvent: (ETEvent *)anEvent
{
	ETLayoutItem *testedItem = [[anEvent contentItem] firstDecoratedItem];
	ETLayoutItem *rootItem = [self hitItemForNil];
	BOOL isOutsideItem = (testedItem != nil 
		&& NSMouseInRect([anEvent location], [testedItem frame], [rootItem isFlipped]) == NO);
	BOOL hitImplicitWindowGroup = (testedItem == nil || isOutsideItem);

	/* Mouse is not over a window or the content view is not a ETView object */
	if (hitImplicitWindowGroup)
	{
		[anEvent setLayoutItem: rootItem];
		[anEvent setLocationInLayoutItem: [anEvent location]];
		return rootItem;
	}

	ETLayoutItem *hitItem = [[anEvent windowItem] hitTestFieldEditorWithEvent: anEvent];
	if (hitItem != nil)
	{
		return hitItem;
	}

	NSPoint windowItemRelativePoint = [anEvent locationInWindowItem];

	hitItem = [self hitTest: windowItemRelativePoint
	              withEvent: anEvent
	                 inItem: (ETLayoutItemGroup *)testedItem];
	[anEvent setLayoutItem: hitItem];

	/* Fall back when the tested item has no action handler */
	if (hitItem == nil && [testedItem acceptsActions] == NO)
	{
		hitItem = rootItem;
		[anEvent setLayoutItem: hitItem];
		[anEvent setLocationInLayoutItem: [anEvent location]];
	}

	ETAssert(hitItem != nil && [anEvent layoutItem] == hitItem);

	return hitItem;
}

/* Does the hit test in:
- explicit children when the item is an ETLayoutItemGroup
- implicit children when the item has a layout (both ETLayoutItem and 
ETLayoutItemGroup can use a layout)

Explicit children are the usual children returned by -[ETLayoutItemGroup items]. 
Implicit children are the children hidden in the layout which are returned by 
[[[anItem layout] layerItem] items].

For the hit test phase, at each recursion level in the layout item tree, both 
-hitTest:withEvent:inItem: and -hitTest:withEvent:inChildrenOfItem: are entered.
Hence whether or not the item has children, this method will be called. */
- (ETLayoutItem *) hitTest: (NSPoint)itemRelativePoint 
                 withEvent: (ETEvent *)anEvent 
          inChildrenOfItem: (ETLayoutItem *)anItem
{
	NSPoint pointInParentContent = [anItem convertRectToContent: ETMakeRect(itemRelativePoint, NSZeroSize)].origin;

	/* Hit in implicit children (owned by the layout)

	   NOTE: We currently expect -[ETLayout layerItem] to have the same frame
	   than anItem. */
	ETLayoutItem *hitItem = [self hitTest: pointInParentContent
                                withEvent: anEvent
	                               inItem: [[anItem layout] layerItem]];
	if (hitItem != nil)
		return hitItem;

	/* Force return when either: 
	   - the item cannot have explicit children
	   - the layout doesn't reuse the children geometry and provides a 
	     completely standalone presentation 
	
	   NOTE: An item without a layout is not opaque. */
	BOOL isOpaqueItem = ([anItem isGroup] == NO || 
		([anItem layout] != nil && [[anItem layout] isOpaque]));
	
	if (isOpaqueItem)
		return anItem;

	/* Hit in explicit children */
	FOREACH([(ETLayoutItemGroup *)anItem items], childItem, ETLayoutItem *)
	{
		NSPoint childRelativePoint = [childItem convertPointFromParent: pointInParentContent];
		BOOL isInside = [childItem pointInside: childRelativePoint useBoundingBox: YES];

		if (isInside) /* Traverse the subtree */
		{
			hitItem = [self hitTest: childRelativePoint
			              withEvent: anEvent 
			                 inItem: childItem];
		}

		if (hitItem != nil)
			return hitItem;
	}
	
	return anItem;
}

/* For debugging, see -hitTestWithEvent:inItem: */
- (void) logEvent: (ETEvent *)anEvent ofType: (NSEventType)evtType atPoint: (NSPoint)aPoint inItem: (ETLayoutItem *)anItem
{
	if ([anEvent type] != evtType)
		return;

	ETUIItem *decorator = [anItem decoratorItemAtPoint: aPoint];
	BOOL isInside = [anItem pointInside: aPoint useBoundingBox: ([anItem windowItem] == nil)];

	ETLog(@"Will try hit test at %@, decorator %@, isInside %d in %@", 
		NSStringFromPoint(aPoint), [decorator primitiveDescription], isInside, anItem);
}

// TODO: Benchmark this method. If it proves to be bottleneck, optimize. 
// Handles the dispatch on the decorator chain, probably by adding -contentRect
// to ETLayoutItem and verifying whether itemRelativePoint is contained in the 
// content rest
- (ETLayoutItem *) hitTest: (NSPoint)itemRelativePoint 
                 withEvent: (ETEvent *)anEvent 
				    inItem: (ETLayoutItem *)anItem
{
	if (anItem == nil)
		return nil;

	BOOL useBoundingBox = ([anItem windowItem] == nil);
	BOOL isOutside = ([anItem pointInside: itemRelativePoint useBoundingBox: useBoundingBox] == NO);
	
	if (isOutside)
		return nil;

	NSPoint hitItemRelativePoint = itemRelativePoint;
	ETLayoutItem *hitItem = [self willHitTest: itemRelativePoint
	                                withEvent: anEvent
	                                   inItem: anItem
	                              newLocation: &hitItemRelativePoint];

	// NOTE: The next block could eventually be put in -willHitTest:XXX
	// The current choice makes harder to wrongly override the method and 
	// newLocation: acts as an explicit hint to update the event location.
	if (hitItem != nil && [hitItem acceptsActions])
	{
		[anEvent setLayoutItem: hitItem];
		[anEvent setLocationInLayoutItem: hitItemRelativePoint];
	}

	/* When -decoratorItemAtPoint: returns nil, the hit lies within the extended 
	   bounding box area and is outside the layout item frame. */
	ETUIItem *decorator = [hitItem decoratorItemAtPoint: hitItemRelativePoint];
	BOOL isInsideContent = (decorator == hitItem);
	BOOL isInsideActionArea = (isInsideContent || ([hitItem isGroup] && 
		[(ETLayoutItemGroup *)hitItem acceptsActionsForItemsOutsideOfFrame]));
	BOOL hitTestCustomized = (hitItem != anItem);
	BOOL shouldContinue = ([self shouldContinueHitTest: itemRelativePoint 
	                                      withEvent: anEvent 
	                                         inItem: hitItem 
	                                    wasReplaced: hitTestCustomized]);

	if (shouldContinue && isInsideActionArea)
	{
		hitItem = [self hitTest: itemRelativePoint 
		              withEvent: anEvent 
		       inChildrenOfItem: hitItem];
	}

	return ([hitItem acceptsActions] ? hitItem : (ETLayoutItem *)nil);
	// NOTE: We could eventually prevent the hit test success with 
	// [anItem acceptsActions] && [anItem pointInside: itemRelativePoint] and 
	// bypass the hit test in the entire item tree connected to an item.
	// However because -[ETFreeLayout layerItem] has no action handler, 
	// -acceptsActions returns NO and prevents handle hit test. The best choice 
	// is either doesn't use -acceptActions with hit test phase or introduce 
	// an ETNullActionHandler, so -acceptsActions can return YES for the root 
	// item in a composite layout (such as ETFreeLayout).
}

/** Overrides to implement your own hit test strategy that prevents 
-hitTest:withEvent:inItem: to be run and handle the hit test in anItem, by
returning a custom item or nil. 

By default, returns anItem and -hitTest:withEvent:inItem: continues to procede 
as usual. */
- (ETLayoutItem *) willHitTest: (NSPoint)itemRelativePoint 
                     withEvent: (ETEvent *)anEvent 
				        inItem: (ETLayoutItem *)anItem
                   newLocation: (NSPoint *)returnedItemRelativePoint
{
	return anItem;
}

/** By default, returns YES, unless wasItemReplaced is YES because 
-willHitTest:withEvent:inItem: has returned a custom item, in that case returns 
NO. */
- (BOOL) shouldContinueHitTest: (NSPoint)itemRelativePoint 
                     withEvent: (ETEvent *)anEvent 
				        inItem: (ETLayoutItem *)anItem
				   wasReplaced: (BOOL)wasItemReplaced
{
	return (wasItemReplaced == NO);
}

#pragma mark Event Handlers Requests -

- (void) trySendEventToWidgetView: (ETEvent *)anEvent
{
	ETLayoutItem *item = [self hitTestWithEvent: anEvent];
	BOOL backendHandled = [[ETEventProcessor sharedInstance] trySendEvent: anEvent
													   toWidgetViewOfItem: item];

	if (backendHandled)
		[anEvent markAsDelivered];
}

- (BOOL) tryActivateItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent
{
	ETLayoutItem *itemToActivate = (item != nil ? item : (ETLayoutItem *)[[anEvent contentItem] firstDecoratedItem]);
	BOOL isActivateEvent = (itemToActivate != [ETApp keyItem]);

	if (isActivateEvent)
		[anEvent markAsDelivered];

	return [[ETEventProcessor sharedInstance] tryActivateItem: item withEvent: anEvent];
}

- (BOOL) tryRemoveFieldEditorItemWithEvent: (ETEvent *)anEvent
{
	ETWindowItem *windowItem = [anEvent windowItem];

	if ([windowItem activeFieldEditorItem] == nil)
		return NO;

	[windowItem removeActiveFieldEditorItem];
	return YES;
}

- (BOOL) performKeyEquivalent: (ETEvent *)anEvent inItem: (ETLayoutItem *)item
{
	if ([[item actionHandler] handleKeyEquivalent: anEvent onItem: item]
		|| [[item view] performKeyEquivalent: (NSEvent *)[anEvent backendEvent]])
	{
		return YES;
	}

	if ([item isGroup] == NO)
		return NO;

	FOREACH([(ETLayoutItemGroup *)item items], childItem, ETLayoutItem *)
	{
		if ([self performKeyEquivalent: anEvent inItem: childItem])
			return YES;
	}

	return NO;
}

- (BOOL) performKeyEquivalent: (ETEvent *)anEvent
{
	BOOL isHandled = [self performKeyEquivalent: anEvent inItem: [ETApp keyItem]];

	if (isHandled)
		return YES;

	return [[ETApp mainMenu] performKeyEquivalent: (NSEvent *)[anEvent backendEvent]];
}

- (void) tryPerformKeyEquivalentAndSendKeyEvent: (ETEvent *)anEvent toResponder: (id)aResponder
{
	NSEventType type = [anEvent type]; // FIXME: Should be ETEventType

	if (type != NSKeyDown && type != NSKeyUp)
		return;

	if ([self performKeyEquivalent: anEvent])
		return;

	/* When the responder is tool, we are usually invoked by [ETTool keyDown/Up:].
	   We only got the key equivalent to check, because the event has already 
	   been dispatched on the tool. */
	if ([aResponder isTool])
		return;

	if ([aResponder isLayoutItem])
	{
		if (type == NSKeyDown)
		{
			[[aResponder actionHandler] handleKeyDown: anEvent onItem: aResponder];
		}
		else
		{
			[[aResponder actionHandler] handleKeyUp: anEvent onItem: aResponder];
		}
	}
	else /* For views and other AppKit responders */
	{
		if (type == NSKeyDown)
		{
			[aResponder keyDown: (NSEvent *)[anEvent backendEvent]];
		}
		else
		{
			[aResponder keyUp: (NSEvent *)[anEvent backendEvent]];
		}
	}
}

#pragma mark Event Handlers -

- (void) mouseDown: (ETEvent *)anEvent
{
	[self tryActivateItem: nil withEvent: anEvent];
	[self trySendEventToWidgetView: anEvent];
	if ([anEvent wasDelivered])
	{
		return;
	}
	/* The field editor has not received the event with -trySendEventToWidgetView:, 
	   the event is not directed towards it. */
	[self tryRemoveFieldEditorItemWithEvent: anEvent];
}

- (void) mouseUp: (ETEvent *)anEvent
{
	[self trySendEventToWidgetView: anEvent];
}

- (void) mouseDragged: (ETEvent *)anEvent
{
	[self trySendEventToWidgetView: anEvent];
}

/** Does nothing by default. */
- (void) mouseMoved: (ETEvent *)anEvent
{

}

- (void) mouseEntered: (ETEvent *)anEvent
{
	/* Don't redo the hit test done in -_mouseMoved. */
	[[[anEvent layoutItem] actionHandler] handleEnterItem: [anEvent layoutItem]];
}

- (void) mouseExited: (ETEvent *)anEvent
{
	/* Don't redo the hit test done in -_mouseMoved. */
	[[[anEvent layoutItem] actionHandler] handleExitItem: [anEvent layoutItem]];
}

- (void) mouseEnteredChild: (ETEvent *)anEvent
{
	ETLayoutItem *item = [anEvent layoutItem];

	[[[item parentItem] actionHandler] handleEnterChildItem: item];
}

- (void) mouseExitedChild: (ETEvent *)anEvent
{
	ETLayoutItem *item = [anEvent layoutItem];

	[[[item parentItem] actionHandler] handleExitChildItem: item];
}

- (void) keyDown: (ETEvent *)anEvent
{
	// FIXME: Don't retrieve the backend responder. The backend responder should
	// be retrieved in -tryPerformKeyEquivalentAndSendKeyEvent:toResponder:
	id firstResponder = [[(id)[[ETApp keyItem] firstResponderSharingArea] window] firstResponder];
	[self tryPerformKeyEquivalentAndSendKeyEvent: anEvent toResponder: firstResponder];
}

- (void) keyUp: (ETEvent *)anEvent
{
	// FIXME: Don't retrieve the backend responder. The backend responder should
	// be retrieved in -tryPerformKeyEquivalentAndSendKeyEvent:toResponder:
	id firstResponder = [[(id)[[ETApp keyItem] firstResponderSharingArea] window] firstResponder];
	[self tryPerformKeyEquivalentAndSendKeyEvent: anEvent toResponder: firstResponder];
}

#pragma mark Cursor -

/** Sets the name of the cursor that represents the receiver.

This name is used to look up the cursor replacing the previous active tool 
cursor, when the receiver becomes activated. */
- (void) setCursorName: (NSString *)aName
{
	[self willChangeValueForProperty: @"cursorName"];
	_cursorName = aName;
	[self didChangeValueForProperty: @"cursorName"];
}

/** Returns the name of the cursor that represents the receiver.

See also -setCursor:. */
- (NSString *) cursorName
{
	return _cursorName;
}


/** Returns the cursor that represents the receiver. */
- (NSCursor *) cursor
{
	SEL factoryMethodSel = NSSelectorFromString([self cursorName]);

	if ([NSCursor respondsToSelector: factoryMethodSel] == NO)
	{
		[NSException raise: NSInternalInconsistencyException
		            format: @"Unsupported cursor name %@", [self cursorName]];
	}
	return [NSCursor performSelector: factoryMethodSel];
}

#pragma mark UI Utility -

/** Shows a palette which lists all the registered tools. 

The palette is a layout item whose represented object is the ETTool class
object. */
+ (void) show: (id)sender
{
	// FIXME: Implement
}

/** Returns a menu that can be used to configure the receiver behavior. */
- (NSMenu *) menuRepresentation
{
	return nil;
}

@end

NSString * const kETToolCursorNameArrow = @"arrowCursor";
NSString * const kETToolCursorNameOpenHand = @"openHandCursor";
NSString * const kETToolCursorNamePointingHand = @"pointingHandCursor";
