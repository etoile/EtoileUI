/** <title>ETController</title>
	
	<abstract>A generic controller layer interfaced with the layout item tree.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem, ETLayoutItemGroup, ETUTI;

// TODO: Think about the selection marker stuff and implement it if it makes senses.

/** ETController provides a generic controller layer, usually to be used a 
	replacement for both NSArrayController and NSTreeController. This reusable 
	controller fills the same purpose than the previously mentionned 
	NSController subclasses. The difference lies in the fact the tree structure 
	is already abstracted in the layout item tree, as such there is no need for 
	a special tree controller class with EtoileUI. The mediation with a 
	collection of model objects is also abstracted in ETLayoutItemGroup class, 
	whose instances play the role of lightweight mediators between View and 
	Model in MVC term, hence NSArrayController isn't really needed either.
	ETController extends the traditional facilities of NSController subclasses 
	by allowing to make a distinction between Object class and Group class 
	(leaf vs branches) as very often needed by applications in the Object 
	Manager style (see also CoreObject) at both UI and model levels. 
	For the UI, you can specify items templates to be cloned when a new element 
	has to be inserted/added. On the model side, you can specify the class of 
	the model objects to be instantiated.

	be exactly accurate or entirely implemented.
	This whole facility can be used at any levels of the UI. For example, for  
	supporting multiple windows in a file manager, you can create an 
	ETLayoutItemGroup instance, that encapsulates a layout item tree which is 
	the file manager UI. Then by simply setting this item group as an item group 
	template on the window layer, and wiring File->New Window... to -add: 
	action of this controller, new file manager windows will be created when 
	New Window... is clicked in the menu. If you want your file managers to 
	automatically open on a default directory, a model class can be set on the 
	on the controller (-setGroupClass:) or alternatively a model instance can be 
	set on the template item group (by calling -[ETLayoutItem setRepresentedObject:]).
	This ability to clone entire UI is detailed in -deepCopy of ETLayoutItem 
	class and subclasses.
	When a controller is set, it's very important to ensure its layout item is 
	a base item, otherwise the wrong template items may be look up in the 
	ancestor layout item instead of using the one declared in the controller 
	bound to the container. 
	ETController directly sorts object of the content and doesn't maintain 
	arranged objects as a collection distinct from the content. */
@interface ETController : NSObject <NSCopying>
{
	ETLayoutItemGroup *_content;
	ETLayoutItem *_templateItem;
	ETLayoutItemGroup *_templateItemGroup;
	Class _objectClass;
	Class _groupClass;
	NSArray *_sortDescriptors;
	NSPredicate *_filterPredicate;
	ETUTI *_allowedPickType;
	NSMutableDictionary *_allowedDropTypes; /* Allowed drop UTIs by drop target UTIs */
	BOOL _automaticallyRearrangesObjects;
	BOOL _hasNewSortDescriptors;
	BOOL _hasNewFilterPredicate;
	BOOL _hasNewContent;
}

- (ETLayoutItemGroup *) content;
- (void) setContent: (ETLayoutItemGroup *)content;

- (ETLayoutItem *) templateItem;
- (void) setTemplateItem: (ETLayoutItem *)template;
- (ETLayoutItemGroup *) templateItemGroup;
- (void) setTemplateItemGroup: (ETLayoutItemGroup *)template;
- (Class) objectClass;
- (void) setObjectClass: (Class)modelClass;
- (Class) groupClass;
- (void) setGroupClass: (Class)modelClass;

/* Actions */

- (id) newObject;
- (id) newGroup;
- (void) add: (id)sender;
- (void) addNewGroup: (id)sender;
- (void) insert: (id)sender;
- (void) insertNewGroup: (id)sender;
- (void) remove: (id)sender;

/* Selection */

- (BOOL) setSelectionIndexes: (NSIndexSet *)selection;
- (NSMutableIndexSet *) selectionIndexes;
- (BOOL) setSelectionIndex: (unsigned int)index;
- (unsigned int) selectionIndex;
- (unsigned int) insertionIndex;

/* Sorting and Filtering */

- (NSArray *) sortDescriptors;
- (void) setSortDescriptors: (NSArray *)sortDescriptors;
- (NSPredicate *) filterPredicate;
- (void) setFilterPredicate: (NSPredicate *)searchPredicate;
- (void) rearrangeObjects;
- (BOOL) automaticallyRearrangesObjects;
- (void) setAutomaticallyRearrangesObjects: (BOOL)flag;

//- (void) commitEditing;

/* Pick and Drop */

- (ETUTI *) allowedPickType;
- (void) setAllowedPickType: (ETUTI *)aUTI;
- (ETUTI *) allowedDropTypeForTargetType: (ETUTI *)aUTI;
- (void) setAllowedDropType: (ETUTI *)aUTI forTargetType: (ETUTI *)targetUTI;

@end

