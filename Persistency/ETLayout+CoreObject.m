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

- (NSString *) serializedAttachedTool
{
	return NSStringFromClass([[self attachedTool] class]);
}

- (void) setSerializedAttachedTool: (NSString *)aToolClassName
{
	[self setAttachedTool: [NSClassFromString(aToolClassName) tool]];
}

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

@end

@implementation ETFreeLayout (CoreObject)

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];

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

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];

	/* Must be executed once -awakeFromDeserialization has been called on subclasses such 
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

#endif
