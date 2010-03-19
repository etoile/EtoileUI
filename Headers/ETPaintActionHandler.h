/*  <title>ETPaintActionHandler</title>

	<abstract>Paint actions produced by various tools/tools.</abstract>

	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2009
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETActionHandler.h>

@class ETLayoutItem;

/** For now paint actions are only produced by the paint bucket tool.

See ETPaintBucketTool. */
@interface ETActionHandler (ETPaintActionHandler)

/* Paint Actions */

- (BOOL) canFillItem: (ETLayoutItem *)item;
- (void) handleFillItem: (ETLayoutItem *)item withColor: (NSColor *)aColor;
- (BOOL) canStrokeItem: (ETLayoutItem *)item;
- (void) handleStrokeItem: (ETLayoutItem *)item withColor: (NSColor *)aColor;

@end
