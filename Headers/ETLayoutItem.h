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
#import <EtoileUI/ETInspecting.h>
#import <EtoileUI/ETFragment.h>
#import <EtoileUI/ETUIItem.h>

@class ETUTI;
@class ETView, ETLayout, ETLayoutItemGroup, 
ETDecoratorItem, ETScrollableAreaItem, ETWindowItem, ETStyleGroup;
@protocol ETInspector;

/** Describes how the item is resized when its parent item is resized.

An item autoresizing margin is the space between a layout item frame edge (left, 
top, right, bottom) and the equivalent parent frame edge.

Unlike NSAutoresizingMask, ETAutoresizing is independent of the -isFlipped value 
returned by the parent item. e.g. NSMinYMargin means a flexible bottom margin 
when [parent isFlipped] returns NO. When YES is returned, NSMinYMargin means a 
flexible top margin.

-[ETLayoutItem setAutoresizingMask:] also applies to the item view. EtoileUI 
transparently converts it to the right AppKit autoresizing mask by looking at 
whether the parent is flipped or not.

See also ETContentAspect. */
enum
{
	ETAutoresizingNone = NSViewNotSizable, 
/** Lets both the size and the position as is. */
	ETAutoresizingFlexibleLeftMargin = NSViewMinXMargin, 
/** Keeps both the right margin and the width fixed but allows the left margin 
to be resized. */
	ETAutoresizingFlexibleWidth = NSViewWidthSizable, 
/** Keeps both the left margin and the right margin fixed but allows the width 
to be resized. */
	ETAutoresizingFlexibleRightMargin = NSViewMaxXMargin,
/** Keeps both the left margin and the width fixed but allows the right margin 
to be resized. */
	ETAutoresizingFlexibleTopMargin = NSViewMinYMargin,
/** Keeps both the bottom margin and the height fixed but allows the top margin 
to be resized. */
	ETAutoresizingFlexibleHeight = NSViewHeightSizable,
/** Keeps both the bottom margin and the top margin fixed but allows the height 
to be resized. */
	ETAutoresizingFlexibleBottomMargin = NSViewMaxYMargin
/** Keeps both the top margin and the height fixed but allows the bottom margin 
to be resized. */
};
typedef unsigned int ETAutoresizing;

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
	ETContentAspectComputed, 
/** Delegates the content position and size computation to -[ETLayoutItem style]. */
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

@interface ETLayoutItem : ETUIItem <NSCopying, ETObjectInspection, ETFragment>
{
	NSMutableDictionary *_variableProperties;
	// TODO: Merge the two dictionaries or store the default values per object 
	// in an external dictionary.
	NSMutableDictionary *_defaultValues;

	ETLayoutItemGroup *_parentItem;
	id _modelObject;
	ETStyleGroup *_styleGroup;

	NSRect _contentBounds;
	NSPoint _position;
	NSAffineTransform *_transform;
	ETAutoresizing _autoresizingMask;
	ETContentAspect _contentAspect;
	NSRect _boundingBox;

	BOOL _flipped;
	BOOL _selected;
	BOOL _visible;
	BOOL _isSyncingSupervisorViewGeometry;
	BOOL _scrollViewShown; /* Used by ETLayoutItem+Scrollable */
	BOOL _wasKVOStopped;
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
- (id) deepCopyWithZone: (NSZone *)aZone;
- (NSMapTable *) objectReferencesForCopy;

/* Layout Item Tree */

- (id) rootItem;
- (ETLayoutItemGroup *) baseItem;
- (BOOL) isBaseItem;
- (ETLayoutItemGroup *) parentItem;
- (void) setParentItem: (ETLayoutItemGroup *)parent;
- (void ) removeFromParent;
- (ETView *) closestAncestorDisplayView;
- (ETLayoutItem *) supervisorViewBackedAncestorItem;
- (id) windowBackedAncestorItem;

- (NSIndexPath *) indexPathFromItem: (ETLayoutItem *)item;
- (NSIndexPath *) indexPathForItem: (ETLayoutItem *)item;
- (NSIndexPath *) indexPath;
- (NSString *) path;
- (NSString *) representedPath;
- (NSString *) representedPathBase;
- (BOOL) hasValidRepresentedPathBase;

- (NSString *) identifier;

/* Main Accessors */

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
- (NSImage *) snapshotFromRect: (NSRect)aRect;

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

- (void) setSelected: (BOOL)selected;
- (BOOL) isSelected;
- (void) setVisible: (BOOL)visible;
- (BOOL) isVisible;

- (ETUTI *) UTI;
- (void) setSubtype: (ETUTI *)aUTI;
- (ETUTI *) subtype;

/* Layouting & Rendering Chain */

- (ETLayout *) layout;
- (void) setLayout: (ETLayout *)layout;
- (ETLayoutItem *) ancestorItemForOpaqueLayout;
- (void) didChangeLayout: (ETLayout *)oldLayout;
- (void) updateLayout;

- (NSRect) drawingFrame;
- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect 
      inContext: (id)ctxt;
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
- (BOOL) containsPoint: (NSPoint)point;
- (BOOL) pointInside: (NSPoint)point useBoundingBox: (BOOL)extended;
- (BOOL) isFlipped;
- (void) setFlipped: (BOOL)flip;

/* Decoration */

- (ETView *) supervisorView;
- (void) setSupervisorView: (ETView *)supervisorView sync: (ETSyncSupervisorView)syncDirection;

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
- (ETAutoresizing) autoresizingMask;
- (void) setAutoresizingMask: (ETAutoresizing)mask;
- (ETContentAspect) contentAspect;
- (void) setContentAspect: (ETContentAspect)anAspect;
- (NSRect) contentRectWithRect: (NSRect)aRect 
                 contentAspect: (ETContentAspect)anAspect 
                    boundsSize: (NSSize)maxSize;

/* Events & Actions */

- (id) actionHandler;
- (void) setActionHandler: (id)anHandler;
- (BOOL) acceptsActions;
- (BOOL) validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>)anItem;
- (void) setTarget: (id)aTarget;
- (id) target;
- (void) setAction: (SEL)aSelector;
- (SEL) action;
- (void) didChangeViewValue: (id)newValue;
- (void) didChangeRepresentedObjectValue: (id)newValue;

/* Editing (NSEditor and NSEditorRegistration Protocols) */

- (void) beginEditing;
- (void) discardEditing;
- (BOOL) commitEditing;
- (void) objectDidBeginEditing: (id)anEditor;
- (void) objectDidEndEditing: (id)anEditor;

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
