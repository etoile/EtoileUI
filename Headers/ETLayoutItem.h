/** <title>ETLayoutItem</title>
	
	<abstract>ETLayoutItem is the base class for all node subclasses that can be 
	used in a layout item tree. ETLayoutItem instances are leaf nodes for the 
	layout item tree structure.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License: Modified BSD (see COPYING)
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

/** Describes how the content looks when the layout item is resized.

The content can be:
<list>
<item>a view, when -view is not nil</item>
<item>what the styles draw, when -styleGroup is not empty</item>
</list>

The content aspect is applied to a view by altering its autoresizing mask.<br />
For their parts, styles are expected to rely on the item content aspect to know 
how they should draw the properties they retrieve through the layout item. 

Some content aspects won't be applied to a view because they cannot be 
translated into an autoresizing mask. */
typedef enum
{
	ETContentAspectNone, 
/** Lets the content as is. */
	ETContentAspectCentered, 
/** Centers the content and never resizes it. */
	ETContentAspectScaleToFit, 
/** Scales the content, by preserving the content proportions, to the maximum 
size that keeps both the height and width equals to or less than the item 
content size. And centers the content. */
	ETContentAspectScaleToFill,
/** Scales the content, by preserving the content proportions, to the minimum 
size that keeps both the height and width equals to or greater than the item 
content size. And centers the content. */
	ETContentAspectScaleToFillHorizontally,
/** Scales the content, by preserving the content proportions, to the item 
content width and centers it. */
	ETContentAspectScaleToFillVertically,
/** Scales the content, by preserving the content proportions, to the item 
content height and centers it. */
	ETContentAspectStretchToFill
/** Streches the content, by distorting it if needed, to the item content size 
and centers it. A strech is a scale that doesn't preserve the content proportions. */
} ETContentAspect;


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
	unsigned int _autoresizingMask;
	ETContentAspect _contentAspect;

	/* Model object stores a persistent frame when the layout is non-computed */
	NSRect _boundingBox;
	BOOL _flipped;
	BOOL _selected;
	BOOL _visible;
	BOOL _needsUpdateLayout;
	BOOL _isSyncingSupervisorViewGeometry;
	BOOL _scrollViewShown; /* Used by ETLayoutItem+Scrollable */
	BOOL _wasKVOStopped;
	// TODO: Implement... BOOL _needsDisplay;
}

/* Initialization */

- (id) initWithValue: (id)value;
- (id) initWithRepresentedObject: (id)object;
- (id) initWithView: (NSView *)view;
- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject;
- (id) initWithFrame: (NSRect)frame;

- (void) stopKVOObservation;
- (void) stopKVOObservationIfNeeded;
- (id) copyWithZone: (NSZone *)zone;
- (id) deepCopy;

/* Layout Item Tree */

- (id) rootItem;
- (ETLayoutItemGroup *) baseItem;
- (BOOL) isBaseItem;
- (ETLayoutItemGroup *) parentItem;
- (void) setParentItem: (ETLayoutItemGroup *)parent;
- (void ) removeFromParent;
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
- (id) subject;

- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;
- (NSArray *) properties;
- (NSDictionary *) variableProperties;

- (BOOL) isLayoutItem;
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
- (ETUTI *) UTI;
- (void) setSubtype: (ETUTI *)aUTI;
- (ETUTI *) subtype;

/* Layouting & Rendering Chain */

- (ETLayout *) layout;
- (void) setLayout: (ETLayout *)layout;
- (ETLayoutItem *) ancestorItemForOpaqueLayout;
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
- (void) refreshIfNeeded;

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
- (ETContentAspect) contentAspect;
- (void) setContentAspect: (ETContentAspect)anAspect;

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

/* Deprecated (DO NOT USE, WILL BE REMOVED LATER) */

- (void) setAppliesResizingToBounds: (BOOL)flag;
- (BOOL) appliesResizingToBounds;

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
