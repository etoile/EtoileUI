/*  <title>NSImage+Etoile</title>
	
	<abstract>NSImage additions.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface NSImage (Etoile)
- (NSImage *) initWithView: (NSView *)view fromRect: (NSRect)rect;
- (NSImage *) icon;
@end
