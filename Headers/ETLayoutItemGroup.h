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

@class ETController;


@interface ETLayoutItemGroup : ETLayoutItem <ETLayoutingContext, ETCollection, ETCollectionMutation>
{
	NSMutableArray *_layoutItems;
	NSMutableArray *_sortedItems;
	NSMutableArray *_arrangedItems;
	ETLayout *_layout;
	ETLayout *_stackedLayout;
	ETLayout *_unstackedLayout;
	SEL _doubleClickAction;
	BOOL _isStack;
	BOOL _autolayout;
	BOOL _usesLayoutBasedFrame;
	BOOL _reloading; /* ivar used by ETMutationHandler category */
	BOOL _hasNewContent;
	BOOL _hasNewLayout;
	BOOL _shouldMutateRepresentedObject;
	BOOL _sorted;
	BOOL _filtered;
}

+ (BOOL) isAutolayoutEnabled;
+ (void) enablesAutolayout;
+ (void) disablesAutolayout;

/* Initialization */

- (id) initWithItems: (NSArray *)layoutItems view: (NSView *)view;
- (id) initWithItems: (NSArray *)layoutItems view: (NSView *)view 
	value: (id)value representedObject: (id)repObject;

- (BOOL) isLayoutOwnedRootItem;

/* Traversing Layout Item Tree */

- (NSString *) pathForIndexPath: (NSIndexPath *)path;
- (NSIndexPath *) indexPathForPath: (NSString *)path;
- (ETLayoutItem *) itemAtIndexPath: (NSIndexPath *)path;
- (ETLayoutItem *) itemAtPath: (NSString *)path;

- (void) setRepresentedPathBase: (NSString *)aPath;

/*  Manipulating Layout Item Tree */

- (void) addItem: (ETLayoutItem *)item;
- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index;
- (void) removeItem: (ETLayoutItem *)item;
- (void) removeItemAtIndex: (int)index;
- (ETLayoutItem *) itemAtIndex: (int)index;
- (ETLayoutItem *) firstItem;
- (ETLayoutItem *) lastItem;
- (int) indexOfItem: (id)item;
- (BOOL) containsItem: (ETLayoutItem *)item;
- (int) numberOfItems;
//- (int) indexOfItem: (ETLayoutItem *)item;
- (void) addItems: (NSArray *)items;
- (void) removeItems: (NSArray *)items;
- (void) removeAllItems;
- (NSArray *) items;
- (NSArray *) itemsIncludingRelatedDescendants;
- (NSArray *) itemsIncludingAllDescendants;

- (BOOL) canReload;
- (void) reload;
- (void) reloadIfNeeded;

- (void) handleAttachItem: (ETLayoutItem *)item;
- (void) handleAttachViewOfItem: (ETLayoutItem *)item;
- (void) handleDetachItem: (ETLayoutItem *)item;
- (void) handleDetachViewOfItem: (ETLayoutItem *)item;

- (BOOL) shouldMutateRepresentedObject;
- (void) setShouldMutateRepresentedObject: (BOOL)flag;
- (BOOL) usesRepresentedObjectAsProvider;
- (id) source;
- (void) setSource: (id)source;
- (id) delegate;
- (void) setDelegate: (id)delegate;
- (ETController *) controller;
- (void) setController: (ETController *)aController;

/* Layout */

- (ETLayout *) layout;
- (void) setLayout: (ETLayout *)layout;

//-reloadAndUpdateAll;
- (void) reloadAndUpdateLayout;
- (void) updateLayout;
- (BOOL) canUpdateLayout;
// FIXME: Implement methods below
/*- (BOOL) canApplyLayout; // would replace -canUpdateLayout
- (void) applyLayout;
- (void) setNeedsLayout: (BOOL)needsLayout;*/

- (BOOL) isAutolayout;
- (void) setAutolayout: (BOOL)flag;
- (BOOL) usesLayoutBasedFrame;
- (void) setUsesLayoutBasedFrame: (BOOL)flag;

/* Layouting Context Protocol */

