/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETLayoutItem+AppKit.h"
#import "EtoileUIProperties.h"

@implementation ETLayoutItem (ETAppKitWidgetBackend)

- (BOOL) isEditing
{
	return _isEditing;
}

- (void) setEditing: (BOOL)editing
{
	_isEditing = editing;
}

// TODO: isProcessingContinuousActionEvent

// TODO: Remove once -valueKey returns the viewpoint name.
- (NSString *) editedProperty
{
	NSString *valueKey = [self valueKey];

	if (valueKey != nil)
		return valueKey;

	if ([[self representedObject] conformsToProtocol: @protocol(ETPropertyViewpoint)])
	{
		valueKey = [(id <ETPropertyViewpoint>)[self representedObject] name];
	}
	return (valueKey != nil ? valueKey : kETValueProperty);
}

- (void) controlTextDidBeginEditing: (NSNotification *)notif
{
	_isEditing = YES;
	[self subjectDidBeginEditingForProperty: [self editedProperty]
	                        fieldEditorItem: nil];
}

/* Nothing to do. KVO is used to get notified of text changes. */
- (void) controlTextDidChange: (NSNotification *)notif
{
	
}

- (void) controlTextDidEndEditing: (NSNotification *)notif
{
	/* Cocoa posts a spurious NSControlTextDidEndEditingNotification on mouse 
	   down (no good reasons seem to exist).
	   Moreover a NSControlTextDidEndEditingNotification is also posted if the 
	   user exits the field without editing (in such a case no  
	   NSControlTextDidEndEditingNotification is posted). By checking 
	   the editing status, we simply ignore it to prevent useless notifications 
	   at the controller level.
	   Take note that at this point, -currentEditor is set. */
	if (_isEditing == NO)
		return;

	_isEditing = NO;
	[self subjectDidEndEditingForProperty: [self editedProperty]];
}

@end
