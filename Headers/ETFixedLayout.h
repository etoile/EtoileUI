/** <title>ETFixedLayout</title>
	
	<abstract>A layout class that position items based on their persistent 
	geometry.</abstract>
 
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: July 2009
	License:  Modified BSD (see COPYING)
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETPositionalLayout.h>


@interface ETFixedLayout : ETPositionalLayout
{
	@private
	BOOL _autoresizesItem;
}

/** @taskunit Type Querying */

- (BOOL) isPositional;
- (BOOL) isComputedLayout;

/** @taskunit Autoresizing */

- (BOOL) autoresizesItems;
- (void) setAutoresizesItems: (BOOL)autoresize;

/** @taskunit Persistent Item Frames */

- (void) loadPersistentFramesForItems: (NSArray *)items;

@end
