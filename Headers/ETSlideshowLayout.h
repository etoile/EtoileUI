/** <title>ETSlideshowLayout</title>
	
	<abstract>A layout which displays one item at a time, stretched to fit the
	size of the layout. Useful in slideshow and presentation applications.
	</abstract>
 
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  August 2009
	License:  Modified BSD (see COPYING)
 */

#import <EtoileUI/ETComputedLayout.h>

@interface ETSlideshowLayout : ETComputedLayout
{
	unsigned int _currentItem;
}

- (void) computeLayoutItemLocationsForLayoutLine: (ETLayoutLine *)line;

/* API for choosing which item should be shown */

- (unsigned int) currentItem;
- (void) setCurrentItem: (unsigned int)item;
- (void) nextItem;
- (void) previousItem;

@end
