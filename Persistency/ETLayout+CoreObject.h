/**
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETLayout.h>

@class COEditingContext, COObject;

@interface ETLayout (CoreObject) 
/**  This method is only exposed to be used internally by EtoileUI.

Makes the receiver persistent by inserting it into the given editing context as 
described in -[COObject becomePersistentInContext:rootObject:]. */
- (void) becomePersistentInContext: (COEditingContext *)aContext rootObject: (COObject *)aRootObject;
@end
