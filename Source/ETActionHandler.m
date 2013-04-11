/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETPropertyViewpoint.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETActionHandler.h"
#import "ETApplication.h"
#import "ETBasicItemStyle.h"
#import "ETEvent.h"
#import "ETGeometry.h"
#import "ETTool.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETResponder.h"
#import "EtoileUIProperties.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"


@implementation ETActionHandler

/** <override-dummy />
Returns the style class that can be used together with the receiver class.

Action handler and style very often exist as a class pair whose instances are 
thought to be used together.

Returns Nil by default. */
+ (Class) styleClass
{
	return Nil;
}

static NSMutableDictionary *sharedActionHandlers = nil;

+ (id) sharedInstance
{
	if (sharedActionHandlers == nil)
		sharedActionHandlers = [[NSMutableDictionary alloc] init];

	NSString *className = NSStringFromClass(self);
	id handler = [sharedActionHandlers objectForKey: className];
	if (handler == nil)
	{
		handler = AUTORELEASE([[self alloc] init]);
		[sharedActionHandlers setObject: handler
		                         forKey: className];
	}

	ETAssert([handler isPersistent] == NO);
	return handler;
}

/** Initializes and returns a new action handler. */
- (id) init
{
	SUPERINIT
	return self;
}

- (void) dealloc
{
	// TODO: Think whether we should really destroy the edited item or simply 
	// expect it to be nil.
	if (nil != _editedItem)
	{
		[self endEditingItem: _editedItem];
	}
	DESTROY(_fieldEditorItem);
	[super dealloc];
}

static NSResponder *sharedFallbackResponder = nil;

+ (id) sharedFallbackResponder
{
	if (sharedFallbackResponder == nil)
	{
		sharedFallbackResponder = [NSResponder new];
	}
	return sharedFallbackResponder;
}

- (BOOL) respondsToSelector: (SEL)aSelector
{
	if ([super respondsToSelector: aSelector])
		return YES;
	
	if ([[ETActionHandler sharedFallbackResponder] respondsToSelector: aSelector])
		return YES;

	return NO;
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL)aSelector
{
	NSMethodSignature *sig = [super methodSignatureForSelector: aSelector];
	
	if (sig == nil)
	{
		sig = [[ETActionHandler sharedFallbackResponder] methodSignatureForSelector: aSelector];
	}
	
	return sig;
}

- (void) forwardInvocation: (NSInvocation *)inv
{
	SEL selector = [inv selector];

	if ([self respondsToSelector: selector] == NO)
	{
		[self doesNotRecognizeSelector: selector];
		return;
	}

	[inv invokeWithTarget: [ETActionHandler sharedFallbackResponder]];
}

/** Returns YES to indicate the receiver can be shared between several owners.

See also -[ETUIObject isShared]. */
- (BOOL) isShared
{
	return YES;
}

/* Editing */

/** <override-dummy />
Makes the item view the first responder or the item itself when there is no view. */
- (void) beginEditingForItem: (ETLayoutItem *)item
{
	id newFirstResponder = ([item view] != nil ? (id)[item view] : (id)item);
	[[[item view] window] makeFirstResponder: newFirstResponder];
}

/** <override-dummy />
Discards any pending changes in the item view or its enclosing layout view. */
- (void) discardEditingForItem: (ETLayoutItem *)item
{
	id layoutView = [[[item ancestorItemForOpaqueLayout] layout] layoutView];

	if (layoutView != nil)
	{
		[[layoutView ifResponds] discardEditing];	
	}
	else
	{
		[[[item view] ifResponds] discardEditing];
	}
}

/** <override-dummy />
Tries to commit any pending changes in the item view or its enclosing layout view.

Always returns YES when the item has no view. */
- (BOOL) commitEditingForItem: (ETLayoutItem *)item
{
	id layoutView = [[[item ancestorItemForOpaqueLayout] layout] layoutView];

	if (layoutView != nil && [layoutView respondsToSelector: @selector(commitEditing)])
	{
		return [layoutView commitEditing];
	}
	else if ([[item view] respondsToSelector: @selector(commitEditing)])
	{
		return [[item view] commitEditing];
	}
	else
	{
		return YES;
	}
}

