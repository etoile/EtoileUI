/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"

#ifdef COREOBJECT

#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import "ETLayout+CoreObject.h"
#import "ETLayoutItemGroup.h"
#import "ETSelectTool.h"

@implementation ETLayout (CoreObject)

- (void) becomePersistentInContext: (COPersistentRoot *)aContext
{
	if ([self isPersistent])
		return;

	[super becomePersistentInContext: aContext];

	// TODO: Leverage the model description rather than hardcoding the aspects
	// TODO: Implement some strategy to recover in the case these aspects 
	// are already used as embedded objects in another root object. 
	//ETAssert([[self dropIndicator] isPersistent] == NO || [[self dropIndicator] isRoot]);
	//[[self dropIndicator] becomePersistentInContext: aContext];
}

- (NSString *) serializedAttachedTool
{
	return NSStringFromClass([[self attachedTool] class]);
}

- (void) setSerializedAttachedTool: (NSString *)aToolClassName
{
	[self setAttachedTool: [NSClassFromString(aToolClassName) tool]];
}

- (void) awakeFromFetch
{
	[super awakeFromFetch];

	ASSIGN(_dropIndicator, [ETDropIndicator sharedInstance]);
	_previousScaleFactor = 1.0;
}

@end

@implementation ETFreeLayout (CoreObject)

- (void) awakeFromFetch
{
	[super awakeFromFetch];

	//[self setAttachedTool: [ETSelectTool tool]];
	[[[self attachedTool] ifResponds] setShouldProduceTranslateActions: YES];
	[[self layerItem] setActionHandler: nil];
	[[self layerItem] setCoverStyle: nil];

	/* Because the layer item is recreated, it must be installed too (see -[ETLayout setUp]) */
	[self mapLayerItemIntoLayoutContext];

	/* Rebuild the handles to manipulate the item copies and not their originals */
	[self updateKVOForItems: [_layoutContext arrangedItems]];
	[self buildHandlesForItems: [_layoutContext arrangedItems]];
}

- (void) didReload
{
	/* Rebuild the handles to manipulate the item copies and not their originals */
	[self updateKVOForItems: [_layoutContext arrangedItems]];
	[self buildHandlesForItems: [_layoutContext arrangedItems]];
}

@end

#endif
