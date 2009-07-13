/** <title>ETTextEditorLayout</title>
	
	<abstract>A layout class that allows to view and edit a layout item tree 
	through a text representation.</asbtract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>

/** Widely unfinished layout that allows to view and potentially edit a layout 
item tree through a text representation. */
@interface ETTextEditorLayout : ETLayout 
{
	BOOL _textRepIncludesContext;
}

- (BOOL) textRepresentationIncludesLayoutContext;
- (void) setTextRepresentationIncludesLayoutContext: (BOOL)flag;

@end
