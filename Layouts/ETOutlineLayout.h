/** <title>ETOutlineLayout</title>

	<abstract>A layout class whichs adapts and wraps an outline or tree view  
	widget provided by the widget backend.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
// FIXME: Don't expose NSOutlineView in the public API.
#import <AppKit/NSOutlineView.h>
#import <EtoileUI/ETTableLayout.h>

/** See [ETTableLayout] API to customize ETOutlineLayout look and behavior. */
@interface ETOutlineLayout : ETTableLayout 
{

}

@end

/** The class the outline views must match to be used with ETOutlineLayout.

See [ETTableView] documentation whose explanations also applies to ETOutlineView. */
@interface ETOutlineView : NSOutlineView
@end
