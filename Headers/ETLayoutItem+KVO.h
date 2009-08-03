/** <title>ETLayoutItem+KVO</title>
	
	<abstract>Layout item Key Value Observing support.</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>


/** WARNING: Unstable API. */
@interface ETLayoutItem (KVO)
- (NSSet *) observableKeyPaths;
@end
