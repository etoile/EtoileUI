/*  <title>ETActionHandler</title>

	<abstract>The EtoileUI event handling model for the layout item tree. Also 
	defines the Pick and Drop model.</abstract>

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// WARNING: Unstable API.

@class ETUTI;
@class ETEvent, ETLayoutItem, ETPickboard, ETPickDropCoordinator;
@protocol ETKeyInputAction, ETTouchAction;

/** Action handler are lightweight objects whose instances can be shared between 
a large number of layout items.
 
The same action handler is automatically set on every new layout item 
instances. You can override it by calling -[ETLayoutItem setActionHandler:].
For example, ETActionHandler can be subclassed to handle the paint 
action in your own way: you might want to alter objects or properties bound
to the layout item  and not just the style object as the base class does. 

For an ETActionHandler subclass, you usually use a single shared instance 
accross all the layout items to which it is bound. To do so, a possibility 
is to write a factory method to build your layout items, this factory 
method will reuse the action handler to be set on every created items. */
@interface ETActionHandler : NSObject
{
	ETLayoutItem *_fieldEditorItem;
	ETLayoutItem *_editedItem;
	BOOL _wasFieldEditorParentModelMutator;
}

+ (Class) styleClass;

+ (id) sharedInstance;

/* Text Editing */

- (ETLayoutItem *) fieldEditorItem;
- (void) setFieldEditorItem: (ETLayoutItem *)anItem;
- (void) beginEditingItem: (ETLayoutItem *)item 
                 property: (NSString *)property
                   inRect: (NSRect)fieldEditorFrame;
- (void) endEditingItem;

/* Instrument/Tool Actions */

- (void) handleClickItem: (ETLayoutItem *)item;
- (void) handleDoubleClickItem: (ETLayoutItem *)item;
- (void) handleDragItem: (ETLayoutItem *)item byDelta: (NSSize)delta;
- (void) handleTranslateItem: (ETLayoutItem *)item byDelta: (NSSize)delta;
- (void) handleEnterItem: (ETLayoutItem *)item;
- (void) handleExitItem: (ETLayoutItem *)item;
- (void) handleEnterChildItem: (ETLayoutItem *)childItem;
- (void) handleExitChildItem: (ETLayoutItem *)childItem;

/* Key Actions */

- (BOOL) handleKeyEquivalent: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item;
- (void) handleKeyUp: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item;
- (void) handleKeyDown: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item;

/* Touch Tracking Actions */

- (BOOL) handleBeginTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item;
- (void) handleContinueTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item;
- (void) handleEndTouch: (id <ETTouchAction>)aTouch onItem: (ETLayoutItem *)item;

/* Select Actions */

//ETSelectTool produced actions.
//-canSelectIndexes:onItem:
//-selectIndexes:onItem:
- (BOOL) canSelect: (ETLayoutItem *)item;
- (void) handleSelect: (ETLayoutItem *)item;
- (BOOL) canDeselect: (ETLayoutItem *)item;
- (void) handleDeselect: (ETLayoutItem *)item;

/* Generic Actions */

- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;
- (BOOL) acceptsFirstMouse;

- (void) sendBackward: (id)sender onItem: (ETLayoutItem *)item;
- (void) sendToBack: (id)sender onItem: (ETLayoutItem *)item;
- (void) bringForward: (id)sender onItem: (ETLayoutItem *)item;
- (void) bringToFront: (id)sender onItem: (ETLayoutItem *)item;

@end


@interface ETButtonItemActionHandler : ETActionHandler
{

}

+ (Class) styleClass;

@end
