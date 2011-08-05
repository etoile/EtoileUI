/** <title>ETPickboard</title>
	
	<abstract>Pick & Drop class</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  October 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItemGroup.h>

@class ETUTI;

extern NSString *ETLayoutItemPboardType;
// NOTE: NSString will be replaced by a CoreObject uuid
#define ETPickboardRef NSString


/** You must never subclass ETPickboard. */
@interface ETPickboard : ETLayoutItemGroup
{
	@private
	NSMutableDictionary *_pickedObjects;
	unsigned int _pickboardRef;
}

/** @taskunit Choosing a Pickboard */

+ (ETPickboard *) systemPickboard;
+ (ETPickboard *) projectPickboard;
+ (ETPickboard *) localPickboard;

+ (ETPickboard *) activePickboard;
+ (void) setActivePickboard: (ETPickboard *)pickboard;

/** @taskunit Pickboard Interaction */

- (id) popObject;
- (id) popObjectAsPickCollection: (BOOL)boxed;
- (ETPickboardRef *) pushObject: (id)object metadata: (NSDictionary *)metadata;
- (ETPickboardRef *) appendObject: (id)object metadata: (NSDictionary *)metadata;
- (void) removeObjectForPickboardRef: (ETPickboardRef *)ref;
- (id) objectForPickboardRef: (ETPickboardRef *)ref;
- (NSArray *) allObjects;

- (id) firstObject;
- (id) firstObjectAsPickCollection: (BOOL)boxed;
- (NSDictionary *) firstObjectMetadata;

/* @taskunit Pick and Drop Palette */

- (NSWindow *) pickPalette;
- (void) showPickPalette;

@end

/** A transient collection that represents several objects manipulated together 
in a pick and drop operation. 

For example when you pick several layout items, a pick collection is 
automatically created to represent these items until the pick operation ends.<br /> 
A pick operation ends when the objects on the pickboard are removed. For example, 
on drop.

On drop, the collection must be unboxed, every element is inserted in the drop 
target as an individual object. EtoileUI does the unboxing in 
-[ETActionHandler handleDropCollection:metadata:atIndex:onItem:coordinator:]. 
You won't need to use to ETPickCollection class, EtoileUI does it, unless you 
want to customize pick & drop behavior. e.g. by overriding ETActionHandler 
methods involved with them, or possibly by pushing or popping objects on a 
a pickboard. */
@interface ETPickCollection : NSObject <ETCollection>
{
	NSArray *_pickedObjects;
	ETUTI *_type;
}

+ (id) pickCollectionWithCollection: (id <ETCollection>)objects;
- (id) initWithCollection: (id <ETCollection>)objects;
- (ETUTI *) type;

@end
