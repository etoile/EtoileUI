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
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETFragment.h>
#import <EtoileUI/ETUIItem.h>

@class ETUTI;
@class ETItemValueTransformer, ETView, ETLayout, ETLayoutItemGroup,
ETDecoratorItem, ETScrollableAreaItem, ETWindowItem, ETActionHandler, ETStyleGroup;
@protocol ETWidget, NSValidatedUserInterfaceItem;

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
	ETAutoresizingFlexibleTopMargin = NSViewMaxYMargin,
/** Keeps both the bottom margin and the height fixed but allows the top margin 
to be resized. */
	ETAutoresizingFlexibleHeight = NSViewHeightSizable,
/** Keeps both the bottom margin and the top margin fixed but allows the height 
to be resized. */
	ETAutoresizingFlexibleBottomMargin = NSViewMinYMargin
/** Keeps both the top margin and the height fixed but allows the bottom margin 
to be resized. */
};
typedef NSUInteger ETAutoresizing;

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
typedef enum : NSUInteger
{
	ETContentAspectNone, 
/** Lets the content as is. */
	ETContentAspectComputed, 
/** Delegates the content position and size computation to -[ETLayoutItem coverStyle]. */
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

/** You must never subclass ETLayoutItem. */
@interface ETLayoutItem : ETUIItem <ETFragment>
{
	@protected
	NSMutableDictionary *_deserializationState;
	// TODO: Merge into _variableStorage or store the default values per object 
	// in an external dictionary.
	@private
	NSMutableDictionary *_defaultValues;
	id _representedObject;
	ETStyleGroup *_styleGroup;
	ETStyle *_coverStyle;

	NSRect _contentBounds;
	NSPoint _position;
	NSAffineTransform *_transform;
	ETAutoresizing _autoresizingMask;
	ETContentAspect _contentAspect;
	NSRect _boundingBox;

	BOOL _flipped;
	BOOL _selected;
	BOOL _selectable;
	BOOL _visible;
	BOOL _isSyncingSupervisorViewGeometry;
	BOOL _scrollable; /* Used by ETLayoutItem+Scrollable */
	BOOL _wasKVOStopped;
	BOOL _isSettingRepresentedObject;
	BOOL _isSyncingViewValue;
	BOOL _isEditing; /* Used by ETLayoutItem+AppKit */
	BOOL _isEditingUI; /* Used by ETLayoutItem+CoreObject */
	@protected
	BOOL _isDeallocating;
}

/** @taskunit Debugging */

+ (BOOL) showsBoundingBox;
+ (void) setShowsBoundingBox: (BOOL)shows;
+ (BOOL) showsFrame;
+ (void) setShowsFrame: (BOOL)shows;

/** @taskunit Autolayout */

+ (BOOL) isAutolayoutEnabled;
+ (void) enablesAutolayout;
+ (void) disablesAutolayout;

/** @taskunit Initialization */

- (id) initWithView: (NSView *)view 
         coverStyle: (ETStyle *)aStyle 
      actionHandler: (ETActionHandler *)aHandler
 objectGraphContext: (COObjectGraphContext *)aContext;

/** @taskunit Description */

- (NSString *) shortDescription;

/** @taskunit Navigating the Item Tree */

- (id) rootItem;
- (ETLayoutItemGroup *) controllerItem;
- (ETLayoutItemGroup *) baseItem;
- (NSIndexPath *) indexPathFromItem: (ETLayoutItem *)item;
- (NSIndexPath *) indexPathForItem: (ETLayoutItem *)item;

/** @taskunit Parent Item */

/** The item group to which the receiver belongs to.
 
For the root item, returns nil.

If a host item is set, returns -hostItem. */
@property (nonatomic, readonly) ETLayoutItemGroup *parentItem;

- (void) removeFromParent;

/** @taskunit Other Ancestor Items */

- (id) windowBackedAncestorItem;
- (ETLayoutItemGroup *) ancestorItemForOpaqueLayout;

/** @taskunit Name and Identifier */

- (NSString *) identifier;
- (void) setIdentifier: (NSString *)anId;
- (NSString *) name;
- (void) setName: (NSString *)name;
- (NSString *) displayName;
- (void) setDisplayName: (NSString *)aName;

/** @taskunit Native Widget */

- (id) view;
- (void) setView: (NSView *)newView;
- (BOOL) usesWidgetView;
- (id <ETWidget>) widget;

/** @taskunit Image and Icon */

- (NSImage *) image;
- (void) setImage: (NSImage *)img;
- (NSImage *) icon;
- (void) setIcon: (NSImage *)icon;
- (NSImage *) snapshotFromRect: (NSRect)aRect;

/** @taskunit Presented Model */

- (id) representedObject;
- (void) setRepresentedObject: (id)modelObject;
- (id) subject;
- (BOOL) isMetaItem;
- (id) valueKey;
- (void) setValueKey: (NSString *)aValue;
- (id) value;
- (void) setValue: (id)value;

/** @taskunit Property-Value Coding */

- (BOOL) requiresKeyValueCodingForAccessingProperties;
- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;
- (ETItemValueTransformer *) valueTransformerForProperty: (NSString *)key;
- (void) setValueTransformer: (ETItemValueTransformer *)aValueTransformer
                 forProperty: (NSString *)key;

/** @taskunit Type Querying */

- (BOOL) isLayoutItem;
- (BOOL) isGroup;
- (BOOL) isBaseItem;

/** @taskunit Selection and Visibility */

- (void) setSelected: (BOOL)selected;
- (BOOL) isSelected;
- (void) setSelectable: (BOOL)selectable;
- (BOOL) isSelectable;
- (void) setVisible: (BOOL)visible;
- (BOOL) isVisible;

/** @taskunit Attached UTIs */

- (ETUTI *) UTI;
- (void) setSubtype: (ETUTI *)aUTI;
- (ETUTI *) subtype;

/** @taskunit Drawing */

- (NSRect) drawingBoundsForStyle: (ETStyle *)aStyle;
- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect 
      inContext: (id)ctxt;

/** @task Styles */

- (ETStyleGroup *) styleGroup;
- (void) setStyleGroup: (ETStyleGroup *)aStyle;
- (id) style;
- (void) setStyle: (ETStyle *)aStyle;
- (id) coverStyle;
- (void) setCoverStyle: (ETStyle *)aStyle;

/** @taskunit Display Update */

- (void) setNeedsDisplay: (BOOL)flag;
- (void) setNeedsDisplayInRect: (NSRect)dirtyRect;
- (void) display;
- (void) displayRect: (NSRect)dirtyRect;
- (void) displayIfNeeded;

/** @taskunit Outer Geometry Conversion in Item Tree */

- (NSRect) convertRectToParent: (NSRect)rect;
- (NSRect) convertRectFromParent: (NSRect)rect;
- (NSPoint) convertPointToParent: (NSPoint)point;
- (NSPoint) convertPointFromParent: (NSPoint)point;
- (NSRect) convertRect: (NSRect)rect fromItem: (ETLayoutItemGroup *)ancestor;
- (NSRect) convertRect: (NSRect)rect toItem: (ETLayoutItemGroup *)ancestor;

/** @taskunit Inner/Outer Geometry Conversion and Hit Test */
 
- (NSRect) convertRectFromContent: (NSRect)rect;
- (NSRect) convertRectToContent: (NSRect)rect;
- (NSPoint) convertPointToContent: (NSPoint)aPoint;
- (BOOL) containsPoint: (NSPoint)point;
- (BOOL) pointInside: (NSPoint)point useBoundingBox: (BOOL)extended;

/** @taskunit Decorator Items */

- (ETScrollableAreaItem *) scrollableAreaItem;
- (ETWindowItem *) windowItem;

/** @taskunit Outer Geometry */

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
- (CGFloat) x;
- (void) setX: (CGFloat)x;
- (CGFloat) y;
- (void) setY: (CGFloat)y;
- (CGFloat) height;
- (void) setHeight: (CGFloat)height;
- (CGFloat) width;
- (void) setWidth: (CGFloat)width;

/** @taskunit Adjusting Hit Test and Display Area */

- (NSRect) boundingBox;
- (void) setBoundingBox: (NSRect)extent;

/** @taskunit Inner Geometry  */

- (NSRect) contentBounds;
- (void) setContentBounds: (NSRect)rect;
- (void) setContentSize: (NSSize)size;
- (void) setTransform: (NSAffineTransform *)aTransform;
- (NSAffineTransform *) transform;
- (BOOL) isFlipped;
- (void) setFlipped: (BOOL)flip;

/** @taskunit Fixed Geometry */

- (NSRect) persistentFrame;
- (void) setPersistentFrame: (NSRect) frame;

/** @taskunit Autoresizing and Content Aspect */

- (ETAutoresizing) autoresizingMask;
- (void) setAutoresizingMask: (ETAutoresizing)mask;
- (ETContentAspect) contentAspect;
- (void) setContentAspect: (ETContentAspect)anAspect;
- (NSRect) contentRectWithRect: (NSRect)aRect 
                 contentAspect: (ETContentAspect)anAspect 
                    boundsSize: (NSSize)maxSize;
- (void) sizeToFit;

/** @taskunit Filtering */

- (BOOL) matchesPredicate: (NSPredicate *)aPredicate;

/** @taskunit Actions */

- (id) actionHandler;
- (void) setActionHandler: (id)anHandler;
- (BOOL) acceptsActions;
- (BOOL) validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>)anItem;
- (void) setTarget: (id)aTarget;
- (id) target;
- (void) setAction: (SEL)aSelector;
- (SEL) action;

/** @taskunit Editing */

- (void) beginEditing;
- (void) discardEditing;
- (BOOL) commitEditing;
- (void) subjectDidBeginEditingForProperty: (NSString *)aKey
                           fieldEditorItem: (ETLayoutItem *)aFieldEditorItem;
- (void) subjectDidEndEditingForProperty: (NSString *)aKey;

/** @taskunit API Conveniency */

- (id) layout;

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
