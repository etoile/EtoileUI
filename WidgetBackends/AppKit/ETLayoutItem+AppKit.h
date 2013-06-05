/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>

/** @group AppKit Widget Backend
 
@abstract Category to integrate ETLayoutItem and AppKit widgets */
@interface ETLayoutItem (ETAppKitWidgetBackend)
- (BOOL) isEditing;
- (void) setEditing: (BOOL)editing;
@end