/* Text Editing */

- (NSFont *) defaultFieldEditorFont
{
	return [NSFont systemFontOfSize: [NSFont smallSystemFontSize]];
}

/** Returns a reusable item with a transparent text view as its view.

This text view is dedicated to text editing in a reusable way.

This item can be reused every time editing a property is needed in reaction to 
an action. See -beginEditingItem:property:inRect:. */
- (ETLayoutItem *) fieldEditorItem
{
	/* Lazily initialization is required, otherwise -textField reenters -init 
	   with +sharedInstance */
	if (nil == _fieldEditorItem)
	{
		NSTextView *fieldEditor = AUTORELEASE([[NSTextView alloc] initWithFrame: [ETLayoutItem defaultItemRect]]);
		
		[fieldEditor setFocusRingType: NSFocusRingTypeExterior];
		[fieldEditor setFont: [self defaultFieldEditorFont]];
		[fieldEditor setDrawsBackground: YES];
		[fieldEditor setEditable: YES];
		[fieldEditor setFieldEditor: YES];
		[fieldEditor setSelectable: YES];
		[fieldEditor setRichText: NO];
		[fieldEditor setImportsGraphics: NO];
		[fieldEditor setUsesFontPanel: NO];
		[fieldEditor setAllowsUndo: YES];

		_fieldEditorItem = [[ETLayoutItemFactory factory] itemWithView: fieldEditor];
		[_fieldEditorItem setCoverStyle: [ETFieldEditorItemStyle sharedInstance]];
	}

	return _fieldEditorItem;
}

/** Sets the item to be used in the field editor role. 

See also -fieldEditorItem. */
- (void) setFieldEditorItem: (ETLayoutItem *)anItem
{
	ASSIGN(_fieldEditorItem, anItem);
}

- (NSFont *) fontForEditingItem: (ETLayoutItem *)anItem
{
	NSFont *font = [[[anItem view] ifResponds] font];

	if (nil == font)
	{
		font = [self defaultFieldEditorFont];
	}

	return font;
}

/** Starts a text editing session in the given rect.

This method prepares the field editor item with the property value returned by 
the provided item, then inserts it in the window backed ancestor item where 
the item is located.

To end the text editing, invoke -endEditingItem.<br />
Which actions begins and ends the text editing is up to you. */
- (void) beginEditingItem: (ETLayoutItem *)item 
                 property: (NSString *)property 
                   inRect: (NSRect)fieldEditorRect
{
	id <ETFirstResponderSharingArea> responderArea = [item firstResponderSharingArea];

	if (nil == responderArea)
	{
		ETLog(@"WARNING: Found no first responder sharing area to edit %@", item);
		return;
	}

	ETLayoutItem *fieldEditorItem = [self fieldEditorItem];

	ETAssert(nil != fieldEditorItem);

	ETLayoutItemGroup *windowBackedItem = [item windowBackedAncestorItem];
	NSRect fieldEditorFrame = [item convertRect: fieldEditorRect toItem: windowBackedItem];
	NSTextView *fieldEditor = (NSTextView *)[fieldEditorItem view];
	// TODO: Handle non-editable properties more in a better way
	NSString *value = [[[item subject] valueForProperty: property] stringValue];
	NSString *formattedValue = @"Untitled";
	
	if (nil != value)
	{
		formattedValue = value;
	}

	// TODO: Use -bindXXX
	[fieldEditor setString: formattedValue];
	[fieldEditor setFont: [self fontForEditingItem: item]];
	[fieldEditor setDelegate: (id)self];
	[fieldEditorItem setFrame: fieldEditorFrame];
	[fieldEditorItem setRepresentedObject: [ETPropertyViewpoint viewpointWithName: property 
	                                                            representedObject: [item subject]]];
	[responderArea setActiveFieldEditorItem: fieldEditorItem
	                             editedItem: item];

	ASSIGN(_editedItem, item);
}

