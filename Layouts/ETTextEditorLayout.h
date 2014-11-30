/** <title>ETTextEditorLayout</title>
	
	<abstract>A layout class that allows to view and edit a layout item tree 
	through a text representation.</asbtract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETWidgetLayout.h>

// FIXME: Don't expose NSTextView in the public API.
@class NSTextView;

/** Widely unfinished layout that allows to view and potentially edit a layout 
item tree through a text representation. */
@interface ETTextEditorLayout : ETWidgetLayout
{
	@private
	BOOL _textRepIncludesContext;
}

- (BOOL) textRepresentationIncludesLayoutContext;
- (void) setTextRepresentationIncludesLayoutContext: (BOOL)flag;

/** The delegate, usually a ETController object.
 
The delegate is owned by the receiver. You can create retain cycles, because the 
object graph context retains all the inner objects and releases them as necessary
each time it runs a GC phase. */
@property (nonatomic, retain) COObject *delegate;

@end

@interface NSObject (ETTextEditorLayoutDelegate)
- (BOOL) layout: (ETTextEditorLayout *)aLayout prepareTextView: (NSTextView *)aTextView;
@end
