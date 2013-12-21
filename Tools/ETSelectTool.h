/**
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETMoveTool.h>

@class ETSelectionAreaItem;

/** @group Tools

@abstract An tool class which provides rich and customizable selection logic. 
ETSelectTool encapsulates selection behavior to make it reusable and uniform 
accross ETLayout subclasses.

Attached by default to ETFreeLayout.

The selection is stored directly in the layout item tree, each item has a 
selected property. This property is used by the item style to draw selection
visual indicator per item. Keeping the selection state in each item, also 
allows to carry the selection state when item tree are moved or copied into 
another tree. For example, by the mean of pick and drop.

In addition, the overall selection within an item tree under the control of a 
base item, is cached in the base item controller if one is set. This allows 
to retrieve the selection efficiently without traversing the entire tree 
structure. This ability is important in a photo view where thousands of 
pictures can be displayed at the same time.

Select tools with different settings may be bound to various layouts to be applied 
to the same item. However because the selection is cached in the controller 
and/or stored in the layout item tree, the selection is carried over even if the 
select tool instance currently active changed.

By default, ETSelectTool supports linear selection, in other words managing the 
selection in the immediate children of a single parent item. If you have a 
controller associated with it, it can manage hierarchical selection and perform 
a lot better with linear selection over a large number of items as explained 
earlier. 

If a parent item is controlled by another select tool object, the layout to 
which the select tool is attached won't be activated on mouse enter, because 
the select tool currently active (at parent level) will prevent it. If the 
child item is double-clicked, its select tool will get activated.

The selection tool is quite special because it only works by default on its 
immediate children and thereby isn't really inherited as other tools are 
usually. However you can retarget the item on which it acts on by setting a 
target item with -setTargetItem:.

The selection tool unlike the move tool (its superclass) produces drag actions 
and not translate actions usually, -shouldProduceTranslateActions is initialized 
to return NO.
*/
@interface ETSelectTool : ETMoveTool
{
	@private
	id _actionHandlerPrototype;
	ETSelectionAreaItem *_selectionAreaItem;
	BOOL _multipleSelectionAllowed;
	BOOL _emptySelectionAllowed;
	BOOL _removeItemsAtPickTime;
	BOOL _forcesItemPick;
	// NOTE: May be move up to ETArrowTool
	BOOL _newSelectionAreaUnderway;
	/** Expressed in hit/background item base with non-flipped coordinates */
	NSPoint _localStartDragLoc;
	/** Expressed in hit/background item base with non-flipped coordinates */
	NSPoint _localLastDragLoc;
}

// TODO: Decide whether we should support...
//- (ETMoveAction) shouldProduceMoveAction;
//- (void) setShouldProduceMoveAction: (ETMoveAction)actionType;

/** @taskunit Selection Settings */

- (BOOL) allowsMultipleSelection;
- (void) setAllowsMultipleSelection: (BOOL)multiple;
- (BOOL) allowsEmptySelection;
- (void) setAllowsEmptySelection: (BOOL)empty;
- (ETSelectionAreaItem *) selectionAreaItem;
- (void) setSelectionAreaItem: (ETSelectionAreaItem *)anItem;

/** @taskunit Pick and Drop Settings */

- (BOOL) shouldRemoveItemsAtPickTime;
- (void) setShouldRemoveItemsAtPickTime: (BOOL)flag;
- (BOOL) forcesItemPick;
- (void) setForcesItemPick: (BOOL)forceItemPick;

/** @taskunit Event Handlers */

- (void) mouseDragged: (ETEvent *)anEvent;
- (void) mouseUp: (ETEvent *)anEvent;
- (void) keyDown: (ETEvent *)anEvent;
- (void) insertNewLine: (id)sender;

/** @taskunit Selection Status */

- (NSArray *) selectedItems;
- (BOOL) isSelectingArea;

/** @taskunit Selection Area Support */

- (void) beginSelectingAreaAtPoint: (NSPoint)aPoint;
- (void) resizeSelectionAreaToRect: (NSRect)aRect;
- (void) resizeSelectionAreaToPoint: (NSPoint)aPoint;
- (void) endSelectingArea;

/** @taskunit Nested Interaction Support */

- (void) beginEditingInsideSelection;
- (void) endEditingInsideSelection;

/** @taskunit Extending or Reducing Selection */

- (void) alterSelectionWithEvent: (ETEvent *)anEvent;
- (void) extendSelectionToItem: (ETLayoutItem *)item;
- (void) reduceSelectionFromItem: (ETLayoutItem *)item;
- (void) addItemToSelection: (ETLayoutItem *)item;
- (void) removeItemFromSelection: (ETLayoutItem *)item;
- (void) makeSingleSelectionWithItem: (ETLayoutItem *)item;
- (void) deselectAllWithItem: (ETLayoutItem *)item;

/** @taskunit Targeted Action Handler */

- (void) setActionHandlerPrototype: (id)aHandler;
- (id) actionHandlerPrototype;
- (id) actionHandler;
- (id) nextResponder;

/** @taskunit Additional Tool Actions */

// TODO: Probably extract the actions handled by the select tool, which applies 
// to multiple items at a time, into a stanalone class or a category at least.

- (IBAction) selectAll: (id)sender;
- (IBAction) group: (id)sender;
- (IBAction) ungroup: (id)sender;

@end
