/** <title>ETLayoutItemGroup</title>

	<abstract>A layout item tree node which can contain arbitrary
	ETLayoutItem subclass instances.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETWidgetLayout.h>

@class ETController;

/** You must never subclass ETLayoutItemGroup. */
@interface ETLayoutItemGroup : ETLayoutItem <ETLayoutingContext, ETWidgetLayoutingContext, ETItemSelection, ETCollection, ETCollectionMutation>
{
	@private
	NSMutableArray *_items;
	NSMutableArray *_sortedItems;
	NSArray *_arrangedItems;
	ETLayout *_layout;
	NSImage *_cachedDisplayImage;
	SEL _doubleAction;
	BOOL _reloading; /* ivar used by ETMutationHandler category */
	BOOL _mutating; /* ivar used by ETMutationHandler category */
	BOOL _hasNewContent;
	BOOL _hasNewLayout;
	/* Indicates whether -arrangedItems has changed since the layout was last
       updated. Sets to YES when the receiver is filtered and/or sorted. */
	BOOL _hasNewArrangement;
	BOOL _shouldMutateRepresentedObject;
	BOOL _sorted;
	BOOL _filtered;
	BOOL _isLayerItem;
	/* We hide the supervisor view subviews when a display cache is set. We
	   must restore [[[self supervisorView] wrappedView] isHidden] correctly. */
	BOOL _wasViewHidden;
	BOOL _changingSelection;
}

/** @taskunit Traversing the Layout Item Tree */

- (ETLayoutItem *) itemAtIndexPath: (NSIndexPath *)path;
- (ETLayoutItem *) itemForIdentifier: (NSString *)anId;

/** @taskunit Debugging */

- (NSString *) descriptionWithProperty: (NSString *)aProperty arranged: (BOOL)usesArrangedItems;

/** @taskunit Accessing and Mutating Items */

- (void) addItem: (ETLayoutItem *)item;
- (void) insertItem: (ETLayoutItem *)item atIndex: (NSUInteger)index;
- (void) removeItem: (ETLayoutItem *)item;
- (void) removeItemAtIndex: (NSUInteger)index;
- (ETLayoutItem *) itemAtIndex: (NSInteger)index;

@property (nonatomic, readonly) ETLayoutItem *firstItem;
@property (nonatomic, readonly) ETLayoutItem *lastItem;

- (NSInteger) indexOfItem: (id)item;
- (BOOL) containsItem: (ETLayoutItem *)item;

@property (nonatomic, readonly) NSInteger numberOfItems;

- (void) addItems: (NSArray *)items;
- (void) removeItems: (NSArray *)items;
- (void) removeAllItems;

@property (nonatomic, readonly) NSArray *items;

/** @taskunit Accessing Descendant Items */

@property (nonatomic, readonly) NSArray *allDescendantItems;

- (BOOL) isDescendantItem: (ETLayoutItem *)anItem;

/** @taskunit Controlling Content Mutation and Item Providing */

@property (nonatomic) BOOL shouldMutateRepresentedObject;
@property (nonatomic, readonly) BOOL usesRepresentedObjectAsProvider;
@property (nonatomic) id source;

/** @@taskunit Reloading Items from Represented Object or Source */

- (void) reloadIfNeeded;
 
/** @taskunit Controller and Delegate */

@property (nonatomic, assign) COObject *delegate;
@property (nonatomic, strong) ETController *controller;

/** @taskunit Layout */

- (id) layout;
- (void) setLayout: (ETLayout *)layout;
- (void) didChangeLayout: (ETLayout *)oldLayout;
- (void) updateLayout;
- (void) updateLayoutRecursively: (BOOL)recursively;
- (void) updateLayoutIfNeeded;
@property (nonatomic, readonly) BOOL needsLayoutUpdate;
- (void) setNeedsLayoutUpdate;

/** @taskunit Item Scaling */

@property (nonatomic) CGFloat itemScaleFactor;

/** @taskunit Drawing */

