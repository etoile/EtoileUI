/**
	Copyright (C) 2006 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2006
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETFragment.h>

/** @abstract An horizontal or vertical line box in a layout

A line fragment is a collection of fragments to be laid out either horizontally
or vertically.

A line fragment is commonly used in together with ETComputedLayout to cluster
items spatially without requiring these items to belong to an item group.

ETLineFragment is not designed to be subclassed. */
@interface ETLineFragment : NSObject <ETFragment>
{
	@protected
	id <ETLayoutFragmentOwner> __weak _owner;
	NSMutableArray *_fragments;
	NSPoint _origin;
	CGFloat _fragmentMargin;
	CGFloat _maxWidth;
	CGFloat _maxHeight;
	BOOL _flipped;
	BOOL _skipsFlexibleFragments;
}

+ (id) horizontalLineWithOwner: (id <ETLayoutFragmentOwner>)anOwner
                    itemMargin: (CGFloat)aMargin 
                      maxWidth: (CGFloat)aWidth;
+ (id) verticalLineWithOwner: (id <ETLayoutFragmentOwner>)anOwner
                  itemMargin: (CGFloat)aMargin 
                   maxHeight: (CGFloat)aHeight
                   isFlipped: (BOOL)isFlipped;

/** Whether fragments which returns YES to -[ETLayoutFragmentOwner isFlexibleItem:] 
should be treated as having a zero length. */
@property (nonatomic, assign) BOOL skipsFlexibleFragments;

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
