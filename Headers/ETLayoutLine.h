/** <title>ETLayoutLine</title>

	<abstract>Represents an horizontal or vertical line box in a layout.</abstract>

	Copyright (C) 2006 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2006
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface ETLayoutLine : NSObject
{
	NSMutableArray *_items;
	NSPoint _origin;
	NSPoint _topLineLocation;
	BOOL _vertical;
}

+ (id) layoutLineWithLayoutItems: (NSArray *)items;

- (NSArray *) items;

- (NSPoint) origin;
- (void) setOrigin: (NSPoint)location;

/** In flipped layout, top line location is rather than base line location. */ 
- (float) height;
- (float) width;

- (BOOL) isVerticallyOriented;
- (void) setVerticallyOriented: (BOOL)vertical;

@end
