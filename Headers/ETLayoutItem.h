/*
	ETLayoutItem.h
	
	ETLayoutItem is the base class for all node subclasses that can be used in
	a layout item tree. ETLayoutItem instances are leaf nodes for the layout 
	item tree structure.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETStyleRenderer.h>
#import <EtoileUI/ETInspecting.h>
#import <EtoileFoundation/ETPropertyValueCoding.h>

// TODO: Remove once ETUTI is part of EtoileFoundation.
#define ETUTI NSString

@class ETView, ETContainer, ETLayoutItemGroup, ETWindowItem, ETActionHandler;
@protocol ETEventHandler;

/* Properties */

extern NSString *kETActionHandlerProperty; /** actionHandler property name */
extern NSString *kETFrameProperty; /** frame property name */  
extern NSString *kETIconProperty; /** icon property name */
extern NSString *kETImageProperty; /** image property name */
extern NSString *kETNameProperty; /** name property name */
extern NSString *kETPersistentFrameProperty; /** persistentFrame property name */
extern NSString *kETStyleProperty; /** style property name */
extern NSString *kETValueProperty; /** value property name */

// FIXME: Use less memory per instance. Name and value are somehow duplicates.
// _cells and _view could be moved in a helper object. Pack booleans in a struct.
@interface ETLayoutItem : ETStyle <ETPropertyValueCoding, ETObjectInspection>
{
	ETLayoutItemGroup *_parentLayoutItem;

	id _modelObject;
	NSMutableDictionary *_variableProperties;
	ETStyle *_style;
	ETLayoutItem *_decoratorItem; // previous decorator
	ETLayoutItem *_decoratedItem; // next decorator

	IBOutlet ETView *_view;
	
	/* Model object stores a persistent frame when the layout is non-computed */
	NSRect _defaultFrame; /* Frame without item scaling */
	NSRect _frame; /* Frame with item scaling */
	
	BOOL _selected;
	BOOL _visible;
	BOOL _resizeBounds; /* Scale view content by resizing bounds */
	BOOL _needsUpdateLayout;
	
	id _reserved;
}

/* Initialization */

- (id) initWithValue: (id)value;
- (id) initWithRepresentedObject: (id)object;
- (id) initWithView: (NSView *)view;
- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject;

- (id) deepCopy;

/* Layout Item Tree */

- (id) rootItem;
- (id) baseItem;
- (ETLayoutItemGroup *) parentItem;
- (void) setParentItem: (ETLayoutItemGroup *)parent;
- (void ) removeFromParent;
- (ETContainer *) closestAncestorContainer;
- (ETView *) closestAncestorDisplayView;

- (NSIndexPath *) indexPathFromItem: (ETLayoutItem *)item;
- (NSIndexPath *) indexPathForItem: (ETLayoutItem *)item;
- (NSIndexPath *) indexPath;
- (NSString *) path;
//- (void) setPath: (NSString *)path;
- (NSString *) representedPath;
- (NSString *) representedPathBase;
- (BOOL) hasValidRepresentedPathBase;

- (NSString *) identifier;

/* Main Accessors */

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
- (NSString *) displayName;

/* Display Element */

- (id) value;
- (void) setValue: (id)value;

- (NSView *) view;
- (void) setView: (NSView *)newView;

- (ETView *) displayView;

//-displayObject

- (NSImage *) image;
- (void) setImage: (NSImage *)img;
- (NSImage *) icon;
- (void) setIcon: (NSImage *)icon;

/* If you have a shape set, it's always inserted after image renderer in the
	rendering chain. */
/*setShape
shape*/

/* Model Access */

- (id) representedObject;
- (void) setRepresentedObject: (id)modelObject;

- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;
- (NSArray *) properties;
- (NSDictionary *) variableProperties;

- (unsigned int) UIMetalevel;
- (unsigned int) UIMetalayer;
- (BOOL) isMetaLayoutItem;
//- (BOOL) isUILayoutItem;
- (BOOL) isGroup;

/* Utility Accessors */

/** When selection is enabled on -render call, the layout item checks a
	selection renderer (ETSelection class or subclasses) is part of its 
	rendering chain. When none is found, it inserts default selection
	renderer at the end of the chain.
	[ETRenderer rendererForName: kETStyleSelection
	If selection is disabled, it does nothing. If you call 
	-setEnablesSelection: with NO, it removes all selection renderers part
	of the rendering chain. */
/*- setEnablesSelection:
- isSelectionEnabled;*/
- (void) setSelected: (BOOL)selected;
- (BOOL) isSelected;
- (void) setVisible: (BOOL)visible;
- (BOOL) isVisible;

/** Used to select items which can be dragged or dropped in a dragging operation */
- (ETUTI *) type;

