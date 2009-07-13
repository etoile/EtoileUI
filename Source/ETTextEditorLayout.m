/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD  (see COPYING)
 */

#import "ETTextEditorLayout.h"
#import "ETLayoutItem.h"
#import "ETCompatibility.h"

#define EDITOR_FRAME NSMakeRect(200, 200, 600, 300)


@implementation ETTextEditorLayout

- (ETLayout *) initWithLayoutView: (NSView *)view
{
	self = [super initWithLayoutView: nil];
	if (self == nil)
		return nil;

	NSTextView *editorView = [[NSTextView alloc] initWithFrame: EDITOR_FRAME];
		
	[editorView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[self setLayoutView: editorView];
	RELEASE(editorView);
	
	return self;
}

- (NSTextView *) textView
{
	return (NSTextView *)[self layoutView];
}

- (id) textRepresentationFromItems: (NSArray *)items
{
	if ([self textRepresentationIncludesLayoutContext])
	{
		return [_layoutContext stringValue];
	}
	else
	{
		return [[items valueForKeyPath: @"subject.stringValue"] 
			componentsJoinedByString: @"\n"];
	}
}

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	// FIXME: Even when the context content/collection isn't mutated, the 
	// text content might have changed in one or several nodes. Which means 
	// the text view has to be updated. The same issue probably arises in 
	// ETTableLayout if we start to observe changes in the model to trigger 
	// -reloadData transparently. Think about that...
	if (NO == isNewContent)
		return;

	[[self textView] setString: [self textRepresentationFromItems: items]];
}

/** Returns whether the layout context or its content receives -stringValue. */
- (BOOL) textRepresentationIncludesLayoutContext
{
	return _textRepIncludesContext;
}

/** Sets whether the layout context or its content receives -stringValue. */
- (void) setTextRepresentationIncludesLayoutContext: (BOOL)flag
{
	_textRepIncludesContext = flag;
}

@end