/** Ends the text editing started with -beginEditingItem:property:inRect: and 
removes the field editor item inserted in the window backed ancestor item. */
- (void) endEditingItem: (ETLayoutItem *)editedItem
{
	if (nil == _editedItem)
		return;

	id <ETFirstResponderSharingArea> responderArea = [_editedItem firstResponderSharingArea];

	if (nil == responderArea)
	{
		ETLog(@"WARNING: Found no first responder sharing area to edit %@", _editedItem);
		return;
	}

	[responderArea removeActiveFieldEditorItem];

	DESTROY(_editedItem);
}

/** When -beginEditingItem:property:inRect: was called, this method is invoked 
each time the text editing can end, because a control character such newline or 
tab was typed.
 
By default, the implementation calls -endEditingItem: on NSReturnTextMovement. 
For NSTabTextMovement and NSBackTabTextMovement, the first responder is passed 
to the next or previous key view. See ETFirstResponderSharingArea.
 
If the AppKit manages the text editing (NSControl used as an item view),
this method is not invoked, the delegate method is called directly on the 
NSControl or NSTextField. */
- (void) textDidEndEditing: (NSNotification *)aNotification
{
	ETAssert(_editedItem != nil);

	NSInteger movement =
		[[[aNotification userInfo] objectForKey: @"NSTextMovement"] unsignedIntegerValue];
	
	if (movement == NSReturnTextMovement)
    {
		[self endEditingItem: _editedItem];
    }
	else if (movement == NSTabTextMovement)
	{
		// TODO: [[_editedItem firstResponderSharingArea] selectKeyViewFollowingView: self];
	}
	else if (movement == NSBacktabTextMovement)
	{
		// TODO: [[_editedItem firstResponderSharingArea] selectKeyViewPrecedingView: self];
    }
}

/* <override-dummy />
Makes the clicked item the first responder of the active tool.

Overrides this method when you want to customize how simple click are handled. */
- (void) handleClickItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint
{
	ETDebugLog(@"Click %@", item);
	[[ETTool activeTool] makeFirstResponder: (id)item];
}

/** <override-dummy />
Tries to send the double action bound to the controller item or the parent item. 
The parent item is used when double action is not set on the controller item. 

Each time a target can receive the action, the -doubleClickedItem property is 
updated on the controller item or the parent item, otherwise it is set to nil, 
then the action is sent.

Overrides this method when you want to customize how double-click are handled. */
- (void) handleDoubleClickItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Double click %@", item);

	ETLayoutItemGroup *itemGroup = [item parentItem];
	
	if ([[item controllerItem] doubleAction] != NULL)
	{
		itemGroup = [item controllerItem];
	}

	BOOL foundTarget = ([ETApp targetForAction: [itemGroup doubleAction] 
	                                        to: [itemGroup target]
	                                      from: itemGroup] != nil);
	if (foundTarget)
	{
		[itemGroup setValue: item forKey: kETDoubleClickedItemProperty];
	}
	else
	{
		[itemGroup setValue: nil forKey: kETDoubleClickedItemProperty];
	}
	
	[[ETApplication sharedApplication] sendAction: [itemGroup doubleAction] 
	                                           to: [itemGroup target] 
	                                         from: itemGroup];
}

- (void) handleDragItem: (ETLayoutItem *)item byDelta: (NSSize)delta
{
	ETDebugLog(@"Drag %@", item);
	[self handleTranslateItem: item byDelta: delta];
}

- (void) beginTranslateItem: (ETLayoutItem *)item
{

}

- (void) handleTranslateItem: (ETLayoutItem *)item byDelta: (NSSize)delta
{
	/* We don't want to relayout and redisplay the whole parent item */
	[ETLayoutItem disablesAutolayout];

	NSRect prevBoundingFrame = [item convertRectToParent: [item boundingBox]];

	[item setPosition: ETSumPointAndSize([item position], delta)];

	/* Compute and redisplay the translation area */
	NSRect newBoundingFrame = [item convertRectToParent: [item boundingBox]];
	NSRect dirtyRect = NSUnionRect(newBoundingFrame, prevBoundingFrame);
	[[item parentItem] setNeedsDisplayInRect: dirtyRect];
	[[item parentItem] displayIfNeeded];

	[ETLayoutItem enablesAutolayout];

	//ETLog(@"Translate dirty rect %@", NSStringFromRect(dirtyRect));
}

