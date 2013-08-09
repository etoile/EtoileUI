/**
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayoutItemFactory.h>

@class COEditingContext, COObject;

@interface ETLayoutItem (CoreObject)

/** @taskunit Item Persistency */

/** Returns the owning compound document, or nil if the receiver is not persisted. 

The owning compound document is an ancestor item. */
- (ETLayoutItemGroup *) compoundDocument;

/** @taskunit UI Persistency */

- (NSString *) persistentUIName;
- (void) setPersistentUIName: (NSString *)aName;
- (ETLayoutItem *) persistentUIItem;
- (BOOL) isEditingUI;
- (void) setEditingUI: (BOOL)editing;

@end

@interface ETLayoutItemGroup (CoreObject) 
/** Returns whether the receiver is a compound document (aka root object). */
- (BOOL) isCompoundDocument;
/** Returns descendant items of the receiver which are compound documents.

When a compound document is collected, its subtree is not visited.<br />
The receiver is not included in the returned set. */
- (NSSet *) descendantCompoundDocuments;
@end

@interface ETLayoutItemFactory (CoreObject) 
/** Creates a compound document in the current editing context.

See +[ETLayoutItemGroup compoundDocumentWithEditingContext:] and 
+[COEditingContext currentContext]. */
- (ETLayoutItemGroup *) compoundDocument;
/** Creates a compound document in the given editing context.

A compound document is ETLayoutItemGroup instance bound to a ETCompoundDocument 
entity description, inserted inside a COEditingContext and marked as a root 
object.

When added to a compound document, any descendant item and its subtree become 
embedded core objects. */
- (ETLayoutItemGroup *) compoundDocumentWithEditingContext: (COEditingContext *)aCtxt;
@end
