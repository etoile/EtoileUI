/** <title>ETNullLayout</title>

	<abstract>A layout class that does nothing.</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2009
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>


/** -[ETLayoutItem/Group setLayout:] doesn't accept a nil layout. You can 
use this class in this role when you want to have no particular layout:
<code>[itemGroup setLayout: [ETNullLayout layout]]</code>. */
@interface ETNullLayout : ETLayout
{

}

@end
