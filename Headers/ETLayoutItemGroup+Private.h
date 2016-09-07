/**
	Copyright (C) 2016 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  August 2016
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileUI/ETLayoutItemGroup.h>

@interface ETLayoutItemGroup ()

/** @task Reloading Descendant Items */

@property (nonatomic, readonly) BOOL canReload;

- (void) reload;

/** @taskunit Mutation Callbacks */

- (void) attachItems: (NSArray *)items atIndexes: (NSIndexSet *)indexes;
- (void) detachItems: (NSArray *)items atIndexes: (NSIndexSet *)indexes;
- (void) updateExposedViewsForItems: (NSArray *)items
                     exposedIndexes: (NSIndexSet *)exposedIndexes
                   unexposedIndexes: (NSIndexSet *)unexposedIndexes;
- (void) setUpSupervisorViewsForNewItemsIfNeeded: (NSArray *)items;

/** @taskunit Mutation Notifications */

- (void) didAttachItem: (ETLayoutItem *)item;
- (void) didDetachItem: (ETLayoutItem *)item;

/** @taskunit Selection Notifications */

- (void) didChangeSelection;

/** @taskunit Layer Support */

- (instancetype) initAsLayerItemWithObjectGraphContext: (COObjectGraphContext *)aContext;

@property (nonatomic, readonly) BOOL isLayerItem;

@end
