/** <title>ETLayoutItemGroup+Mutation</title>

	<abstract>Description forthcoming.</abstract>
 
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
   
#define PROVIDER_SOURCE [[self baseItem] source]

/* Properties */

extern NSString *kETControllerProperty; // controller

/* All model mutations are triggered by implicit or explicit remove/insert/add 
   in the layout item tree. Implicit mutations are done by the framework unlike 
   explicit ones which are located in your code. These implicit mutations are 
   triggered by a first explicit mutation, the only one that needs to be 
   propagated to the model side. 
   The only case of implicit mutation is presently add/insert that may trigger 
   a remove. If a layout item is moved to a new parent item on insert or add, 
   and this new parent that differs from the existing parent, the new parent 
   will require that the item to be inserted removes itself from its existing 
   parent, before truly inserting it. See -[ETLayoutItemGroup handleAttachItem:], 
   -[ETLayoutItemGroup handleDetachItem:] and -isCoalescingModelMutation.
   Take note, you can induce implicit mutations in your code if you write a
   subclass for ETLayoutItem (or other related subclasses) and you call methods 
   like -addItem, removeItem:, -insertItem:atIndex: etc. */
@interface ETLayoutItemGroup (ETMutationHandler)

- (BOOL) hasNewContent;
- (void) setHasNewContent: (BOOL)flag;
- (BOOL) isCoalescingModelMutation;
- (void) beginCoalescingModelMutation;
- (void) endCoalescingModelMutation;
- (BOOL) beginMutate;
- (void) endMutate: (BOOL)wasAutolayoutEnabled;

/* Mutation Backend
   Handling of Mutations on Layout Item Tree, Model Graph and Source  */

- (BOOL) handleAdd: (ETEvent *)event item: (ETLayoutItem *)item;
- (BOOL) handleModelAdd: (ETEvent *)event item: (ETLayoutItem *)item;
- (BOOL) handleInsert: (ETEvent *)event item: (ETLayoutItem *)item atIndex: (int)index;
- (BOOL) handleModelInsert: (ETEvent *)event item: (ETLayoutItem *)item atIndex: (int)index;
- (BOOL) handleRemove: (ETEvent *)event item: (ETLayoutItem *)item;
- (BOOL) handleModelRemove: (ETEvent *)event item: (ETLayoutItem *)item;

- (void) handleAdd: (ETEvent *)event items: (NSArray *)items;
- (void) handleRemove: (ETEvent *)event items: (NSArray *)items;

/* Collection Protocol Backend */

- (void) handleAdd: (ETEvent *)event object: (id)object;
- (void) handleInsert: (ETEvent *)event object: (id)object;
- (void) handleRemove: (ETEvent *)event object: (id)object;
	
/* Providing */

- (BOOL) isReloading;
- (NSArray *) itemsFromSource;
- (NSArray *) itemsFromFlatSource;
- (NSArray *) itemsFromTreeSource;
- (NSArray *) itemsFromRepresentedObject;
- (int) checkSourceProtocolConformance;
- (void) sourceDidUpdate: (NSNotification *)notif;

/* Controller Coordination */

- (id) newItem;
- (id) newItemGroup;
- (id) itemWithObject: (id)object isValue: (BOOL)isValue;

@end