- (void) endTranslateItem: (ETLayoutItem *)item
{
	[item commitWithType: @"Item Move" shortDescription: @"Translated Item"];
}

/** <override-dummy />
Does nothing.

Overrides this method when you want to customize how enter are handled.<br />
You can use this method and -handleExitItem: to implement roll-over effect. */
- (void) handleEnterItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Enter %@", item);
}

/** <override-dummy />
Does nothing.

Overrides this method when you want to customize how exit are handled. */
- (void) handleExitItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Exit %@", item);
}

- (void) handleEnterChildItem: (ETLayoutItem *)childItem
{
	ETDebugLog(@"Exit child %@", childItem);
}

- (void) handleExitChildItem: (ETLayoutItem *)childItem
{
	ETDebugLog(@"Enter child %@", childItem);
}

/* Key Actions */

- (BOOL) handleKeyEquivalent: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item
{
	return NO;
}

- (void) handleKeyUp: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item
{
	// FIXME: -handleKeyUp: isn't declared anywhere...
	// [[item nextResponder] handleKeyUp: keyInput];
}

- (void) handleKeyDown: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item
{
	// FIXME: [[item nextResponder] handleKeyDown: keyInput];
}

/* Touch Tracking Actions */

/** <override-dummy />
Tells the receiver a touch begins at a location inside the given item.<br />
Does nothing by default and returns NO.

Overrides to return YES and initiate a tracking sequence which will make the 
active tool invokes -handleContinueTouch:atPoint:onItem: repeatedly (even 
when the touch moves outside the given item) and finally -handleEndTouch:onItem:. 

The point is expressed relative to the item received in parameter.

[aTouch layoutItem] is equal to the given item. */
- (BOOL) handleBeginTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item
{
	return NO;
}

/** <override-dummy /> 
Tells the receiver a touch initiated on the given item has moved to a new 
location.<br />
Does nothing by default.

Overrides to handle how the receiver reacts to each step in the tracking 
sequence motion.<br />
-handleEndTouch:onItem: is always invoked once the touch is released.

The point is expressed relative to the item received in parameter.<br />
For now, aPoint is not yet supported and is equal to ETNullPoint. */
- (void) handleContinueTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item
{

}

/** <override-dummy />
Tells the receiver a touch initiated on the given item has ended.<br />
Does nothing by default.

Overrides to handle how the receiver reacts to the touch release. This is the 
last step in the tracking sequence.

You can retrieve the item on which the touch has ended with [aTouch layoutItem]. 
The touch location related to this item can be retrieved with 
[aTouch locationInLayoutItem]. */
- (void) handleEndTouch: (id <ETTouchAction>)aTouch onItem: (ETLayoutItem *)item
{

}

/* Select Actions */

/** Returns whether item can be selected or not. 

By default returns YES, except when the item is a base item, then returns NO. */
- (BOOL) canSelect: (ETLayoutItem *)item
{
	//if ([item isBaseItem])
	//	return NO;

	return YES;
}

/** Sets the item as selected and marks it to be redisplayed. */
- (void) handleSelect: (ETLayoutItem *)item
{
	//ETLog(@"Select %@", item);
	[item setSelected: YES];
	[item setNeedsDisplay: YES];

	// TODO: Cache the selection in the controller if there is one
	//[[[item controllerItem] controller] addSelectedObject: item];
}

/** Returns whether item can be deselected or not. 

By default returns YES.

TODO: Problably remove, since it should be of any use and just adds complexity. */
- (BOOL) canDeselect: (ETLayoutItem *)item
{
	return YES;
}

/** Sets the item as not selected and marks it to be redisplayed. */
- (void) handleDeselect: (ETLayoutItem *)item
{
	//ETLog(@"Deselect %@", item);
	[item setSelected: NO];
	[item setNeedsDisplay: YES];

	// TODO: May be cache in the controller... 
	//[[[item controllerItem] controller] removeSelectedObject: item];
}

/* Generic Actions */

