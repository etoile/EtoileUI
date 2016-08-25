/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETUIObject.h>

@class ETLayoutItem;
@protocol ETResponder;

/** Protocol to declare an area where the first responder status is shared.
 
If a class adopts this protocol, its instances represent UI areas that 
coordinate the field editor use to ensure the first responder status is given to 
a single object in each area.

For a desktop environment using windows, the first responder sharing area 
is a ETWindowItem (usually backed by a window provided by the widget backend).
 
ETUIItem subclasses can implement this protocol. 
 
You shouldn't need to implement this protocol unless you implement a new 
ETDecoratorItem subclass similar to ETWindowItem. */
@protocol ETFirstResponderSharingArea <NSObject>
/** Returns the object thas the focus from the framework standpoint.

See also -firstResponder and -focusedItem. */
- (BOOL) makeFirstResponder: (id <ETResponder>)newResponder;
/** Returns the object thas the focus from the framework standpoint.

The first responder is the current responder where the action dispatch starts in 
the EtoileUI responder chain.

See -focusedItem and -makeFirstResponder:. */
@property (nonatomic, readonly) id<ETResponder> firstResponder;
/** Returns the item that currently has the focus from the user standpoint.

For example, if you edit a text area, the first responder is -fieldEditorItem, 
but the focused item is the edited text area item (usually -editedItem). 
Another example would be, if an item group bound to a select tool is made the 
first responder, it doesn't become the first responder but the focused item, 
while the select tool becomes the first responder (the select tool next 
responder will be the item group that owns it).

For a focused item using a widget layout, -firstResponder and -focusedItem are 
points to the same item group (the one owning the widget layout). Descendant 
items that represent rows don't become focused items in this case.

You can track focused item changes using ETEditionCoordinator protocol.

See also -firstResponder. */
@property (nonatomic, readonly) ETLayoutItem *focusedItem;
/** Returns the item that serves as a field editor in the item tree presently.

When no editing is underway, returns nil.

See -firstResponder. */
@property (nonatomic, readonly) ETLayoutItem *activeFieldEditorItem;
/** Returns the item whose subject is currently edited.

The edited item is usually an item representing a model object whose content 
or properties have begun being edited using 
-[ETActionHandler beginEditingItem:property:inRect:].

If the edited value is presented in a text view (or text field), the edited item 
doesn't always represent the item that owns this text view, but can be another  
item used to present the value elswhere in the UI.
 
When no editing is underway, returns nil. */
@property (nonatomic, readonly) ETLayoutItem *editedItem;
/** Inserts the item that serves field editor into the item tree at the 
beginning of the editing targeting the given edited item.
 
See -[ETActionHandler beginEditingItem:property:inRect:]. */
- (void) setActiveFieldEditorItem: (ETLayoutItem *)editorItem 
                       editedItem: (ETLayoutItem *)editedItem;
/** Removes the item that serves as field editor from the item tree at the 
end of the editing.
 
See -[ETActionHandler endEditingItem:]. */
- (void) removeActiveFieldEditorItem;
@end

/** Protocol to declare a controller as an edition coordinator.
 
If a class adopts this protocol, its instances are bound to UI areas that
act as reusable UI components.
 
An edition coordinator tracks the first responder changes in the area it manages 
but ignores similar changes in areas controlled by other editor coordinators 
(higher or lower in the layout item tree).
 
Your ETController subclasses can implement this protocol. */
@protocol ETEditionCoordinator <NSObject>
- (void) didBecomeFocusedItem: (ETLayoutItem *)anItem;
- (void) didResignFocusedItem: (ETLayoutItem *)anItem;
@end

/** Protocol to declare an object as a responder.

A responder is an object that can respond to actions emitted by the active 
tool and dispatched in the layout tem tree.

An action targeting the responder chain (by providing a nil target) is 
dispatched as explained in -[ETApplication targetForAction:from:to:].
 
A responder usually belongs to a responder chain through the object returned by 
-nextResponder.
 
In addition, a responder provides access to special objects coordinating 
interaction among multiple UI objects present in their area. See
-firstResponderSharingArea and -editionCoordinator. */
@protocol ETResponder <NSObject>

/** @taskunit Responder Chain */

/** See -[ETResponderTrait nextResponder]. */
@property (nonatomic, readonly) id nextResponder;

/** @taskunit Coordinating User Interaction */

/** See -[ETResponderTrait firstResponderSharingArea]. */
@property (nonatomic, readonly) id<ETFirstResponderSharingArea> firstResponderSharingArea;
/** See -[ETResponderTrait editionCoordinator]. */
@property (nonatomic, readonly) id<ETEditionCoordinator> editionCoordinator;
/** This method is only exposed to be used internally by Etoile. For reacting to 
focused item changes, use ETEditionCoordinator.
 
From the user standpoint, returns the item that accepts the focus in the 
responder chain.
 
The returned item must be identical to the receiver or encloses it in the item 
tree. */
@property (nonatomic, readonly) ETLayoutItem *candidateFocusedItem;

@end

/** A trait providing a basic implementation for all ETResponder methods.
 
To override a ETResponderTrait method, just implement it in the target class
to which the trait is applied. */
@interface ETResponderTrait : NSObject
{
	
}

/** @taskunit Responder Chain */

@property (nonatomic, readonly, strong) id nextResponder;

/** @taskunit Coordinating User Interaction */

@property (nonatomic, readonly, strong) id<ETFirstResponderSharingArea> firstResponderSharingArea;
@property (nonatomic, readonly, strong) id<ETEditionCoordinator> editionCoordinator;

@end