- (void) setLayoutView: (NSView *)aView;
- (NSArray *) visibleItems;
- (void) setVisibleItems: (NSArray *)items;
- (NSArray *) visibleItemsForItems: (NSArray *)items;
- (void) setVisibleItems: (NSArray *)visibleItems forItems: (NSArray *)items;
- (NSSize) size;
- (void) setSize: (NSSize)size;
- (NSView *) view;
- (NSSize) visibleContentSize;
- (void) setContentSize: (NSSize)size;
- (BOOL) isScrollViewShown;

/* Item scaling */

- (float) itemScaleFactor;
- (void) setItemScaleFactor: (float)aFactor;

/* Rendering */

- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect 
      inContext: (id)ctxt;

/* Stacking */

- (ETLayout *) stackedItemLayout;
- (void) setStackedItemLayout: (ETLayout *)layout;
- (ETLayout *) unstackedItemLayout;
- (void) setUnstackedItemLayout: (ETLayout *)layout;

- (void) setIsStack: (BOOL)flag;
- (BOOL) isStack;
- (BOOL) isStacked;

- (void) stack;
- (void) unstack;

/* Selection */

- (unsigned int) selectionIndex;
- (void) setSelectionIndex: (unsigned int)index;
- (NSMutableIndexSet *) selectionIndexes;
- (void) setSelectionIndexes: (NSIndexSet *)indexes;
- (NSArray *) selectionIndexPaths;
- (void) setSelectionIndexPaths: (NSArray *)indexPaths;
- (void) didChangeSelection;

- (NSArray *) selectedItems;
- (NSArray *) selectedItemsInLayout;
- (NSArray *) selectedItemsIncludingRelatedDescendants;
- (NSArray *) selectedItemsIncludingAllDescendants;

/* Sorting and Filtering */

- (void) sortWithSortDescriptors: (NSArray *)descriptors recursively: (BOOL)recursively;
- (void) filterWithPredicate: (NSPredicate *)predicate recursively: (BOOL)recursively;
- (NSArray *) arrangedItems;
- (BOOL) isSorted;
- (BOOL) isFiltered;

/* Actions */

- (void) setDoubleAction: (SEL)selector;
- (SEL) doubleAction;
- (ETLayoutItem *) doubleClickedItem;
- (BOOL) acceptsActionsForItemsOutsideOfFrame;

/* Collection Protocol */

- (BOOL) isOrdered;
- (BOOL) isEmpty;
- (unsigned int) count;
- (id) content;
- (NSArray *) contentArray;
- (void) addObject: (id)object;
- (void) removeObject: (id)object;

/* Deprecated (DO NOT USE, WILL BE REMOVED LATER) */

@end


/** Informal flat source protocol based on child index, which can be implemented 
by the source object set with -[ETLayoutItemGroup setSource:]. */
@interface NSObject (ETLayoutItemGroupIndexSource)

- (int) numberOfItemsInItemGroup: (ETLayoutItemGroup *)baseItem;
- (ETLayoutItem *) itemGroup: (ETLayoutItemGroup *)baseItem itemAtIndex: (int)index;

@end
		
/** Informal tree source protocol based on index path, which can be implemented 
by the source object set with -[ETLayoutItemGroup setSource:]. */
@interface NSObject (ETLayoutItemGroupPathSource)

- (int) itemGroup: (ETLayoutItemGroup *)baseItem
	numberOfItemsAtPath: (NSIndexPath *)indexPath;
- (ETLayoutItem *) itemGroup: (ETLayoutItemGroup *)baseItem 
	itemAtPath: (NSIndexPath *)indexPath;

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
extern NSString *ETItemGroupSelectionDidChangeNotification;
/** Notification observed by ETLayoutItemGroup, ETUIMediator and other classes 
on which a source can be set. When the notification is received, the layout 
item tree that belongs to the receiver is automatically reloaded. 

This notification is only delivered when the poster is equal to the source 
object of the observer.

You can use this method to trigger the reloading everywhere the poster object 
is used as source, without having to know the involved objects directly and 
explicitly invoke -reload on each object. */
extern NSString *ETSourceDidUpdateNotification;

// TODO: Documentation to be reused somewhere...
/* In this case, each time the user enters a new level, you are in charge of
removing then adding the proper items which are associated with the level
requested by the user. Implementing a data source, alleviates you from this
task, you simply need to return the items, EtoileUI will build takes care of
building and managing the tree structure. To set a represented path base, turns
the item group into an entry point in your model, */