/* Layouting & Rendering Chain */

- (void) updateLayout;
- (void) apply: (NSMutableDictionary *)inputValues;
- (NSRect) drawingFrame;
- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect 
         inView: (NSView *)view;
- (void) render;
- (ETStyle *) style;
- (void) setStyle: (ETStyle *)aStyle;

- (void) setNeedsDisplay: (BOOL)now;

/* Geometry */

- (NSRect) convertRectToParent: (NSRect)rect;
- (NSRect) convertRectFromParent: (NSRect)rect;
- (NSPoint) convertPointToParent: (NSPoint)point;
- (NSPoint) convertPointFromParent: (NSPoint)point;
- (BOOL) containsPoint: (NSPoint)point;
- (BOOL) pointInside: (NSPoint)point;
- (BOOL) isFlipped;

//- (ETLayoutItem *) decoratorItemAtPoint: (NSPoint *)point;
//- (NSRect) contentRect;

/* Decoration */

- (ETLayoutItem *) decoratorItem;
- (void) setDecoratorItem: (ETLayoutItem *)decorator;
- (ETLayoutItem *) decoratedItem;
- (void) setDecoratedItem: (ETLayoutItem *)decorator;
- (ETLayoutItem *) lastDecoratorItem;
- (ETLayoutItem *) firstDecoratedItem;
- (BOOL) canDecorateItem: (ETLayoutItem *)item;
- (BOOL) acceptsDecoratorItem: (ETLayoutItem *)item;
- (void) handleDecorateItem: (ETLayoutItem *)item inView: (ETView *)parentView;
- (id) supervisorView;
- (void) setSupervisorView: (ETView *)supervisorView;

- (ETLayoutItem *) firstScrollViewDecoratorItem;
- (ETWindowItem *) windowDecoratorItem;

//-setShowsDecorator:

/* Sizing */

// No need for the following
/** The following method locks the layout item to prevent modifying the 
    property kETVectorLocation which stores the layout item location in
	non-computed layout like ETFreeLayout */
/*- (void) beginLayoutComputation;
- (void) endLayoutComputation;*/

- (NSRect) persistentFrame;
- (void) setPersistentFrame: (NSRect) frame;

- (NSRect) frame;
- (void) setFrame: (NSRect)rect;
- (NSPoint) origin;
- (void) setOrigin: (NSPoint)origin;
- (NSSize) size;
- (void) setSize: (NSSize)size;
- (float) x;
- (void) setX: (float)x;
- (float) y;
- (void) setY: (float)y;
- (float) height;
- (void) setHeight: (float)height;
- (float) width;
- (void) setWidth: (float)width;

- (NSRect) defaultFrame;
- (void) setDefaultFrame: (NSRect)frame;
- (void) restoreDefaultFrame;
- (unsigned int) autoresizingMask;
- (void) setAutoresizingMask: (unsigned int)mask;
- (void) setAppliesResizingToBounds: (BOOL)flag;
- (BOOL) appliesResizingToBounds;

/* Events & Actions */

- (ETActionHandler *) actionHandler;
- (void) setActionHandler: (ETActionHandler *)anHandler;

- (void) showInspectorPanel;
- (id <ETInspector>) inspector;

/* Live Development */

- (void) beginEditingUI;
/*- (BOOL) isEditingUI;
- (void) commitEditingUI;*/

/* Deprecated (DO NOT USE, WILL BE REMOVED LATER) */

- (ETLayoutItemGroup *) parentLayoutItem;
- (void) setParentLayoutItem: (ETLayoutItemGroup *)parent;
- (id <ETEventHandler>) eventHandler;

@end

/** ETlayoutItem has no delegate but rather used the delegate of the closest 
	container ancestor.
	Implements this method if you set values in aggregate views or cells. For
	example, when you have a mixed icon text cell, you would write:
	if ([property isEqual: kPropertyName])
	{
		[[item cell] setText: value];
		[[item cell] setImage: [item valueForProperty: @"icon"];
	}
	Be careful with property because it can be a key path so you may better 
	to always retrieve the last component.
	Binding can be used instead of this method if you prefer.
	An other alternative is to subclass ETLayoutItem and overrides method
	-setValue:forProperty:. But the purpose of this delegate is precisely to 
	avoid subclassing burden. */
@interface ETLayoutItem (ETLayoutItemDelegate)
- (void) layoutItem: (ETLayoutItem *)item setValue: (id)value forProperty: (NSString *)property;
@end

/*
@interface ETLayoutItem (NSCellCompatibility)
- (NSCell *) cellForProperty: (NSString *)property;
- (void) setCellForProperty: (NSCell *)cell;
@end
*/

@interface NSObject (ETLayoutItem)
- (BOOL) isLayoutItem;
@end
