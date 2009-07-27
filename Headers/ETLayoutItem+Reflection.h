/** <title>ETLayoutItem+Reflection</title>

	<abstract>Reflection on the layout item tree.</abstract>

	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2008
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>


@interface ETLayoutItem (ETUIReflection)

- (unsigned int) UIMetalevel;
- (unsigned int) UIMetalayer;
- (BOOL) isMetaLayoutItem;

/** A basic meta model which inspects layout items by wrapping each one in a 
	new meta layout item. Achieved by setting the base layout item as the
	represented object of the new meta layout item. */
+ (ETLayoutItem *) layoutItemWithRepresentedItem: (ETLayoutItem *)item
                                        snapshot: (BOOL)snapshot;

@end
