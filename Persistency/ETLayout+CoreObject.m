/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import "ETDropIndicator.h"
#import "ETFreeLayout.h"
#import "ETGeometry.h"
#import "ETLayout.h"
#import "ETLayoutItemGroup.h"
#import "ETTableLayout.h"
#import "ETTemplateItemLayout.h"
#import "ETSelectTool.h"

@implementation ETLayout (CoreObject)

- (NSValue *) serializedOldProposedLayoutSize
{
	if (NSEqualSizes(_oldProposedLayoutSize, [self proposedLayoutSize]))
		return [NSValue valueWithSize: ETNullSize];
 
	return [NSValue valueWithSize: _oldProposedLayoutSize];
}

- (void) setSerializedOldProposedLayoutSize: (NSValue *)aValue
{
	_oldProposedLayoutSize = [aValue sizeValue];
}

/** Maps the layer item into the context. 
 
Can be overriden, but -setUp or -tearDown must never be called in this method, 
to avoid doing changes previously recorded in the object graph on 
-[ETLayoutItem setLayout:] or similar.

If -setUp was called, calling -[ETLayout resetLayoutSize] would break autoresizing,
-[ETWidgetLayout setUpLayoutView] wouldn't work without a layout context, etc.
 
When overriding this method, the subclasses must call the superclass
implementation first usually, and the subclass implementation must contain 
the -setUp logic, that makes sense when deserializing an already set up layout 
or a layout without a context. */
- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];

	if (NSEqualSizes(_oldProposedLayoutSize, ETNullSize))
	{
		_oldProposedLayoutSize = [self proposedLayoutSize];
	}
	_layoutSize = [self proposedLayoutSize];
	_previousScaleFactor = ([self layoutContext] != nil ? [[self layoutContext] itemScaleFactor] : 1.0);

    if ([self layoutContext] == nil)
		return;
}

@end


@interface ETFreeLayout (CoreObject)
@end

@implementation ETFreeLayout (CoreObject)

/**
 * Will prevent KVO notifications to be received during the reloading.
 *
 * Unused items are retained by the object graph context until the next GC phase 
 * (e.g. on commit), so if we just wanted to discard invalid/outdated observed 
 * items, we could do it in -didLoadObjectGraph.
 */
- (void) willLoadObjectGraph
{
	[super willLoadObjectGraph];
	[self updateKVOForItems: [NSArray array]];
}

- (void) didLoadObjectGraph
{
    /* Will call -mapLayerItemIntoLayoutContext to recreate the layer item */
	[super didLoadObjectGraph];

	[[self layerItem] setActionHandler: nil];
	[[self layerItem] setCoverStyle: nil];

	if ([self layoutContext] == nil)
		return;

	/* Rebuild the handles to manipulate the item copies and not their originals */
	ETTool *activatableTool = [ETTool activatableToolForItem: [self contextItem]];

	[self updateKVOForItems: [[self layoutContext] arrangedItems]];

	if ([self showsHandlesForTool: activatableTool])
	{
		[self buildHandlesForItems: [[self layoutContext] arrangedItems]];
		_areHandlesHidden = NO;
	}
	else
	{
		_areHandlesHidden = YES;
	}
}

@end


@interface ETWidgetLayout (CoreObject)
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

	layoutView = newView;
}


/* For reloading the widget view, -[ETLayoutItem didLoadObjectGraph] could call 
-setNeedsLayoutUpdate. However we must ensure -setUp is called prior to the 
layout update, so calling -updateLayout in -[ETLayoutItemGroup didLoadObjectGraph] 
is not an option. */
- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];

	if ([self layoutContext] == nil)
		return;

	[self setUpLayoutView];
	/* Force the content to get reloaded in the widget view */
	[(ETLayoutItemGroup *)[self layoutContext] setNeedsLayoutUpdate];
}

@end


@interface ETTableLayout (CoreObject)
@end

@implementation ETTableLayout (CoreObject)

- (NSDictionary *) serializedPropertyColumns
{
	NSMutableDictionary *unusedColumns = [NSMutableDictionary dictionary];
	NSTableView *tableView = [self tableView];

	for (NSString *key in _propertyColumns)
	{
		NSTableColumn *column =  [_propertyColumns objectForKey: key];
		BOOL isUsed = ([tableView tableColumnWithIdentifier: key] != nil);

		if (isUsed)
		{
			ETAssert(column == [tableView tableColumnWithIdentifier: key]);
			continue;
		}
		
		[unusedColumns setObject: column forKey: key];
	}
	return unusedColumns;
}

- (void) setSerializedPropertyColumns: (NSDictionary *)serializedColumns
{
	_propertyColumns = [serializedColumns mutableCopy];
}

- (void) awakeFromDeserialization
{
	ETAssert([self layoutView] != nil);

	[super awakeFromDeserialization];
	
	NSDictionary *deserializedPropertyColumns = _propertyColumns;

	/* The table view is deserialized in layoutView ivar by CoreObject, but
	   the internal state related to the table view can only recreated by 
	   -setLayoutView:.
	   We cannot implement -setSerializedLayoutView: because -setLayoutView: 
	   depends on _propertyColumns and overwrites it. */
	[self setLayoutView: [self layoutView]];

	ETAssert([[_propertyColumns allValues] isEqual: [[self tableView] tableColumns]]);
	ETAssert([[_propertyColumns allValues] isEqual: [self allTableColumns]]);
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


@interface ETTemplateItemLayout (CoreObject)
@end

@implementation ETTemplateItemLayout (CoreObject)

#pragma mark Loading Notifications
#pragma mark -

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];
	[self prepareTransientState];
}

- (void) willLoadObjectGraph
{
	[super willLoadObjectGraph];

	/* Unapply external state changes related to the layout, usually during 
	   -[ETLayout setUp:], to support switching to a new layout (if the store 
	   item contains another UUID reference for the layout relationship) */
	[self setPositionalLayout: nil];
}

- (void) restoreLayoutFromDeserialization
{
	[_positionalLayout setUp: YES];

	// TODO: Remove
	for (ETLayoutItem *item in _renderedItems)
	{
		ETAssert([item parentItem] == [self layoutContext]);
		[self setUpKVOForItem: item];
	}

    [[self contextItem] setNeedsLayoutUpdate];
}

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];
	[self restoreLayoutFromDeserialization];
}

@end
