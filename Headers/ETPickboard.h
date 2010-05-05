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


@interface ETPickboard : ETLayoutItemGroup
{
	NSMutableDictionary *_pickedObjects;
	unsigned int _pickboardRef;
}

/* Factory Methods */

/** Returns the system-wide pickboard which is used by default accross Etoile
    environment. */
+ (ETPickboard *) systemPickboard;
/** Returns a pickboard restricted to the active project. This pickboard isn't
    accessible in another project. */
+ (ETPickboard *) projectPickboard;
/** Returns the local pickboard which only exists in the process where it had 
	been initially requested. This pickboard isn't available externally to other
	processes. 
	Local pickboards are non-persistent, they expire when the lifetime of their
	owner process ends. */
+ (ETPickboard *) localPickboard;
+ (ETPickboard *) activePickboard;
+ (void) setActivePickboard: (ETPickboard *)pickboard;

/* Pickboard Interaction */

- (id) popObject;
- (ETPickboardRef *) pushObject: (id)object;
- (ETPickboardRef *) appendObject: (id)object;
- (void) removeObjectForPickboardRef: (ETPickboardRef *)ref;
- (id) objectForPickboardRef: (ETPickboardRef *)ref;
- (NSArray *) allObjects;
- (id) firstObject;

/* Pick & Drop Palette */

- (NSWindow *) pickPalette;
- (void) showPickPalette;

@end

/** Picked Object Set 

	Represents several objects manipulated together in a pick and drop
	operation. For example when you pick several layout items, a pick
	collection is automatically created to represent these items until the pick
	operation ends. A pick operation ends when the objects on the pickboard are 
	removed. For example, when the items are dropped somewhere.
	When a pick collection is dropped, the elements needs to be inserted as 
	distinct objects and not as a single object as you expect it when you drop 
	other collections (like array, dictionary etc.). If all collections were 
	inserted as distinct object when a drop occurs, it would imply no NSArray
	NSDictionary, NSSet etc. objects couldn't be manipulated by pick and drop,
	the collection objects would be lost when they left the pickboard. Writing
	specific code that decides how to insert the collection would be very 
	tedious and introduces inconsistent and unexpected behaviors. 
	ETPickCollection solves this exact problem by providing a transient 
	collection object to be used with pickboards. ETPickboard is also able to
	provide browsing of the picked objects and better visual feedback by being
	aware when a collection is a set of picked objects and not a usual 
	collection.
	You won't need to use to ETPickCollection class, EtoileUI does it, unless 
	you want to customize pick & drop behavior. If you manipulate pickboards 
	directly, you may want to group several objects together on a pickboard. In
	this case, before calling -pushObject: or -addObject:, you need to turn 
	them into a pick collection that you will pass to one of these two methods. 
*/

@interface ETPickCollection : NSObject <ETCollection>
{
	NSArray *_pickedObjects;
	ETUTI *_type;
}

+ (id) pickCollectionWithCollection: (id <ETCollection>)objects;

- (id) initWithCollection: (id <ETCollection>)objects;

- (ETUTI *) type;

/* ETCollection protocol */

- (BOOL) isEmpty;
- (id) content;
- (NSArray *) contentArray;
- (BOOL) isOrdered;

@end
