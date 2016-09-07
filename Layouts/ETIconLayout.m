/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import "ETIconLayout.h"
#import "ETBasicItemStyle.h"
#import "ETComputedLayout.h"
#import "ETEvent.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Private.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "EtoileUIProperties.h"
// FIXME: Add -sizeWithAttributes: or similar to the AppKit graphics backend
#import "ETWidgetBackend.h"
#import "ETCompatibility.h"


@implementation ETIconLayout

/** <init />
Initializes and returns a new icon layout. */
- (instancetype) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;
	
	_iconSizeForScaleFactorUnit = NSMakeSize(32, 32);
	_minIconSize = NSMakeSize(16, 16);

	[self setAttachedTool: [ETSelectAndClickTool toolWithObjectGraphContext: aContext]];
	[[self attachedTool] setShouldRemoveItemsAtPickTime: NO];

	ETLayoutItem *templateItem =
		[[ETLayoutItemFactory factoryWithObjectGraphContext: aContext] item];
	ETIconAndLabelStyle *iconStyle =
		[[ETIconAndLabelStyle alloc] initWithObjectGraphContext: aContext];

	[self setTemplateItem: templateItem];
	[templateItem setCoverStyle: iconStyle];
	[templateItem setActionHandler: [ETIconAndLabelActionHandler sharedInstanceForObjectGraphContext: aContext]];
	/* Will delegate the icon/image rect computation to the icon style rather 
	   than stretching it. */
	[templateItem setContentAspect: ETContentAspectComputed];
	/* Icon must precede Style and View to let us snapshot the item in its 
	   initial state. See -setUpTemplateElementWithNewValue:forKey:inItem:
	   View must also be restored after Content Aspect, otherwise the view 
	   geometry computation occurs two times when the items are restored. */
	// FIXME: When View comes before Content Aspect an assertion is raised.
	[self setTemplateKeys: @[@"icon", @"coverStyle", @"actionHandler", @"contentAspect", @"view"]];

	return self;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"picture--pencil.png"];
}

- (void) setUpTemplateElementWithNewValue: (id)templateValue
                                   forKey: (NSString *)aKey
                                   inItem: (ETLayoutItem *)anItem
{
	if ([aKey isEqualToString: kETIconProperty])
	{
		/* Generate/retrieve the icon with -icon and cache it with -setIcon:.
		   Once the item view/style is removed, we cannot generate the icon lazily. */
		[anItem setIcon: [anItem icon]];
	}
	else
	{
		[super setUpTemplateElementWithNewValue: templateValue 
		                                 forKey: aKey 
		                                 inItem: anItem];
	}

}

/* Mainly useful for debugging... */
- (void) setUpTemplateElementsForItem: (ETLayoutItem *)item
{
	[super setUpTemplateElementsForItem: item];

	//[item setFrame: [[item coverStyle] boundingFrameForItem: item]];
	// FIXME: Shouldn't be needed if we set on the template view already
	[item setAutoresizingMask: NSViewNotSizable | NSViewMinYMargin | NSViewMinXMargin |	NSViewMaxXMargin | NSViewMaxYMargin];
}

- (void) prepareNewItems: (NSArray *)items
{
	/* We insert the item display views into the view hierarchy to let us take a
	   snapshot with -icon */
	self.layoutContext.exposedItems = items;

	[super prepareNewItems: items];

	self.layoutContext.exposedItems = @[];
}

- (void) setItemTitleFont: (NSFont *)font
{
	_itemLabelFont = font;
	[self renderAndInvalidateDisplay];
}

/** Returns the icon size used when the scale factor is equal to 1. 

By default, returns (32, 32).

See also -setIconSizeForScaleFactorUnit. */
- (NSSize) iconSizeForScaleFactorUnit
{
	return _iconSizeForScaleFactorUnit;
}

