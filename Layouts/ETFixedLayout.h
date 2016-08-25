/** <title>ETFixedLayout</title>
	
	<abstract>A layout class that position items based on their persistent 
	geometry.</abstract>
 
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: July 2009
	License:  Modified BSD (see COPYING)
*/

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETPositionalLayout.h>


@interface ETFixedLayout : ETPositionalLayout
{
	@private
	BOOL _autoresizesItems;
}

/** @taskunit Type Querying */

@property (nonatomic, getter=isPositional, readonly) BOOL positional;
@property (nonatomic, getter=isComputedLayout, readonly) BOOL computedLayout;

/** @taskunit Autoresizing */

@property (nonatomic) BOOL autoresizesItems;

/** @taskunit Persistent Item Frames */

- (void) loadPersistentFramesForItems: (NSArray *)items;

@end
