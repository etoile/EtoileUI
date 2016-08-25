/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <AppKit/NSTextView.h>
#import "ETTokenLayout.h"
#import "ETBasicItemStyle.h"
#import "ETComputedLayout.h"
#import "ETController.h"
#import "ETGeometry.h"
#import "ETEvent.h"
#import "ETIconLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "EtoileUIProperties.h"
#import "ETSelectTool.h"
#import "ETCompatibility.h"


@implementation ETTokenLayout

@synthesize itemLabelFont = _itemLabelFont, maxTokenWidth = _maxTokenWidth;

/** <init />
Initializes and returns a new token layout. */
- (instancetype) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;
	
	_maxTokenWidth = [[self class] defaultMaxTokenWidth];

	[self setAttachedTool: [ETSelectAndClickTool toolWithObjectGraphContext: aContext]];
	[[self attachedTool] setShouldRemoveItemsAtPickTime: NO];
	[[self attachedTool] setIgnoresBackgroundClick: NO];

	ETLayoutItem *templateItem = [[ETLayoutItemFactory factoryWithObjectGraphContext: aContext] item];
	ETTokenStyle *tokenStyle = [[ETTokenStyle alloc] initWithObjectGraphContext: aContext];

	[self setTemplateItem: templateItem];
	[templateItem setCoverStyle: tokenStyle];
	[templateItem setActionHandler: [ETTokenActionHandler sharedInstanceForObjectGraphContext: aContext]];
	/* Will delegate the icon/image rect computation to the icon style rather 
	   than stretching it. */
	[templateItem setContentAspect: ETContentAspectComputed];
	/* Icon must precede Style and View to let us snapshot the item in its 
	   initial state. See -setUpTemplateElementWithNewValue:forKey:inItem:
	   View must also be restored after Content Aspect, otherwise the view 
	   geometry computation occurs two times when the items are restored. */
	[self setTemplateKeys: A(@"icon", @"coverStyle", @"actionHandler", @"contentAspect", @"view")];

	[[self positionalLayout] setBorderMargin: 2];
	[[self positionalLayout] setItemMargin: 4];

	return self;
}

- (void) setUp: (BOOL)isDeserialization
{
	[super setUp: isDeserialization];

	// FIXME: Should use a new ETLayout API that memorizes the context state
	[(id)[self layoutContext] setActionHandler: [[ETTokenBackgroundActionHandler alloc] initWithObjectGraphContext: [self objectGraphContext]]];
}

- (void) tearDown
{
	[super tearDown];
	
	// TODO: Implement
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"picture--pencil.png"];
}

- (NSString *) editedProperty
{
	return [[[self templateItem] actionHandler] editedProperty];
}

- (void) setEditedProperty: (NSString *)aProperty
{
	[[[self templateItem] actionHandler] setEditedProperty: aProperty];
}

/** <override-dummy />
Returns the height used to size the token items.

By default, returns 20.

See also -setMaxTokenWidth:. */
+ (CGFloat) defaultTokenHeight
{
	return 18.;
}

/** Returns the minimum token width allowed.
 
See also -setMaxTokenWidth:. */
+ (CGFloat) defaultMinTokenWidth
{
	return 45.;
}

/** Returns 200.
 
 See also -setMaxTokenWidth:. */
+ (CGFloat) defaultMaxTokenWidth
{
	return 200.;
}

/* -[ETTemplateLayout renderLayoutItems:isNewContent:] doesn't invoke 
-resizeLayoutItems:toScaleFactor: unlike ETLayout, hence we override this method 
to trigger the resizing before ETTemplateItemLayout hands the items to the 
positional layout. */
- (void) willRenderItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	CGFloat scale = [[self layoutContext] itemScaleFactor];
	if (isNewContent || scale != _previousScaleFactor)
	{
		[self resizeItems: items toScaleFactor: scale];
		_previousScaleFactor = scale;
	}
}

/* Edge inset are not supported per edge, so we just use the width of 
   -boundingSizeForItem:imageOrViewSize:. However the height we use might not 
   always match the expectations of other methods such as 
   -[ETBasicItemStyle rectForLabel:inFrame:ofItem:]. For example, 
   ETLabelPositionCentered works fine, but other label positioning won't. */
- (CGFloat) tokenWidthForItem: (ETLayoutItem *)item tokenStyle: (ETTokenStyle *)tokenStyle
{
	CGFloat labelBasedWidth = [tokenStyle boundingSizeForItem: item
	                                          imageOrViewSize: NSZeroSize].width;
	
	if (labelBasedWidth > [self maxTokenWidth])
	{
		return [self maxTokenWidth];
	}
	else if (labelBasedWidth < [[self class] defaultMinTokenWidth])
	{
		return [[self class] defaultMinTokenWidth];
	}
	return labelBasedWidth;
}

