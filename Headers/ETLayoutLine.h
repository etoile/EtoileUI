/** <title>ETLayoutLine</title>

	<abstract>Represents an horizontal or vertical line box in a layout.</abstract>

	Copyright (C) 2006 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2006
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETFragment.h>

/** A line fragment is a collection of fragments to be layouted either 
horizontally or vertically.

A line fragment is typically used together with ETComputedLayout to cluster 
items spatially without requiring that these layout items belong to an item 
group.  */
@interface ETLayoutLine : NSObject <ETFragment>
{
	NSMutableArray *_fragments;
	NSPoint _origin;
}

+ (id) horizontalLineWithFragments: (NSArray *)fragments;
+ (id) verticalLineWithFragments: (NSArray *)fragments;

- (NSArray *) fragments;

- (NSPoint) origin;
- (void) setOrigin: (NSPoint)location;
- (float) height;
- (float) width;

- (float) length;
- (float) thickness;
- (BOOL) isVerticallyOriented;

@end
