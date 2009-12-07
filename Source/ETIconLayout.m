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
#import "ETLayoutItem+Factory.h"
#import "EtoileUIProperties.h"
#import "ETSelectTool.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

// TODO: Find a better name...
@interface ETSelectAndClickTool : ETSelectTool
@end


@implementation ETIconLayout

/** <init />
Initializes and returns a new icon layout. */
- (id) init
{
	SUPERINIT
	
	_iconSizeForScaleFactorUnit = NSMakeSize(32, 32);
	_minIconSize = NSMakeSize(16, 16);

	[self setAttachedInstrument: [ETSelectAndClickTool instrument]];

	ETLayoutItem *templateItem = [ETLayoutItem item];
	ETIconAndLabelStyle *iconStyle = AUTORELEASE([[ETIconAndLabelStyle alloc] init]);

	[self setTemplateItem: templateItem];
	[templateItem setStyle: iconStyle];
	[templateItem setActionHandler: [ETIconAndLabelActionHandler sharedInstance]];
	/* Will delegate the icon/image rect computation to the icon style rather 
	   than stretching it. */
	[templateItem setContentAspect: ETContentAspectComputed];
	/* Icon must precede Style and View to let us snapshot the item in its 
	   initial state. See -setUpTemplateElementWithNewValue:forKey:inItem:
	   View must also be restored after Content Aspect, otherwise the view 
	   geometry computation occurs two times when the items are restored. */
	// FIXME: When View comes before Content Aspect an assertion is raised.
	[self setTemplateKeys: A(@"icon", @"style", @"actionHandler", @"contentAspect", @"view")];

	return self;
}

DEALLOC(DESTROY(_itemLabelFont))

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETIconLayout *layoutCopy = 	[super copyWithZone: aZone layoutContext: ctxt];
	
	layoutCopy->_itemLabelFont = [_itemLabelFont copyWithZone: aZone];
	layoutCopy->_iconSizeForScaleFactorUnit = _iconSizeForScaleFactorUnit;
	layoutCopy->_minIconSize = _minIconSize;

	return layoutCopy;
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
	/* We insert the item display view into the view hierarchy to let us take a 
	   snapshot with -icon */
	[item setVisible: YES];

	if (_localBindings != nil)
	{
		[super setUpTemplateElementsForItem: item];
	}
	else
	{
		ETLog(@"WARNING: Bindings missing in %@", self);
	}

	[item setVisible: NO];

	//[item setFrame: [[item style] boundingFrameForItem: item]];
	// FIXME: Shouldn't be needed if we set on the template view already
	[item setAutoresizingMask: NSViewNotSizable | NSViewMinYMargin | NSViewMinXMargin |	NSViewMaxXMargin | NSViewMaxYMargin];
}

- (void) setItemTitleFont: (NSFont *)font
{
	ASSIGN(_itemLabelFont, font);
}

/* Always returns 1 to prevent the positional layout to resize the items, the 
icon layout does it in its own way by overriding -resizeLayoutItems:toScaleFactor:. */
- (float) itemScaleFactor
{
	return 1;
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
	_iconSizeForScaleFactorUnit = aSize;
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
	_minIconSize = aSize;
}

/* -[ETTemplateLayout renderLayoutItems:isNewContent:] doesn't invoke 
-resizeLayoutItems:toScaleFactor: unlike ETLayout, hence we override this method 
to trigger the resizing before ETTemplateItemLayout hands the items to the 
positional layout. */
- (void) willRenderItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	float scale = [_layoutContext itemScaleFactor];
	if (isNewContent || scale != _previousScaleFactor)
	{
		[self resizeLayoutItems: items toScaleFactor: scale];
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
- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	id <ETFirstResponderSharingArea> editionCoordinator = 
		[[ETInstrument activeInstrument] editionCoordinatorForItem: _layoutContext];

	/* We use -arrangedItems in case we receive only a subset to resize (not true currently) */
	if ([[_layoutContext arrangedItems] containsObject: [editionCoordinator editedItem]])
	{
		[editionCoordinator removeActiveFieldEditorItem];
	}

	ETIconAndLabelStyle *iconStyle = [[self templateItem] style];

	/* We expect all the items to use the same style object */
	//NSParameterAssert([[items firstObject] style] == iconStyle);
	
	/* Scaling is always computed from the base image size (scaleFactor equal to 
	   1) in order to avoid rounding error that would increase on each scale change. */
	float iconWidth = MAX(_iconSizeForScaleFactorUnit.width * factor, _minIconSize.width);
	float iconHeight = MAX(_iconSizeForScaleFactorUnit.height * factor, _minIconSize.height);
	NSSize iconSize = NSMakeSize(iconWidth, iconHeight);

	// TODO: We need to reduce the label margin when the icon size drops below 
	// 32 * 32.
	//[iconStyle setLabelMargin: 8];
	//[iconStyle setMaxImageSize: iconSize];

	FOREACH(items, item, ETLayoutItem *)
	{

		[item setSize: [iconStyle boundingSizeForItem: item imageSize: iconSize]];
	}
}

@end


@implementation ETIconAndLabelStyle

+ (NSDictionary *) standardLabelAttributes
{
	return D([NSFont labelFontOfSize: 12], NSFontAttributeName);
}

- (id) init
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
	ETBasicItemStyle *iconStyle = [item style];
	NSString *label = [iconStyle labelForItem: item];
	NSRect labelRect = [iconStyle rectForLabel: label
	                                   inFrame: [item frame]
	                                    ofItem: item];

	if (NSPointInRect(aPoint, labelRect) == NO)
		return;								

	NSSize labelSize = [label sizeWithAttributes: [iconStyle labelAttributes]];
	float lineHeight = labelSize.height;
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

- (void) handleClickWithEvent: (ETEvent *)anEvent
{
	[self alterSelectionWithEvent: anEvent];

	ETLayoutItem *item = [self hitTestWithEvent: anEvent];

	// NOTE: May be replace next line by ([[item layout] isEqual: [self layoutOwner]);
	BOOL backgroundClick = ([item isEqual: [self targetItem]]);
	
	if (backgroundClick)
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
