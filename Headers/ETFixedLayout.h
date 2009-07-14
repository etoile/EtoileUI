/** <title>ETFixedLayout</title>
	
	<abstract>A layout class that position items based on their persistent 
	geometry.</asbtract>
 
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: July 2009
	License:  Modified BSD (see COPYING)
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>


@interface ETFixedLayout : ETLayout
{

}

- (BOOL) isPositional;
- (BOOL) isComputedLayout;

- (void) loadPersistentFramesForItems: (NSArray *)items;

@end
