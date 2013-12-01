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
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETWidgetLayout.h>

@class ETController;

/** You must never subclass ETLayoutItemGroup. */
@interface ETLayoutItemGroup : ETLayoutItem <ETLayoutingContext, ETWidgetLayoutingContext, ETItemSelection, ETCollection, ETCollectionMutation>
{
	@private
	NSMutableOrderedSet *_items;
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
- (ETLayoutItem *) firstItem;
- (ETLayoutItem *) lastItem;
- (NSInteger) indexOfItem: (id)item;
- (BOOL) containsItem: (ETLayoutItem *)item;
- (NSInteger) numberOfItems;
- (void) addItems: (NSArray *)items;
- (void) removeItems: (NSArray *)items;
- (void) removeAllItems;
- (NSArray *) items;

/** @taskunit Accessing Descendant Items */

- (NSArray *) descendantItemsSharingSameBaseItem;
- (NSArray *) allDescendantItems;
- (BOOL) isDescendantItem: (ETLayoutItem *)anItem;

/** @taskunit Controlling Content Mutation and Item Providing */

- (BOOL) shouldMutateRepresentedObject;
- (void) setShouldMutateRepresentedObject: (BOOL)flag;
- (BOOL) usesRepresentedObjectAsProvider;
- (id) source;
- (void) setSource: (id)source;

/** @@taskunit Reloading Items from Represented Object or Source */

- (void) reloadIfNeeded;
 
/** @taskunit Controller and Delegate */

- (id) delegate;
- (void) setDelegate: (id)delegate;
- (ETController *) controller;
- (void) setController: (ETController *)aController;

/** @taskunit Layout */

- (id) layout;
- (void) setLayout: (ETLayout *)layout;
- (void) updateLayout;
- (void) updateLayoutRecursively: (BOOL)recursively;

/** @taskunit Item Scaling */

- (CGFloat) itemScaleFactor;
- (void) setItemScaleFactor: (CGFloat)aFactor;

/** @taskunit Drawing */

- (void) render: (NSMutableDictionary *)inputValues
      dirtyRect: (NSRect)dirtyRect
      inContext: (id)ctxt;

/** @taskunit Selection */

- (NSUInteger) selectionIndex;
- (void) setSelectionIndex: (NSUInteger)index;
- (NSMutableIndexSet *) selectionIndexes;
- (void) setSelectionIndexes: (NSIndexSet *)indexes;
- (NSArray *) selectionIndexPaths;
- (void) setSelectionIndexPaths: (NSArray *)indexPaths;
- (BOOL) isChangingSelection;

- (NSArray *) selectedItems;
- (NSArray *) selectedItemsInLayout;
- (void) setSelectedItems: (NSArray *)items;

/** @taskunit Sorting and Filtering */

- (void) sortWithSortDescriptors: (NSArray *)descriptors recursively: (BOOL)recursively;
- (void) filterWithPredicate: (NSPredicate *)predicate recursively: (BOOL)recursively;
- (NSArray *) arrangedItems;
- (BOOL) isSorted;
- (BOOL) isFiltered;

/** @taskunit Actions */

- (void) setDoubleAction: (SEL)selector;
- (SEL) doubleAction;
- (ETLayoutItem *) doubleClickedItem;
- (BOOL) acceptsActionsForItemsOutsideOfFrame;

/** @taskunit Additions to ETCollectionMutation */

- (ETLayoutItem *) insertObject: (id)object
                        atIndex: (NSUInteger)index
                           hint: (id)hint
                   boxingForced: (BOOL)boxingForced;

/** @taskunit Layouting Context Protocol */

- (void) setLayoutView: (NSView *)aView;
- (NSArray *) visibleItems;
- (void) setVisibleItems: (NSArray *)items;
- (NSSize) visibleContentSize;

/** @taskunit Framework Private */

- (BOOL) canReload;
- (void) reload;
- (void) handleAttachItem: (ETLayoutItem *)item;
- (void) handleAttachViewOfItem: (ETLayoutItem *)item;
- (void) handleDetachItem: (ETLayoutItem *)item;
- (void) handleDetachViewOfItem: (ETLayoutItem *)item;
- (void) didChangeSelection;
- (id) initAsLayerItemWithObjectGraphContext: (COObjectGraphContext *)aContext;
- (BOOL) isLayerItem;

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