/** Sets the icon size used when the scale factor is equal to 1.

This icon size is used a base to compute the new item size every time the item 
scale factor changed.

See also -iconSizeForScaleFactorUnit. */
- (void) setIconSizeForScaleFactorUnit: (NSSize)aSize
{
	[self willChangeValueForProperty: @"iconSizeForScaleFactorUnit"];
	_iconSizeForScaleFactorUnit = aSize;
	[self renderAndInvalidateDisplay];
	[self didChangeValueForProperty: @"iconSizeForScaleFactorUnit"];
}

/** Returns the mininum icon size allowed.

By default, returns (16, 16).

See also -resizeLayoutItems:toScaleFactor:. */
- (NSSize) minIconSize
{
	return _minIconSize;
}

/** Sets the mininum icon size allowed. 

See also -minIconSize. */
- (void) setMinIconSize: (NSSize)aSize
{
	[self willChangeValueForProperty: @"minIconSize"];
	_minIconSize = aSize;
	[self renderAndInvalidateDisplay];
	[self didChangeValueForProperty: @"minIconSize"];
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

/** Resizes every item to the given scale by delegating it to 
-[ETIconAndLabelStyle boundingSizeForItem:imageSize:].

Unlike the inherited implementation, the method ignores every ETLayout 
constraints that might be set such as -constrainedItemSize and 
-itemSizeConstraintStyle.<br />
However when the scaled icon size is smaller than -minIconSize, this latter 
value becomes the image size used to compute to the new item size.

The resizing isn't delegated to the positional layout unlike in ETTemplateItemLayout. */
- (void) resizeItems: (NSArray *)items toScaleFactor: (CGFloat)factor
{
	id <ETFirstResponderSharingArea> responderArea = [[self contextItem] firstResponderSharingArea];

	/* We use -arrangedItems in case we receive only a subset to resize (not true currently) */
	if ([[[self layoutContext] arrangedItems] containsObject: [responderArea editedItem]])
	{
		[responderArea removeActiveFieldEditorItem];
	}

	ETIconAndLabelStyle *iconStyle = [[self templateItem] coverStyle];

	/* We expect all the items to use the same style object */
	//NSParameterAssert([[items firstObject] coverStyle] == iconStyle);
	
	/* Scaling is always computed from the base image size (scaleFactor equal to 
	   1) in order to avoid rounding error that would increase on each scale change. */
	CGFloat iconWidth = MAX(_iconSizeForScaleFactorUnit.width * factor, _minIconSize.width);
	CGFloat iconHeight = MAX(_iconSizeForScaleFactorUnit.height * factor, _minIconSize.height);
	NSSize iconSize = NSMakeSize(iconWidth, iconHeight);

	// TODO: We need to reduce the label margin when the icon size drops below 
	// 32 * 32.
	//[iconStyle setLabelMargin: 8];
	//[iconStyle setMaxImageSize: iconSize];

	for (ETLayoutItem *item in items)
	{

		[item setSize: [iconStyle boundingSizeForItem: item imageOrViewSize: iconSize]];
	}
}

@end


@implementation ETIconAndLabelStyle

+ (NSDictionary *) standardLabelAttributes
{
	return @{ NSFontAttributeName: [NSFont labelFontOfSize: 12] };
}

- (instancetype) init
{
	SUPERINIT

	NSSize maxLabelSize = [self maxLabelSize];

	maxLabelSize.width = 150;
	[self setMaxLabelSize: maxLabelSize];
	[self setLabelPosition: ETLabelPositionInsideBottom];
	[self setLabelMargin: 8];
	[self setEdgeInset: 7];

	return self;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"picture--pencil.png"];
}

/** Always returns the item display name. */
- (NSString *) labelForItem: (ETLayoutItem *)anItem
{
	return [anItem displayName];
}

/** Always returns the item icon. */
- (NSImage *) imageForItem: (ETLayoutItem *)anItem
{
	return [anItem icon];
}

- (NSRect) rectForImage: (NSImage *)anImage 
                 ofItem: (ETLayoutItem *)anItem
          withLabelRect: (NSRect)labelRect
{
	NSRect rect = [super rectForImage: anImage ofItem: anItem withLabelRect: labelRect];
	//ETLog(@"Image size %@ to %@", NSStringFromSize([anImage size]), NSStringFromRect(rect));
	return rect;
}