/** Resizes every item by delegating it to 
 -[ETTokenStyle boundingSizeForItem:imageSize:].
 
For now, the scale factor is ignored.

Unlike the inherited implementation, the method ignores every ETLayout 
constraints that might be set such as -constrainedItemSize and 
-itemSizeConstraintStyle.

When the computed token width is greater than -maxTokenWidth, the latter value 
becomes the token width.

The resizing isn't delegated to the positional layout unlike in ETTemplateItemLayout. */
- (void) resizeItems: (NSArray *)items toScaleFactor: (CGFloat)factor
{
	id <ETFirstResponderSharingArea> responderArea = [[self contextItem] firstResponderSharingArea];

	/* We use -arrangedItems in case we receive only a subset to resize (not true currently) */
	if ([[[self layoutContext] arrangedItems] containsObject: [responderArea editedItem]])
	{
		[responderArea removeActiveFieldEditorItem];
	}

	ETTokenStyle *tokenStyle = [[self templateItem] coverStyle];
	CGFloat tokenHeight = [[self class] defaultTokenHeight];

	/* We expect all the items to use the same style object */
	//NSParameterAssert([[items firstObject] coverStyle] == tokenStyle);

	for (ETLayoutItem *item in items)
	{
		CGFloat tokenWidth = [self tokenWidthForItem: item tokenStyle: tokenStyle];
		[item setSize: NSMakeSize(tokenWidth, tokenHeight)];
	}
}

@end


@implementation ETTokenStyle

@synthesize tintColor = _tintColor;

+ (NSDictionary *) standardLabelAttributes
{
	return D([NSFont labelFontOfSize: 13], NSFontAttributeName);
}

+ (NSDictionary *) defaultSelectedLabelAttributes
{
	NSMutableDictionary *newAttributes = [[self standardLabelAttributes] mutableCopy];
	[newAttributes setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];
	return [newAttributes copy];
}

+ (NSColor *) defaultTintColor
{
	return [NSColor colorWithCalibratedRed: 0.5 green: 0.1 blue: 0.7 alpha: 0.8];
}

- (instancetype) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return self;

	_tintColor = [[self class] defaultTintColor];
	[self setSelectedLabelAttributes: [[self class] defaultSelectedLabelAttributes]];

	NSSize maxLabelSize = [self maxLabelSize];

	maxLabelSize.width = 150;
	[self setMaxLabelSize: maxLabelSize];
	[self setLabelPosition: ETLabelPositionCentered];
	[self setLabelMargin: 0];
	[self setEdgeInset: 7];

	return self;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"document-tag.png"];
}

/** Always returns the item display name. */
- (NSString *) labelForItem: (ETLayoutItem *)anItem
{
	return [anItem valueForProperty: kETDisplayNameProperty];
}

/** Always returns nil. */
- (NSImage *) imageForItem: (ETLayoutItem *)anItem
{
	return nil;
}

- (void) render: (NSMutableDictionary *)inputValues
     layoutItem: (ETLayoutItem *)item
	  dirtyRect: (NSRect)dirtyRect
{
	// TODO: Perhaps add a method -drawBackgroundInRect: to ETBasicItemStyle

	// FIXME: May be we should better support dirtyRect. The next drawing
	// methods don't take in account it and simply redraw all their content.
	NSRect bounds = [item drawingBoundsForStyle: self];
	NSString *itemLabel = [self labelForItem: item];

	[self drawRoundedTokenInRect: bounds
	                  isSelected: [self shouldDrawItemAsSelected: item]];

	if (nil != itemLabel)
	{
		// NOTE: For the label rect, see -[ETTokenLayout tokenWidthForItem:tokenStyle:]
		[self drawLabel: itemLabel
		     attributes: [self labelAttributesForDrawingItem: item]
		        flipped: [item isFlipped]
		         inRect: [self rectForLabel: itemLabel inFrame: bounds ofItem: item]];
	}
	
	/*if ([[[item firstResponderSharingArea] firstResponder] isEqual: item])
	{
		[self drawFirstResponderIndicatorInRect: bounds];
	}*/
}

