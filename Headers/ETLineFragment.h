/** <title>ETLineFragment</title>

	<abstract>Represents an horizontal or vertical line box in a layout.</abstract>

	Copyright (C) 2006 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2006
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETFragment.h>

/** A line fragment is a collection of fragments to be layouted either 
horizontally or vertically.

A line fragment is typically used together with ETComputedLayout to cluster 
items spatially without requiring that these layout items belong to an item 
group.

Although we name 'items' the elements hold by a line fragment, they can be any 
objects that comply to the ETFragment protocol when their layout implements the 
ETLayoutFragmentOwner protocol in a compatible way.<br />
Take note that ETComputedLayout and its EtoileUI subclasses only accept 
ETLayoutItem objects as arguments to -rectForItem: and -setOrigin:forItem:.<br />
You can write subclasses and override these methods to solve this limitation.

It is not advised to subclass ETLineFragment. In any case, the ivars must be 
considered private. */
@interface ETLineFragment : NSObject <ETFragment>
{
	id <ETLayoutFragmentOwner> __weak _owner;
	NSMutableArray *_fragments;
	NSPoint _origin;
	CGFloat _fragmentMargin;
	CGFloat _maxWidth;
	CGFloat _maxHeight;
	BOOL _flipped;
}

+ (id) horizontalLineWithOwner: (id <ETLayoutFragmentOwner>)anOwner
                    itemMargin: (CGFloat)aMargin 
                      maxWidth: (CGFloat)aWidth;
+ (id) verticalLineWithOwner: (id <ETLayoutFragmentOwner>)anOwner
                  itemMargin: (CGFloat)aMargin 
                   maxHeight: (CGFloat)aHeight
                   isFlipped: (BOOL)isFlipped;

- (NSArray *) fillWithItems: (NSArray *)fragments;
@property (nonatomic, readonly) NSArray *items;
@property (nonatomic, readonly) CGFloat itemMargin;

@property (nonatomic) NSPoint origin;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) CGFloat width;

@property (nonatomic, readonly) CGFloat maxWidth;
@property (nonatomic, readonly) CGFloat maxHeight;
@property (nonatomic, readonly) CGFloat maxLength;

@property (nonatomic, readonly) CGFloat length;
@property (nonatomic, readonly) CGFloat thickness;
@property (nonatomic, getter=isVerticallyOriented, readonly) BOOL verticallyOriented;

@end
