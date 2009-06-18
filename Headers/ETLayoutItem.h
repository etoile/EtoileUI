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
#import <EtoileUI/ETStyle.h>
#import <EtoileUI/ETInspecting.h>
#import <EtoileUI/ETDecoratorItem.h>
#import <EtoileFoundation/ETPropertyValueCoding.h>

@class ETUTI;
@class ETView, ETContainer, ETLayout, ETLayoutItemGroup, 
ETDecoratorItem, ETScrollableAreaItem, ETWindowItem, ETStyleGroup;
@protocol ETInspector;


/* Properties */

extern NSString *kETAnchorPointProperty; /** anchorPoint property name */
extern NSString *kETActionProperty; /** actionHandler property name */
extern NSString *kETActionHandlerProperty; /** actionHandler property name */
extern NSString *kETAutoresizingMaskProperty; /** autoresizingMask property name */
extern NSString *kETBoundingBoxProperty; /** boudingBox property name */
extern NSString *kETDefaultFrameProperty; /** defaultFrame property name */
extern NSString *kETFlippedProperty; /** flipped property name */
extern NSString *kETFrameProperty; /** frame property name */  
extern NSString *kETIconProperty; /** icon property name */
extern NSString *kETImageProperty; /** image property name */
extern NSString *kETInspectorProperty; /** inspector property name */
extern NSString *kETLayoutProperty; /** layout property name */
extern NSString *kETNameProperty; /** name property name */
extern NSString *kETNeedsDisplayProperty; /** needsDisplay property name */
extern NSString *kETParentItemProperty; /** parentItem property name */
extern NSString *kETPersistentFrameProperty; /** persistentFrame property name */
extern NSString *kETRepresentedObjectProperty; /** representedObject property name */
extern NSString *kETRepresentedPathBaseProperty; /** representedPathBase property name */
extern NSString *kETSelectedProperty; /** selected property name */
extern NSString *kETSubtypeProperty; /** subtype property name */
extern NSString *kETStyleGroupProperty; /** styleGroup property name */
extern NSString *kETTargetProperty; /** actionHandler property name */
extern NSString *kETValueProperty; /** value property name */
extern NSString *kETVisibleProperty; /** visible property name */

// FIXME: Use less memory per instance. Name and value are somehow duplicates.
// _cells and _view could be moved in a helper object. Pack booleans in a struct.
@interface ETLayoutItem : ETUIItem <NSCopying, ETPropertyValueCoding, ETObjectInspection>
{
	ETLayoutItemGroup *_parentItem;
	
	id _modelObject;
	ETStyleGroup *_styleGroup;
	NSMutableDictionary *_variableProperties;
	NSMutableDictionary *_defaultValues; // TODO: Probably merge the two dictionaries

	NSRect _contentBounds;
	NSPoint _position;
	NSAffineTransform *_transform;

	/* Model object stores a persistent frame when the layout is non-computed */
	NSRect _boundingBox;
	BOOL _flipped;
	BOOL _selected;
	BOOL _visible;
	BOOL _resizeBounds; /* Scale view content by resizing bounds */
	BOOL _needsUpdateLayout;
	BOOL _isSyncingSupervisorViewGeometry;
	BOOL _scrollViewShown; /* Used by ETLayoutItem+Scrollable */
	// TODO: Implement... BOOL _needsDisplay;
}

/* Initialization */

- (id) initWithValue: (id)value;
- (id) initWithRepresentedObject: (id)object;
- (id) initWithView: (NSView *)view;
- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject;
- (id) initWithFrame: (NSRect)frame;

- (id) copyWithZone: (NSZone *)zone;
- (id) deepCopy;

/* Layout Item Tree */

- (id) rootItem;
- (ETLayoutItemGroup *) baseItem;
- (BOOL) isBaseItem;
- (ETLayoutItemGroup *) parentItem;
- (void) setParentItem: (ETLayoutItemGroup *)parent;
- (void ) removeFromParent;
- (ETContainer *) closestAncestorContainer;
- (ETView *) closestAncestorDisplayView;
- (ETLayoutItem *) closestAncestorItemWithDisplayView;

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
- (BOOL) usesWidgetView;

- (NSImage *) image;
- (void) setImage: (NSImage *)img;
- (NSImage *) icon;
- (void) setIcon: (NSImage *)icon;

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
- (void) setSubtype: (ETUTI *)aUTI;
- (ETUTI *) subtype;

/* Layouting & Rendering Chain */

- (ETLayout *) layout;
- (void) setLayout: (ETLayout *)layout;
- (void) didChangeLayout: (ETLayout *)oldLayout;