/** Draws a rounded rectangle that covers the given rect area. */
 - (void) drawRoundedTokenInRect: (NSRect)aRect isSelected: (BOOL)isSelected
{
	[NSGraphicsContext saveGraphicsState];

	CGFloat radius = (aRect.size.height / 2);
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: NSInsetRect(aRect, 0.5, 0.5)
	                                                     xRadius: radius
	                                                     yRadius: radius * 1.5];

	if (isSelected)
	{
		[[_tintColor shadowWithLevel: 0.4] setFill];
		[path fill];
		[[_tintColor shadowWithLevel: 0.2] setStroke];
		[path stroke];
	}
	else
	{
		NSColor *highlightedTintColor = [_tintColor highlightWithLevel: 0.6];
	
		[highlightedTintColor setFill];
		[path fill];
		[[highlightedTintColor shadowWithLevel: 0.5] setStroke];
		[path stroke];
	}

	[NSGraphicsContext restoreGraphicsState];
}

@end


@implementation ETTokenActionHandler

@synthesize editedProperty = _editedProperty;

- (instancetype) init
{
	SUPERINIT
	_editedProperty = kETValueProperty;
	return self;
}

- (NSFont *) defaultFieldEditorFont
{
	return [NSFont labelFontOfSize: 13];
}

- (ETLayoutItem *) fieldEditorItem
{
	ETLayoutItem *fieldEditorItem = [super fieldEditorItem];
	[(NSTextView *)[fieldEditorItem view] setAlignment: NSCenterTextAlignment];
	return fieldEditorItem;
}

- (void) handleDoubleClickItem: (ETLayoutItem *)item
{
	NSRect labelRect = [item drawingBoundsForStyle: [item coverStyle]];

	[self beginEditingItem: item property: [self editedProperty] inRect: labelRect];
}

@end

@implementation ETTokenBackgroundActionHandler

- (NSFont *) defaultFieldEditorFont
{
	return [NSFont labelFontOfSize: 13];
}

- (ETLayoutItem *) fieldEditorItem
{
	ETLayoutItem *fieldEditorItem = [super fieldEditorItem];
	[(NSTextView *)[fieldEditorItem view] setDrawsBackground: NO];
	[(NSTextView *)[fieldEditorItem view] setFocusRingType: NSFocusRingTypeNone];
	return fieldEditorItem;
}

// TODO: Should work correctly if the item is not a group too.
- (void) handleClickItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint
{
	NSParameterAssert([[item layout] isKindOfClass: [ETTokenLayout class]]);

	if ([self isEditing])
		return;

	CGFloat labelWidth = [[[item layout] class] defaultMinTokenWidth] + 80;
	CGFloat labelHeight = [[[item layout] class] defaultTokenHeight];
	ETLayoutItem *lastItem = [(ETLayoutItemGroup *)item lastItem];
	NSPoint labelOrigin = NSZeroPoint;

	if (lastItem != nil)
	{
		id <ETComputableLayout> layout = [(ETTokenLayout *)[item layout] positionalLayout];
	
		labelOrigin.x = [lastItem x] + [lastItem width] + [layout itemMargin];
		labelOrigin.y = [lastItem y];
	}

	BOOL placeFieldEditorOnNewRow = ([item width] - labelOrigin.x < labelWidth);

	if (placeFieldEditorOnNewRow)
	{
		labelOrigin = NSMakePoint(0, [lastItem y] + [lastItem height]);
	}

	[self beginEditingItem: item
	              property: nil
	                inRect: NSMakeRect(labelOrigin.x, labelOrigin.y, labelWidth, labelHeight)];
}

/* Disable double-click behavior inherited from the superclass. */
- (void) handleDoubleClickItem: (ETLayoutItem *)item
{

}

// TODO: Should work correctly if the item is not a group too.
- (void) endEditingItem: (ETLayoutItem *)editedItem
{
	NSParameterAssert([[editedItem layout] isKindOfClass: [ETTokenLayout class]]);
	ETLayoutItem *fieldEditorItem =
		[[editedItem firstResponderSharingArea] activeFieldEditorItem];
	ETAssert(fieldEditorItem != nil);

	id value = [[[fieldEditorItem  view] string] copy];
	BOOL isValidValue = (value != nil && [value isEqual: @""] == NO);

	if (isValidValue)
	{
		ETController *controller = [[(ETLayoutItemGroup *)editedItem controllerItem] controller];

		// TODO: Attempt to handle the missing controller case transparently
		if (controller != nil)
		{
			[controller add: nil];
			
			ETLayoutItem *newItem = [[controller content] lastItem];
			NSString *editedProperty = [[editedItem layout] editedProperty];

			[[newItem subject] setValue: value forProperty: editedProperty];
			ETAssert([value isEqual: [[newItem subject] valueForProperty: editedProperty]]);
		}
		else
		{
			[(ETLayoutItemGroup *)editedItem addObject: value];
		}
	}

	[super endEditingItem: editedItem];
}

@end
