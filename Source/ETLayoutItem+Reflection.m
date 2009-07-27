/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2008
	License: Modified BSD (see COPYING)
 */

#import <EtoileUI/ETLayoutItem+Reflection.h>
#import "NSView+Etoile.h"
#import "ETCompatibility.h"


@implementation ETLayoutItem (ETUIReflection)

/** Returns the metalevel in the UI domain.
	Three metamodel variants exist in Etoile:
	- Object
	- Model
	- UI
	Each metamodel domain is bound to an arbitrary number of metalevels (0, 1, 
	3, etc.). Metalevels are expressed as positive integers and are usually 
	not limited to a max value.
	A new metalevel is entered, each time -setRepresentedObject: is called with 
	an object of the same type than the receiver. The type interpretation of 
	both the receiver and the paremeter varies with the metamodel domain. For UI
	domain, both must include ETLayoutItem type or subtype in their type.
	For example:
	
	id item1 = [ETLayoutItem layoutItem];
	
	item2 = [ETLayoutItem layoutItemWithRepresentedObject: item1];
	item3 = [ETLayoutItem layoutItemWithRepresentedObject: [NSImage image]];
	item4 = [ETLayoutItem layoutItemWithRepresentedObject: item2];
	
	If we call -metalevel method on each item, the output is the following:
	- item1 will return 0
	- item2 will return 1
	- item3 will return 0
	- item4 will return 2 */
- (unsigned int) UIMetalevel
{
	if ([self isMetaLayoutItem])
	{
		unsigned int metalevel = 0;
		id repObject = [self representedObject];
		
		/* An item can be a meta layout item by using a view as represented object */
		if ([repObject respondsToSelector: @selector(UIMetalevel)] )
			metalevel = [repObject UIMetalevel];
		
		return ++metalevel;
	}
	else
	{
		return 0;
	}
}

/** Returns the UI metalayer the receiver belongs to.
	The metalayer is the metalevel which owns the receiver. For UI metamodel 
	domain, the ownership to a metalayer results of existing parent/child 
	relationships in the layout item tree.
	An item has equal UIMetalevel and UIMetalayer when no parent with superior
	UIMetalevel value can be found by climbing up the layout item tree until the
	root item is reached. The root item UI metalevel is 0, thus all descendant
	items can create metalayers by having a superior UI metalevel. 
	A child item can introduce a new metalayer by having a UI metalevel 
	superior to the last parent item defining a UI metalayer. 
	Finally in a metalayer, objects can have arbitrary metalevel. 
	For example:
	
		Item Tree		Metalevel
	
	- root item	0			(0)
	- item 1				(2)
		- child item 11		(1)
			- item 111		(4)
				- item 1111	(4)
				- item 1112	(0)
		- child item 12		(2)
	- item 2				(0)
		- item 21			(0)
		
	Available metalayers:
	- (0) item 0, 2, 21
	- (2) item 1, 11, 12
	- (4) item 1111, 1111, 1112
	
	No metalayer (1) exists with this layout item tree, because the only item
	bound to this metalevel is preempted by the metalayer (2) introduced with 
	'item 1'. */
- (unsigned int) UIMetalayer
{
	int metalayer = [self UIMetalevel];
	id parent = self;
	
	while ((parent = [parent parentItem]) != nil)
	{
		if ([parent UIMetalevel] > metalayer)
			metalayer = [parent UIMetalevel];
	}
	
	return metalayer;
}

// TODO: Rename -isMetalevelItem
- (BOOL) isMetaLayoutItem
{
	// NOTE: Defining the item as a meta item when a view is the represented 
	// object allows to read and write view values when the item is modified
	// with PVC. If the item is declared as a normal item, PVC will apply to
	// the item itself for all properties common to NSView and ETLayoutItem 
	// (mostly frame related properties).
	// See also -valueForProperty and -setValue:forProperty:
	return ([[self representedObject] isKindOfClass: [ETLayoutItem class]]
		|| [[self representedObject] isKindOfClass: [NSView class]]);
}