- (void) updateLayout;
- (void) apply: (NSMutableDictionary *)inputValues;
- (NSRect) drawingFrame;
- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect 
      inContext: (id)ctxt;
- (void) render;
- (ETStyleGroup *) styleGroup;
- (void) setStyleGroup: (ETStyleGroup *)aStyle;
- (id) style;
- (void) setStyle: (ETStyle *)aStyle;

- (void) setNeedsDisplay: (BOOL)flag;
- (void) setNeedsDisplayInRect: (NSRect)dirtyRect;
- (void) display;
- (void) displayRect: (NSRect)dirtyRect;
- (void) displayIfNeeded;

- (void) setDefaultValue: (id)aValue forProperty: (NSString *)key;
- (id) defaultValueForProperty: (NSString *)key;

/* Geometry */

- (NSRect) convertRectToParent: (NSRect)rect;
- (NSRect) convertRectFromParent: (NSRect)rect;
- (NSPoint) convertPointToParent: (NSPoint)point;
- (NSPoint) convertPointFromParent: (NSPoint)point;
- (NSRect) convertRect: (NSRect)rect fromItem: (ETLayoutItemGroup *)ancestor;
- (NSRect) convertRect: (NSRect)rect toItem: (ETLayoutItemGroup *)ancestor;
/*- (NSPoint) convertPoint: (NSPoint)point fromItem: (ETLayoutItemGroup *)ancestor;
- (NSPoint) convertPoint: (NSPoint)point toItem: (ETLayoutItemGroup *)ancestor;*/
- (BOOL) containsPoint: (NSPoint)point;
- (BOOL) pointInside: (NSPoint)point useBoundingBox: (BOOL)extended;
- (BOOL) isFlipped;
- (void) setFlipped: (BOOL)flip;

/* Decoration */

- (id) supervisorView;
- (void) setSupervisorView: (ETView *)supervisorView;

- (ETScrollableAreaItem *) firstScrollViewDecoratorItem;
- (ETWindowItem *) windowDecoratorItem;

/* Sizing */

- (NSRect) persistentFrame;
- (void) setPersistentFrame: (NSRect) frame;

- (NSRect) frame;
- (void) setFrame: (NSRect)rect;
- (NSPoint) origin;
- (void) setOrigin: (NSPoint)origin;
- (NSPoint) anchorPoint;
- (void) setAnchorPoint: (NSPoint)center;
- (NSPoint) position;
- (void) setPosition: (NSPoint)position;
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

- (NSRect) contentBounds;
- (void) setContentBounds: (NSRect)rect;
- (void) setContentSize: (NSSize)size;
- (NSRect) convertRectFromContent: (NSRect)rect;
- (NSRect) convertRectToContent: (NSRect)rect;
- (void) setTransform: (NSAffineTransform *)aTransform;
- (NSAffineTransform *) transform;

- (NSRect) boundingBox;
- (void) setBoundingBox: (NSRect)extent;
- (NSRect) defaultFrame;
- (void) setDefaultFrame: (NSRect)frame;
- (void) restoreDefaultFrame;
- (unsigned int) autoresizingMask;
- (void) setAutoresizingMask: (unsigned int)mask;
- (void) setAppliesResizingToBounds: (BOOL)flag;
- (BOOL) appliesResizingToBounds;

/* Events & Actions */

- (id) actionHandler;
- (void) setActionHandler: (id)anHandler;
- (BOOL) acceptsActions;
- (BOOL) validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>)anItem;
- (void) setTarget: (id)aTarget;
- (id) target;
- (void) setAction: (SEL)aSelector;
- (SEL) action;
- (id) nextResponder;

- (id <ETInspector>) inspector;
- (void) setInspector: (id <ETInspector>)inspector;

/* Live Development */

- (void) beginEditingUI;
/*- (BOOL) isEditingUI;
- (void) commitEditingUI;*/

@end


@interface NSObject (ETLayoutItemDelegate)
/** See ETLayoutItemLayoutDidChangeNotification. */
- (void) layoutDidChange: (NSNotification *)notif;
@end

/** Notification posted by ETLayoutItem and subclasses in reply to -setLayout: 
on the poster object. The poster object can be retrieved through 
-[NSNotification object]. 

If -setLayout: results in no layout change, no notification is posted.

This notification is also posted when the layout is modified by the user (e.g. 
through an inspector). */
extern NSString *ETLayoutItemLayoutDidChangeNotification;


@interface NSObject (ETLayoutItem)
- (BOOL) isLayoutItem;
@end
