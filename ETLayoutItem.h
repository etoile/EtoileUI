//
//  ETLayoutItem.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETStyleRenderer;

/** WARNING: Personal notes that are vague and may change, move or become part
	of another framework.

	Rendering tree is an extension of renderer support, this extension is 
	useful essentially in imaging applications either vector or bitmap based.

	Rendering is the step which precedes display and encompass both layout and
	real time graphics computation.
	A renderer tree would be roughly identical to GEGL model.
	Layout item tree and renderer tree form two parallel trees which are 
	bridged together and ruled by layout items. 
	At each layout item node, a renderer branch is connected.
	Both trees are visited together from top to bottom at rendering time.
	At rendering time, a visitor object which encapsulates the rendering state
	is passed through layout items:
	- it enters a layout item
	- it visits the item renderer branch and computes it if needed
	- it memorizes the first renderer directly connected to the layout item
	- it quits the layout item
	- it enters a second layout item
	- it checks whether the first renderer of the layout item has a second 
	input if we put aside renderer branch which plays the first input role; if
	no second input is present, it uses the last memorized renderer in this 
	role
	- it removes the last memorized renderer of the second input if necessary
	- it memorizes the renderer connected to the second layout
	- it quits the layout item
 */


@interface ETLayoutItem : NSObject 
{
	id _value;
	id _modelObject;
	NSView *_view;
	ETStyleRenderer *_renderer;
	BOOL _selected;
	NSRect _defaultFrame;
	NSString *_name;
	BOOL _resizeBounds;
}

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view;

- (ETLayoutItem *) initWithValue: (id)value;
- (ETLayoutItem *) initWithRepresentedObject: (id)object;
- (ETLayoutItem *) initWithView: (NSView *)view;

/** Facility methods to store a name acting like a last fallback property for 
	display. Name is also used as a path component to build 
	paths passed through tree source protocol to the container source. If no 
	name is available, the layout item is referenced in the path by its index 
	in layout item group which owns it. Name have the advantage to be more 
	stable than index in some cases, you can also store id or uuid in this
	field.
	You can retrieve a layout item bound a know path by simply passing this 
	path as a parameter to -[ETContainer layoutItemForPath:]. Layout items
	tree structure are managed by container archictecture so you never need
	to worry about releasing/retaining items. Only your wrapped model if you
	need/have one must be memory-managed by your code. 
	NOTE: the feature described below isn't yet supported by container
	architecture and could never be.
	If you use no container source, and you call -[ETContainer addItem:] with
	a layout item group referencing other items, in this case the management
	of the tree structure is up to you.*/
- (NSString *) name;
- (void) setName: (NSString *)name;

/* Display Element */

- (id) value;
- (void) setValue: (id)value;

- (NSView *) view;
- (void) setView: (NSView *)view;

- (NSView *) displayView;

/* Model Access */

- (id) representedObject;
- (void) setRepresentedObject: (id)modelObject;

- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;

/* Utility Accessors */

- (void) setSelected: (BOOL)selected;
- (BOOL) isSelected;

/* Rendering Chain */

- (void) render;
- (ETStyleRenderer *) renderer;
- (void) setStyleRenderer: (ETStyleRenderer *)renderer;

- (NSRect) defaultFrame;
- (void) setDefaultFrame: (NSRect)frame;
- (void) restoreDefaultFrame;
- (void) setAppliesResizingToBounds: (BOOL)flag;
- (BOOL) appliesResizingToBounds;

/* Actions */

- (void) doubleClick;

@end

/*
@interface ETLayoutItem (NSCellCompatibility)
- (NSCell *) cell;
- (void) setCell: (NSCell *)cell;
@end
*/
