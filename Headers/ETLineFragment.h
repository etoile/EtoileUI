/** <title>ETLineFragment</title>

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
group. */
@interface ETLineFragment : NSObject <ETFragment>
{
	id <ETLayoutFragmentOwner>_owner;
	NSMutableArray *_fragments;
	NSPoint _origin;
	float _fragmentMargin;
	float _maxWidth;
	float _maxHeight;
	BOOL _flipped;
}

+ (id) horizontalLineWithOwner: (id <ETLayoutFragmentOwner>)anOwner
                fragmentMargin: (float)aMargin 
                      maxWidth: (float)aWidth;
+ (id) verticalLineWithOwner: (id <ETLayoutFragmentOwner>)anOwner
                  itemMargin: (float)aMargin 
                   maxHeight: (float)aHeight
                   isFlipped: (BOOL)isFlipped;

- (NSArray *) fillWithItems: (NSArray *)aFragment;
- (NSArray *) items;
- (float) itemMargin;

- (NSPoint) origin;
- (void) setOrigin: (NSPoint)location;
- (float) height;
- (float) width;

- (float) maxWidth;
- (float) maxHeight;
- (float) maxLength;

- (float) length;
- (float) thickness;
- (BOOL) isVerticallyOriented;

@end
