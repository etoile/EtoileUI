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
#import <EtoileUI/ETGeometryTypes.h>
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
typedef NS_OPTIONS(NSUInteger, ETAutoresizing)
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
typedef NS_ENUM(NSUInteger, ETContentAspect)
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
};

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
	NSRect _boundingInsetsRect;
	NSSize _minSize;
	NSSize _maxSize;

	BOOL _flipped;
	BOOL _selected;
	BOOL _selectable;
	BOOL _exposed;
	BOOL _hidden;
	BOOL _isSyncingSupervisorViewGeometry;
	BOOL _scrollable; /* Used by ETLayoutItem+Scrollable */
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

- (instancetype) initWithView: (NSView *)view 
         coverStyle: (ETStyle *)aStyle 
      actionHandler: (ETActionHandler *)aHandler
 objectGraphContext: (COObjectGraphContext *)aContext NS_DESIGNATED_INITIALIZER;

/** @taskunit Description */

@property (nonatomic, readonly, copy) NSString *shortDescription;

/** @taskunit Navigating the Item Tree */

@property (nonatomic, readonly) id rootItem;
@property (nonatomic, readonly) ETLayoutItemGroup *controllerItem;
@property (nonatomic, readonly) ETLayoutItemGroup *sourceItem;

- (NSIndexPath *) indexPathFromItem: (ETLayoutItem *)item;
- (NSIndexPath *) indexPathForItem: (ETLayoutItem *)item;

/** @taskunit Parent Item */

/** The item group to which the receiver belongs to.
 
For the root item, returns nil.

If a host item is set, returns -hostItem. */
@property (nonatomic, readonly, weak) ETLayoutItemGroup *parentItem;

- (void) removeFromParent;

/** @taskunit Other Ancestor Items */

@property (nonatomic, readonly) id windowBackedAncestorItem;
@property (nonatomic, readonly) ETLayoutItemGroup *ancestorItemForOpaqueLayout;

/** @taskunit Name and Identifier */

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *displayName;

/** @taskunit Native Widget */

- (id) view;
- (void) setView: (NSView *)newView;
@property (nonatomic, readonly) BOOL usesWidgetView;
@property (nonatomic, readonly) id<ETWidget> widget;

/** @taskunit Image and Icon */

@property (nonatomic, copy) NSImage *image;
@property (nonatomic, copy) NSImage *icon;

- (NSImage *) snapshotFromRect: (NSRect)aRect;

/** @taskunit Presented Model */

@property (nonatomic, strong) id representedObject;
@property (nonatomic, readonly) id subject;
@property (nonatomic, readonly) BOOL isMetaItem;
@property (nonatomic, copy) NSString *valueKey;
@property (nonatomic) id value;

/** @taskunit Property-Value Coding */

@property (nonatomic, readonly) BOOL requiresKeyValueCodingForAccessingProperties;

- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;
- (ETItemValueTransformer *) valueTransformerForProperty: (NSString *)key;
- (void) setValueTransformer: (ETItemValueTransformer *)aValueTransformer
                 forProperty: (NSString *)key;

/** @taskunit Type Querying */

@property (nonatomic, readonly) BOOL isLayoutItem;
@property (nonatomic, readonly) BOOL isGroup;

/** @taskunit Selection and Visibility */

@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isSelectable) BOOL selectable;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, getter=isVisible, readonly) BOOL visible;

/** @taskunit Attached UTIs */

@property (nonatomic, readonly, copy) ETUTI *UTI;
@property (nonatomic, copy) ETUTI *subtype;

/** @taskunit Drawing */

- (NSRect) drawingBoundsForStyle: (ETStyle *)aStyle;
- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect 
      inContext: (id)ctxt;

/** @task Styles */

@property (nonatomic, strong) ETStyleGroup *styleGroup;

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

@property (nonatomic, readonly) ETScrollableAreaItem *scrollableAreaItem;
@property (nonatomic, readonly) ETWindowItem *windowItem;

/** @taskunit Outer Geometry */

@property (nonatomic) NSRect frame;
@property (nonatomic) NSPoint origin;
@property (nonatomic) NSPoint anchorPoint;
@property (nonatomic) NSPoint position;
@property (nonatomic) NSSize size;
@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;

/** The minimum size for the outer geometry. 

When no decorators are set, will be enforced by -[ETLayoutItem setContentBounds:] 
and any other methods updating the content bounds.

When decorators are set, will be enforced by the outmost decorator (not yet
implemented). */
@property (nonatomic) NSSize minSize;
/** The maximum size for the outer geometry.

When no decorators are set, will be enforced by -[ETLayoutItem setContentBounds:] 
and any other methods updating the content bounds.

When decorators are set, will be enforced by the outmost decorator (not yet
implemented). */
@property (nonatomic) NSSize maxSize;

/** @taskunit Adjusting Hit Test and Display Area */

/** The edget insets used to compute the bounding box from the receiver bounds. */
@property (nonatomic) ETEdgeInsets boundingInsets;
@property (nonatomic) NSRect boundingBox;

/** @taskunit Inner Geometry  */

@property (nonatomic) NSRect contentBounds;
- (void) setContentSize: (NSSize)size;
@property (nonatomic, copy) NSAffineTransform *transform;
@property (nonatomic, getter=isFlipped) BOOL flipped;

/** @taskunit Fixed Geometry */

@property (nonatomic) NSRect persistentFrame;

/** @taskunit Autoresizing and Content Aspect */

@property (nonatomic) ETAutoresizing autoresizingMask;
@property (nonatomic) ETContentAspect contentAspect;

- (NSRect) contentRectWithRect: (NSRect)aRect 
                 contentAspect: (ETContentAspect)anAspect 
                    boundsSize: (NSSize)maxSize;
- (void) sizeToFit;

/** @taskunit Filtering */

- (BOOL) matchesPredicate: (NSPredicate *)aPredicate;

/** @taskunit Actions */

@property (nonatomic, strong) id actionHandler;
@property (nonatomic, readonly) BOOL acceptsActions;
@property (nonatomic, assign) id target;
@property (nonatomic) SEL action;

- (BOOL) validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>)anItem;

/** @taskunit Editing */

- (void) beginEditing;
- (void) discardEditing;
- (BOOL) commitEditing;

- (void) subjectDidBeginEditingForProperty: (NSString *)aKey
                           fieldEditorItem: (ETLayoutItem *)aFieldEditorItem;
- (void) subjectDidEndEditingForProperty: (NSString *)aKey;

/** @taskunit API Conveniency */

@property (nonatomic, readonly, strong) id layout;

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
