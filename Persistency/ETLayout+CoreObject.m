/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
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

- (COObject *) serializedDelegate
{
	BOOL isPersistent = ([delegate isKindOfClass: [COObject class]]
		&& [(COObject *)delegate isPersistent]);

	NSAssert1(delegate == nil || isPersistent, @"ETLayoutItemGroup.delegate must "
		"be a persistent COObject and not a transient one: %@", delegate);

	return (isPersistent ? delegate : nil);
}

- (void) setSerializedDelegate: (COObject *)aDelegate
{
	NSParameterAssert(aDelegate == nil || [aDelegate isKindOfClass: [COObject class]]);
	// FIXME: Delegate should be retained in EtoileUI surely.
	delegate = aDelegate;
}

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];

	ASSIGN(_dropIndicator, [ETDropIndicator sharedInstanceForObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]]);
	_previousScaleFactor = 1.0;
}


/** Maps the layer item into the context. 
 
Can be overriden, but -setUp or -tearDown must never be called in this method, 
to avoid doing changes previously recorded in the object graph on 
-[ETLayoutItem setLayout:] or similar.

If -setUp was called, calling -[ETLayout resetLayoutSize] would break autoresizing,
-[ETWidgetLayout setUpLayoutView] wouldn't work without a layout context, or
-[ETCompositeLayout save/prepareInitialContextState:] would mess up the context, 
etc.
 
When overriding this method, the subclasses must call the superclass
implementation first usually, and the subclass implementation must contain 
the -setUp logic, that makes sense when deserializing an already set up layout 
or a layout without a context. */
- (void) didLoadObjectGraph
{
    _layoutContext = [self valueForVariableStorageKey: @"layoutContext"];
    if (_layoutContext != nil)
    {
    	[self mapLayerItemIntoLayoutContext];
    }
}

@end

@implementation ETFreeLayout (CoreObject)

- (void) didLoadObjectGraph
{
    /* Will call -mapLayerItemIntoLayoutContext to recreate the layer item */
	[super didLoadObjectGraph];

	//[self setAttachedTool: [ETSelectTool toolWithObjectGraphContext: [self objectGraphContext]]];
	[[[self attachedTool] ifResponds] setShouldProduceTranslateActions: YES];
	[[self layerItem] setActionHandler: nil];
	[[self layerItem] setCoverStyle: nil];

	if ([self layoutContext] == nil)
		return;

	/* Rebuild the handles to manipulate the item copies and not their originals */
	[self updateKVOForItems: [_layoutContext arrangedItems]];
	[self buildHandlesForItems: [_layoutContext arrangedItems]];
}

@end

@implementation ETWidgetLayout (CoreObject)

- (NSData *) serializedLayoutView
{
	return (layoutView != nil ? [NSKeyedArchiver archivedDataWithRootObject: layoutView] : nil);
}

- (void) setSerializedLayoutView: (NSData *)newViewData
{
	NSView *newView =
		(newViewData != nil ? [NSKeyedUnarchiver unarchiveObjectWithData: newViewData] : nil);

	NSParameterAssert([newView superview] == nil);

	ASSIGN(layoutView, newView);
}


/* For reloading the widget view, -[ETLayoutItem didLoadObjectGraph] could call 
-setNeedsLayoutUpdate. However we must ensure -setUp is called prior to the 
layout update, so calling -updateLayout in -[ETLayoutItemGroup didLoadObjectGraph] 
is not an option. */
- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];

    [[self layoutContext] setLayoutView: [self layoutView]];
	/* Force the content to get reloaded in the widget view */
	[(ETLayoutItemGroup *)[self layoutContext] updateLayout];
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

- (void) setSerializedPropertyColumns: (NSDictionary *)serializedColumns
{
	ASSIGN(_propertyColumns, AUTORELEASE([serializedColumns mutableCopy]));
}

- (void) awakeFromDeserialization
{
	ETAssert([self layoutView] != nil);

	[super awakeFromDeserialization];
	
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

@implementation ETTemplateItemLayout (CoreObject)

- (void) didLoadObjectGraph
{
	for (ETLayoutItem *item in _renderedItems)
	{
		ETAssert([item parentItem] == [self layoutContext]);
		[self setUpKVOForItem: item];
	}
}

@end
