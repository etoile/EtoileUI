/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETUIObject.h>

@class ETLayoutItem;

/** Protocol to declare an area where the first responder status is shared.
 
If a class adopts this protocol, its instances represent UI areas that 
coordinate the field editor use to ensure the first responder status is given to 
a single object in each area.
 
ETUIItem subclasses can implement this protocol. 
 
You shouldn't need to implement this protocol unless you implement a new 
ETDecoratorItem subclass similar to ETWindowItem. */
@protocol ETFirstResponderSharingArea <NSObject>
- (ETLayoutItem *) activeFieldEditorItem;
- (ETLayoutItem *) editedItem;
- (void) setActiveFieldEditorItem: (ETLayoutItem *)editorItem 
                       editedItem: (ETLayoutItem *)editedItem;
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
- (void) didBecomeFirstResponder: (id)aResponder;
- (void) didResignFirstResponder: (id)aResponder;
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
@protocol ETResponder

/** @taskunit Responder Chain */

/** See -[ETResponderTrait nextResponder]. */
- (id) nextResponder;

/** @taskunit Coordinating User Interaction */

/** See -[ETResponderTrait firstResponderSharingArea]. */
- (id <ETFirstResponderSharingArea>) firstResponderSharingArea;
/** See -[ETResponderTrait editionCoordinator]. */
- (id <ETEditionCoordinator>) editionCoordinator;
@end

/** A trait providing a basic implementation for all ETResponder methods.
 
To override a ETResponderTrait method, just implement it in the target class
to which the trait is applied. */
@interface ETResponderTrait : NSObject
{
	
}

/** @taskunit Responder Chain */

- (id) nextResponder;

/** @taskunit Coordinating User Interaction */

- (id <ETFirstResponderSharingArea>) firstResponderSharingArea;
- (id <ETEditionCoordinator>) editionCoordinator;

@end
