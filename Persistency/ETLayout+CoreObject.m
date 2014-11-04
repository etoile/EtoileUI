/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import "ETCompositeLayout.h"
#import "ETDropIndicator.h"
#import "ETFreeLayout.h"
#import "ETLayout.h"
#import "ETLayoutItemGroup.h"
#import "ETPaneLayout.h"
#import "ETTableLayout.h"
#import "ETTemplateItemLayout.h"
#import "ETSelectTool.h"

@interface ETLayout (CoreObject)
@end

@implementation ETLayout (CoreObject)

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
	[super didLoadObjectGraph];

	_previousScaleFactor = ([self layoutContext] != nil ? [[self layoutContext] itemScaleFactor] : 1.0);

    if ([self layoutContext] != nil)
    {
    	[self mapLayerItemIntoLayoutContext];
		[self syncLayerItemGeometryWithSize: _layoutSize];
    }
}

@end


@interface ETFreeLayout (CoreObject)
@end

@implementation ETFreeLayout (CoreObject)

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


@interface ETTableLayout (CoreObject)
@end

@implementation ETTableLayout (CoreObject)

- (NSDictionary *) serializedPropertyColumns
{
	NSMutableDictionary *unusedColumns = [NSMutableDictionary dictionary];
	NSTableView *tableView = [self tableView];

	for (NSString *key in _propertyColumns)
	{
		NSTableColumn *column = ([tableView tableColumnWithIdentifier: key]);

        // FIXME: Should be 'column == nil'
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


@interface ETTemplateItemLayout (CoreObject)
@end

@implementation ETTemplateItemLayout (CoreObject)

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];

	for (ETLayoutItem *item in _renderedItems)
	{
		ETAssert([item parentItem] == [self layoutContext]);
		[self setUpKVOForItem: item];
	}
}

@end


@interface ETCompositeLayout (CoreObject)
@end

@implementation ETCompositeLayout (CoreObject)
@end


@interface ETPaneLayout (CoreObject)
@end

@implementation ETPaneLayout (CoreObject)

- (void) didLoadObjectGraph
{
    [super didLoadObjectGraph];

	/* Replicate the observer set up in -setBarItem: */
	[[NSNotificationCenter defaultCenter] 
		   addObserver: self
	          selector: @selector(itemGroupSelectionDidChange:)
		          name: ETItemGroupSelectionDidChangeNotification 
			    object: _barItem];
}

@end