/** Builds and returns a meta layout item representing item.
	If snapshot is YES and item has a view, a snapshot of this view is going to 
	be taken and sets a the image/icon of the meta item. Take note that 
	creating a view snapshot is an expansive operation. */
+ (ETLayoutItem *) layoutItemWithRepresentedItem: (ETLayoutItem *)item 
                                        snapshot: (BOOL)snapshot
{
	/* The meta item only need to be a shallow copy of item since the meta 
	   children will be created by using the children of item as represented 
	   objects. When -items will be called on the meta item, the collection 
	   protocol will be used to transparently retrieve the represented children 
	   items and generates all the necessary meta children items. */
	ETLayoutItem *metaLayoutItem = AUTORELEASE([[ETLayoutItem alloc] initWithRepresentedObject: item]); 
	id propertyName = nil;

	[metaLayoutItem setRepresentedObject: item];

	// NOTE: In most cases, -[ETLayoutItem copy] is used to create meta layout
	// items which only need a static snapshot of the view and not an 
	// interactive view.
	if (snapshot && [item displayView] != nil 
		&& NSEqualRects([[item displayView] frame], NSZeroRect) == NO)
	{
		id img = [[item displayView] snapshot];
		id imgView = [[NSImageView alloc] initWithFrame: [[item displayView] frame]];
		[imgView setImage: img];
		[metaLayoutItem setView: imgView];
		RELEASE(imgView);
	}

	/* If the item represents a property, the related meta layout item must 
	   represent the property name as a value of property 'kProperty' and the 
	   value of the property as a value of property 'kValue'.
	   
	   Example:
	             
					    Objects and Meta Objects                           Metalevel
				 
	   - Inspected item (layout item or model object)                    <- level 0
	       kPrice = 5 
		   kPrice is a property and 5 a value
	   - Meta Inspected item (property view root node)                   <- level 1
	       kPrice = 5 
		   kPrice is a property and 5 a value
	   - Property item (represents a single property of inspected item)  <- level 1
	       kProperty = kPrice
		   kValue = 5
		   kName = kPrice
	   So every properties of inspected item are represented by a property item
	   which is created indirectly when a meta layout item is instantiated to 
	   both play the role of the property view root node and represents the 
	   inspected item. 
	   Now if the view displaying the property item list is inspected, we must 
	   create a new meta layout item for each property item to be inspected.
	   - Meta Item of Property Item                                      <- level 2
		   kProperty = kPrice
		   kValue = 5
		   kName = kPrice
	   - Property Items for Meta Property item                           <- level 2
	     (represents a single property of inspected property item)
		 Because Meta Property Item has 3 properties, 3 property items will be
		 created to represent Meta Property Item in a property view:
	     - property item 1
	       kProperty = kProperty
		   kValue = kPrice
		   kName = KProperty
		 - property item 2
		   kProperty = kValue
		   kValue = 5
		   kName = kValue
		 - property item 3
		   kProperty = kName
		   kValue = kPrice
		   kName = kName
	   etc.
	   
	   From here, you can create new Meta Item or Property Items based on 
	   the layout items mentionned above. There are no limitations to the
	   introspection depth, but there is rarely an interest to go beyond
	   meta levels 1 or 2.
	*/
	// NOTE: this code may be better located in -[ETLayoutItem valueForProperty:]
	if ([[item properties] containsObject: @"property"])
	{
		propertyName = [metaLayoutItem valueForProperty: @"property"];
		if (propertyName != nil)
		{
			[metaLayoutItem setValue: propertyName forProperty: @"name"];
			[metaLayoutItem setValue: [metaLayoutItem valueForProperty: @"property"]
						 forProperty: @"property"];
		}
	}
	
	return metaLayoutItem;
}

@end
