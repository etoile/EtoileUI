/**
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETCollectionToPersistentCollection.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayoutItemFactory.h>

@class COEditingContext, COObject;

@interface ETLayoutItem (CoreObject)

/** @taskunit Item Persistency */

/** Returns the owning compound document, or nil if the receiver is not persisted. 

The owning compound document is an ancestor item. */
@property (nonatomic, readonly) ETLayoutItemGroup *compoundDocument;

/** @taskunit UI Persistency */

@property (nonatomic, copy) NSString *persistentUIName;
@property (nonatomic, readonly) ETLayoutItem *persistentUIItem;
@property (nonatomic, getter=isEditingUI) BOOL editingUI;

@end

@interface ETLayoutItemGroup (CoreObject) 
/** Returns whether the receiver is a compound document (aka root object). */
@property (nonatomic, readonly) BOOL isCompoundDocument;
/** Returns descendant items of the receiver which are compound documents.

When a compound document is collected, its subtree is not visited.<br />
The receiver is not included in the returned set. */
@property (nonatomic, readonly) NSSet *descendantCompoundDocuments;
@end


@interface ETValueTransformersToPersistentDictionary : ETCollectionToPersistentCollection
@end