/** Draws a selection indicator that covers the icon area which is smaller than 
the given indicator rect. */
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect
{
	// TODO: We need to reduce the offset amount when the icon size drops below 
	// 32 * 32. We can check the -imageMaxSize sets by ETIconLayout to do so.
	NSRect iconSelectionRect = NSInsetRect([self currentImageRect], -4, -4);

	/* We don't use a rounded rect. We could use one and make it look good...
	   The radius would have to be be reduced in a more or less linear way below 
	   64 * 64 and become 0 at 16 * 16.

	NSBezierPath *roundedRectPath = 
		[NSBezierPath bezierPathWithRoundedRect: rect xRadius: 7 yRadius: 7]; */

	[[[NSColor lightGrayColor] colorWithAlphaComponent: 0.5] setFill];
	[NSBezierPath fillRect: iconSelectionRect];

	NSRect labelSelectionRect = NSInsetRect([self currentLabelRect], -7, -1);	
	NSBezierPath *labelSelectionRectPath = 
		[NSBezierPath bezierPathWithRoundedRect: labelSelectionRect xRadius: 9 yRadius: 9];

	[labelSelectionRectPath fill];
}

@end


@implementation ETIconAndLabelActionHandler

- (NSFont *) defaultFieldEditorFont
{
	return [NSFont labelFontOfSize: 12];
}

- (void) handleClickItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint
{
	ETBasicItemStyle *iconStyle = [item coverStyle];
	NSString *label = [iconStyle labelForItem: item];
	NSRect labelRect = [iconStyle rectForLabel: label
	                                   inFrame: [item frame]
	                                    ofItem: item];

	if (NSPointInRect(aPoint, labelRect) == NO)
		return;								

	NSSize labelSize = [label sizeWithAttributes: [iconStyle labelAttributes]];
	CGFloat lineHeight = labelSize.height;
	BOOL nbOfLines = 1;

	/* Limit the editing width to the max label width */
	if (labelSize.width > labelRect.size.width)
	{
		labelSize.width = labelRect.size.width;
		nbOfLines = 2;
		labelSize.height = lineHeight * nbOfLines; /* Add an extra line */
	}

	/* We need some extra width to fit the label into the field editor */
	labelSize.width += 11;

	/* Resize the field editor and compute its new location */
	labelRect.origin.x -= (labelSize.width - labelRect.size.width) * 0.5;
	// TODO: To be compensated in -beginEditingItem:property:inRect: when 
	// the window backed item is flipped.
	if ([item isFlipped] == NO)
	{
		labelRect.origin.y -= lineHeight * (nbOfLines - 1);
	}
	labelRect.size = labelSize;

	[self beginEditingItem: item property: kETNameProperty inRect: labelRect];
}

@end


@implementation ETSelectAndClickTool

- (instancetype) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	_ignoresBackgroundClick = YES;
	return self;
}

- (BOOL) ignoresBackgroundClick
{
	return _ignoresBackgroundClick;
}

- (void) setIgnoresBackgroundClick: (BOOL)noBackgroundClick
{
	[self willChangeValueForProperty: @"ignoresBackgroundClick"];
	_ignoresBackgroundClick = noBackgroundClick;
	[self didChangeValueForProperty: @"ignoresBackgroundClick"];
}

- (void) handleClickWithEvent: (ETEvent *)anEvent
{
	[self alterSelectionWithEvent: anEvent];

	ETLayoutItem *item = [self hitTestWithEvent: anEvent];

	// NOTE: May be replace next line by ([[item layout] isEqual: [self layoutOwner]);
	BOOL backgroundClick = ([item isEqual: [self targetItem]]);
	
	if (backgroundClick && [self ignoresBackgroundClick])
		return;

	/* Allow to edit the item label or open the item */
	if ([anEvent clickCount] == 1)
	{
		[[item actionHandler] handleClickItem: item atPoint: [anEvent locationInLayoutItem]];
	}
	else if ([anEvent clickCount] == 2)
	{
		[[item actionHandler] handleDoubleClickItem: item];	
	}
}

@end
