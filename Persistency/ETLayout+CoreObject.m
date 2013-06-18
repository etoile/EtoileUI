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
#import "ETTableLayout.h"

@interface ETFreeLayout (CoreObject)
@end

@interface ETTableLayout (CoreObject)
@end

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

- (void) didLoad
{
	[super didLoad];

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

@end

@implementation ETWidgetLayout (CoreObject)

- (void) didLoad
{
	[super didLoad];

	/* Must be executed once -awakeFromFetch has been called on subclasses such 
	   as ETTableLayout, and the layout context is entirely deserialized and 
	   awaken.
	   Will call -[ETLayoutContext setLayoutView:]. */
	[self setUp];
}

@end

@implementation ETTableLayout (CoreObject)

- (NSDictionary *) serializedPropertyColumns
{
	NSMutableDictionary *unusedColumns = [NSMutableDictionary dictionary];
	NSTableView *tableView = [self tableView];

	for (NSString *key in _propertyColumns)
	{
		NSTableColumn *column = ([tableView tableColumnWithIdentifier: key]);

		if (column != nil)
			continue;

		[unusedColumns setObject: column forKey: key];
	}
	return unusedColumns;
}

- (void) awakeFromFetch
{
	ETAssert([self layoutView] != nil);

	[super awakeFromFetch];
	
	NSDictionary *deserializedPropertyColumns = RETAIN(_propertyColumns);

	/* The deserialized layout view is set on the ivar by 
	   -[COObject setSerializedValue:forProperty:] but -setLayoutView: is used 
	   as an intializer so we must call it to initialize the layout object.
	   We cannot implement -setSerializedLayoutView: because -setLayoutView: 
	   depends on _propertyColumns and overwrites it. */
	[self setLayoutView: [self layoutView]];
	ETAssert([[_propertyColumns allValues] containsCollection: [self allTableColumns]]);
	ETAssert(_sortable);

	/* Finish to populate _propertyColumns to take in account it can contain 
	   cached columns that are not used in the table/outline view currently. */
	for (NSString *key in deserializedPropertyColumns)
	{
		BOOL isUnusedColumn = ([_propertyColumns objectForKey: key] == nil);

		if (isUnusedColumn)
		{
			[_propertyColumns setObject: [deserializedPropertyColumns objectForKey: key]
			                     forKey: key];
		}
	}
}

@end

#endif
