/** <title>Controls+Etoile</title>

	<abstract>NSControl class and subclass additions.</abstract>

	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// TODO: Declare properties and work out all the default factory values to be 
// used for cloning view-based items with EtoileUI. Only NSTextField is 
// partially implemented for now.

@interface NSControl (Etoile)

- (BOOL) isWidget;

/* Copying */

- (id) copyWithZone: (NSZone *)zone;

/* Property Value Coding */

- (NSArray *) properties;

@end


@interface NSTextField (Etoile)
+ (NSRect) defaultFrame;
- (NSArray *) properties;
@end

@interface NSImageView (Etoile)
- (BOOL) isWidget;
@end

