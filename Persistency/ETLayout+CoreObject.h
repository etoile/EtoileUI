/**
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETFreeLayout.h>

@class COEditingContext, COObject;

@interface ETLayout (CoreObject) 
/**  This method is only exposed to be used internally by EtoileUI.

Makes the receiver persistent by inserting it into the given persistent root as 
described in -[COObject becomePersistentInContext:]. */
- (void) becomePersistentInContext: (COPersistentRoot *)aContext;
@end

@interface ETFreeLayout (CoreObject)
@end