- (void) render: (NSMutableDictionary *)inputValues
      dirtyRect: (NSRect)dirtyRect
      inContext: (id)ctxt;

/** @taskunit Selection */

@property (nonatomic) NSUInteger selectionIndex;
@property (nonatomic) NSIndexSet *selectionIndexes;
@property (nonatomic) NSArray *selectionIndexPaths;
@property (nonatomic, getter=isChangingSelection, readonly) BOOL changingSelection;

@property (nonatomic) NSArray *selectedItems;
@property (nonatomic, readonly) NSArray *selectedItemsInLayout;

/** @taskunit Sorting and Filtering */

- (void) sortWithSortDescriptors: (NSArray *)descriptors recursively: (BOOL)recursively;
- (void) filterWithPredicate: (NSPredicate *)predicate recursively: (BOOL)recursively;

@property (nonatomic, readonly) NSArray *arrangedItems;
@property (nonatomic, getter=isSorted, readonly) BOOL sorted;
@property (nonatomic, getter=isFiltered, readonly) BOOL filtered;

/** @taskunit Actions */

@property (nonatomic) SEL doubleAction;
@property (nonatomic, readonly) ETLayoutItem *doubleClickedItem;
@property (nonatomic, readonly) BOOL acceptsActionsForItemsOutsideOfFrame;

/** @taskunit Additions to ETCollectionMutation */

- (ETLayoutItem *) insertObject: (id)object
                        atIndex: (NSUInteger)index
                           hint: (id)hint
                   boxingForced: (BOOL)boxingForced;

/** @taskunit Layouting Context Protocol */

- (void) setLayoutView: (NSView *)aView;

@property (nonatomic, readonly) NSArray *visibleItems;
@property (nonatomic, copy) NSArray *exposedItems;
@property (nonatomic, readonly) NSSize visibleContentSize;

/** @taskunit Deprecated */

- (void) reloadAndUpdateLayout;

@end


/** Informal source protocol based on child index, which can be implemented
by the source object set with -[ETLayoutItemGroup setSource:]. */
@interface NSObject (ETLayoutItemGroupIndexSource)
- (int) baseItem: (ETLayoutItemGroup *)baseItem numberOfItemsInItemGroup: (ETLayoutItemGroup *)itemGroup;
- (ETLayoutItem *) baseItem: (ETLayoutItemGroup *)baseItem
                itemAtIndex: (NSUInteger)index
                inItemGroup: (ETLayoutItemGroup *)itemGroup;
@end

/** Additional methods that makes up the informal source protocol. */
@interface NSObject (ETLayoutItemGroupSource)
- (NSArray *) displayedItemPropertiesInItemGroup: (ETLayoutItemGroup *)itemGroup;
@end

/** Informal delegate protocol that can be implemented by the object set with
-[ETLayoutItemGroup setDelegate:]. */
@interface NSObject (ETLayoutItemGroupDelegate)
/** Delegate method that corresponds to ETItemGroupSelectionDidChangeNotification. */
- (void) itemGroupSelectionDidChange: (NSNotification *)notif;
- (ETWindowItem *) provideWindowItemForItemGroup: (ETLayoutItemGroup *)itemGroup;
@end

/** Notification posted by ETLayoutItemGroup and subclasses in reply to
selection change in the layout item tree connected to the poster object. The
poster object is always an item group and can be retrieved through
-[NSNotification object].

This notification is posted when a selection related method such as
-setSelectionIndexPaths: has been called on the object associated with the
notification, or when the selection is modified by the user, in this last case
the poster object will always be a base item. */
extern NSString * const ETItemGroupSelectionDidChangeNotification;
/** Notification observed by ETLayoutItemGroup and other classes
on which a source can be set. When the notification is received, the layout
item tree that belongs to the receiver is automatically reloaded.

This notification is only delivered when the poster is equal to the source
object of the observer.

You can use this method to trigger the reloading everywhere the poster object
is used as source, without having to know the involved objects directly and
explicitly invoke -reload on each object. */
extern NSString * const ETSourceDidUpdateNotification;