/** Overrides to return YES if you want that items to which the receiver is 
bound to can become first responder. By default, returns NO. */
- (BOOL) acceptsFirstResponder
{
	return YES;
}

/** Tells the receiver that the item to which it is bound is asked to become 
the first responder. Returns YES by default, to let the item become first 
responder.

Overrides to handle how the receiver or the item to which it is bound to, react 
to the first responder status (e.g. UI feedback).

Moreover this method can be used as a last chance to refuse this status. */
- (BOOL) becomeFirstResponder
{
	return YES;
}

/** Tells the receiver that the item to which it is bound is asked to hand  
on the first responder status. Returns YES by default, to let the item 
resigns from the first responder status.

Overrides to handle how the receiver or the item to which it is bound to, react  
to the loss of the first responder status (e.g. UI feedback).

Moreover this method can be used to prevent to hand over the first responder 
status, when others request it. */
- (BOOL) resignFirstResponder
{
	return YES;
}

- (BOOL) acceptsFirstMouse
{
	return NO;
}

- (void) insertRectangle: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = ([item isGroup] ? (ETLayoutItemGroup *)item : [item parentItem]);
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];

	[itemFactory setAspectProviderItem: parent];
	[parent addItem: [itemFactory rectangle]];
	[itemFactory setAspectProviderItem: nil];
	[item commitWithType: @"Item Insertion" shortDescription: @"Created Rectangle"];
}

- (void) sendBackward: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent firstItem]])
		return;

	int currentIndex = [parent indexOfItem: item];

	RETAIN(item);
	[item removeFromParent];
	[parent insertItem: item atIndex: currentIndex - 1];
	RELEASE(item);

	[item commitWithType: @"Item Reordering" shortDescription: @"Sent Item backward"];
}

- (void) sendToBack: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent firstItem]])
		return;

	RETAIN(item);
	[item removeFromParent];
	[parent insertItem: item atIndex: 0];
	RELEASE(item);

	[item commitWithType: @"Item Reordering" shortDescription: @"Sent Item to the back"];
}

- (void) bringForward: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent lastItem]])
		return;

	int currentIndex = [parent indexOfItem: item];

	RETAIN(item);
	[item removeFromParent];
	[parent insertItem: item atIndex: currentIndex + 1];
	RELEASE(item);

	[item commitWithType: @"Item Reordering" shortDescription: @"Bring Item forward"];
}

- (void) bringToFront: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent lastItem]])
		return;

	RETAIN(item);
	[item removeFromParent];
	[parent addItem: item];
	RELEASE(item);

	[item commitWithType: @"Item Reordering" shortDescription: @"Bring Item to the front"];
}

/** Invokes -inspect: action on the given item.

You should generally use this action in a 'Inspect' menu item rather than 
-inspect:, otherwise when the first responder is a view, the view is 
inspected and not the item that owns it. */
- (void) inspectItem: (id)sender onItem: (ETLayoutItem *)item
{
	[item inspect: sender];
}

@end


@implementation ETButtonItemActionHandler

/** Returns ETBasicItemStyle class. */
+ (Class) styleClass
{
	return NSClassFromString(@"ETBasicItemStyle");
}

- (BOOL) handleBeginTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item
{
	[item setSelected: YES];
	[item setNeedsDisplay: YES];
	return YES;
}

- (void) handleContinueTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item
{
	if ([item isEqual: [aTouch layoutItem]])
	{
		[item setSelected: YES];
		[item setNeedsDisplay: YES];
	}
	else
	{
		[item setSelected: NO];
		[item setNeedsDisplay: YES];	
	}
}

- (void) handleEndTouch: (id <ETTouchAction>)aTouch onItem: (ETLayoutItem *)item
{
	[item setSelected: NO];
	[item setNeedsDisplay: YES];

	if ([item isEqual: [aTouch layoutItem]])
	{
		BOOL foundTarget = ([ETApp targetForAction: [item action] 
	                                            to: [item target]
		                                      from: item] != nil);
		if (foundTarget)
		{
			[ETApp sendAction: [item action] 
			               to: [item target] 
			             from: item];
		}
	}
}

@end
