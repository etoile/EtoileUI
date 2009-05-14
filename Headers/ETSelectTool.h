/** <title>ETSelectTool</title>

	<abstract>An instrument class which provides rich and customizable selection 
	logic. ETSelectTool encapsulates selection behavior to make it 
	reusable and uniform accross ETLayout subclasses.</abstract>

	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETInstruments.h>

@class ETEvent, ETLayoutItem, ETLayoutItemGroup, ETLayout, ETSelectionAreaItem;

/*enum {
	ETMoveActionTranslate,
	ETMoveActionDrag,
	ETMoveActionNone
}*/

/** Attached by default to ETFreeLayout

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
immediate children and thereby isn't really inherited as other instruments are 
usually. However you can retarget the item on which it acts on by setting a 
target item with -setTargetItem:.
*/
@interface ETSelectTool : ETMoveTool
{
	id _actionHandlerPrototype;
	ETSelectionAreaItem *_selectionAreaItem;
	BOOL _multipleSelectionAllowed;
	BOOL _emptySelectionAllowed;
	BOOL _removeItemsAtPickTime;
	BOOL _newSelectionAreaUnderway; // NOTE: May be move up to ETArrowTool
	NSPoint _localStartDragLoc; /** Expressed in hit/background item base with non-flipped coordinates */
	NSPoint _localLastDragLoc; /** Expressed in hit/background item base with non-flipped coordinates */
}

// TODO: Implement
//- (void) didBecomeActive: (ETInstrument *)prevInstrument;
// or
/*- (void) willBecomeActive
{
	ETInstrument *activeInstrument = [ETInstrument activeInstrument];
	BOOL isInstrumentReplacement = ([activeInstrument isSelectTool] && [[activeInstrument layoutOwner] isEqual: [self layoutOwner]]);
	
	if (isInstrumentReplacement)
		[self setAllowedDragUTIs: [activeInstrument allowedDragUTIs]];
}*/
// or rather take the values from the controller when attaching the instrument for the first time. or cache a select tool prototype in the controller? Well need a general mechanism to store tool prototypes anyway…
// -[ETController setPrototype: forInstrumentClass:]?

// NOTE: May be we should alternatively allow the controller to specify the 
// following properties...
- (BOOL) allowsMultipleSelection;
- (void) setAllowsMultipleSelection: (BOOL)multiple;
- (BOOL) allowsEmptySelection;
- (void) setAllowsEmptySelection: (BOOL)empty;
- (BOOL) shouldRemoveItemsAtPickTime;
- (void) setShouldRemoveItemsAtPickTime: (BOOL)flag;
//- (ETMoveAction) shouldProduceMoveAction;
//- (void) setShouldProduceMoveAction: (ETMoveAction)actionType;

- (ETSelectionAreaItem *) selectionAreaItem;
- (void) setSelectionAreaItem: (ETSelectionAreaItem *)anItem;
- (BOOL) isSelectingArea;
- (void) beginSelectingAreaAtPoint: (NSPoint)aPoint;
- (void) resizeSelectionAreaToPoint: (NSPoint)aPoint;
- (void) endSelectingArea;

- (void) mouseDragged: (ETEvent *)anEvent;
- (void) mouseUp: (ETEvent *)anEvent;
- (void) insertNewLine: (id)sender;
- (void) beginEditingInsideSelection;
- (void) endEditingInsideSelection;

- (void) alterSelectionWithEvent: (ETEvent *)anEvent;
- (void) extendSelectionToItem: (ETLayoutItem *)item;
- (void) reduceSelectionFromItem: (ETLayoutItem *)item;
- (void) addItemToSelection: (ETLayoutItem *)item;
- (void) removeItemFromSelection: (ETLayoutItem *)item;
- (void) makeSingleSelectionWithItem: (ETLayoutItem *)item;
- (void) deselectAllWithItem: (ETLayoutItem *)item;

- (void) setActionHandlerPrototype: (id)aHandler;
- (id) actionHandlerPrototype;
- (id) actionHandler;
- (BOOL) makeFirstKeyResponder: (id)aResponder;
- (BOOL) makeFirstMainResponder: (id)aResponder;
- (id) nextResponder;

// TODO: Probably extract the actions handled by the select tool, which applies 
// to multiple items at a time, into a stanalone class or a category at least.

- (IBAction) selectAll: (id)sender;
- (IBAction) group: (id)sender;
- (IBAction) ungroup: (id)sender;

@end

// TODO: Inspection and ETSelectTool
/* Returns inspector based on selection unlike ETLayoutItem.

If a custom inspector hasn't been set by calling -setInspector:, the inspector 
set on the base item is retrieved. If the option/alt modifier key is pressed, 
a copy of the inspector is returned rather reusing the existing instance as 
usual. This facility allows to easily inspect two items with two distinct 
inspectors, even if these layout items belong to the same base item. At UI level, 
the user can press the option/alt key when choosing Inspect in a menu. */
