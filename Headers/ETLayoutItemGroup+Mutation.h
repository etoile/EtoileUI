/** <title>ETLayoutItemGroup+Mutation</title>

	<abstract>Handling of Mutations on Layout Item Tree, Model Graph and Source.</abstract>
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItemGroup.h>

@class ETLayoutItem, ETEvent;

/* Private Header
   Don't use or override methods exposed here. */

/** All model mutations are triggered by implicit or explicit remove/insert/add 
in the layout item tree. Implicit mutations are done by the framework unlike 
explicit ones which are located in your code. These implicit mutations are 
triggered by a first explicit mutation, the only one that needs to be propagated 
to the model side. 

The only case of implicit mutation is presently add/insert that may trigger 
a remove. If a layout item is moved to a new parent item on insert or add, and 
this new parent that differs from the existing parent, the new parent will 
require that the item to be inserted removes itself from its existing parent, 
before truly inserting it.<br />
See -[ETLayoutItemGroup handleAttachItem:], -[ETLayoutItemGroup handleDetachItem:] 
and -isCoalescingModelMutation.
   
Take note, you can induce implicit mutations in your code if you write a 
subclass for ETLayoutItem (or other related subclasses) and you call methods 
like -addItem, removeItem:, -insertItem:atIndex: etc. */
@interface ETLayoutItemGroup (ETMutationHandler)

/** @taskunit Mutation Coordination */

- (BOOL) hasNewContent;
- (void) setHasNewContent: (BOOL)flag;
- (void) didChangeContentWithMoreComing: (BOOL)moreComing;
- (BOOL) isCoalescingModelMutation;
- (void) beginCoalescingModelMutation;
- (void) endCoalescingModelMutation;
- (BOOL) beginMutate;
- (void) endMutate: (BOOL)wasAutolayoutEnabled;

/** @taskunit Mutation Actions */

- (void) handleAddItem: (ETLayoutItem *)item moreComing: (BOOL)moreComing;
- (void) handleInsertItem: (ETLayoutItem *)item atIndex: (int)index moreComing: (BOOL)moreComing;
- (void) handleRemoveItem: (ETLayoutItem *)item moreComing: (BOOL)moreComing;

- (void) handleAddItems: (NSArray *)items;
- (void) handleRemoveItems: (NSArray *)items;

/** @taskunit Model Mutation */

- (void) mutateRepresentedObjectForAddedItem: (ETLayoutItem *)item;
- (void) mutateRepresentedObjectForInsertedItem: (ETLayoutItem *)item atIndex: (int)index;
- (void) mutateRepresentedObjectForRemovedItem: (ETLayoutItem *)item;

/** @taskunit Autoboxing */

- (ETLayoutItem *) boxObject: (id)object;
	
/** @taskunit Providing */

- (BOOL) isReloading;
- (NSArray *) itemsFromSource;
- (void) sourceDidUpdate: (NSNotification *)notif;

/** @taskunit Controller Coordination */

- (id) itemWithObject: (id)object isValue: (BOOL)isValue;

@end
