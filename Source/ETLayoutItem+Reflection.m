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
