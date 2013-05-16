/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETNumberPicker.h"

static const NSInteger textFieldTag = 1;
static const NSInteger stepperTag = 2;

@implementation ETNumberPicker

/** <init />
Initializes and returns a new number picker.
 
The provided height indicates the inner text field height that is expected to 
be smaller or equal to the frame height. */
- (id) initWithFrame: (NSRect)frameRect textFieldHeight: (CGFloat)aFieldHeight
{
	self = [super initWithFrame: frameRect];
	if (self == nil)
		return nil;

	NSStepper *stepper = [[NSStepper alloc] initWithFrame: frameRect];
	NSTextField *textField = [[NSTextField alloc] initWithFrame: frameRect];

	[textField setAutoresizingMask: NSViewWidthSizable];
	[stepper setAutoresizingMask: NSViewMinXMargin];
	[stepper sizeToFit];

	CGFloat margin = 0;

	[textField setWidth: [textField width] - margin - [stepper width]];
	[textField setHeight: aFieldHeight];
	[textField setY: (frameRect.size.height - aFieldHeight) / 2];
	[stepper setX: [textField width] + margin];

	NSNumberFormatter *formatter = AUTORELEASE([NSNumberFormatter new]);

	[formatter setNumberStyle: NSNumberFormatterDecimalStyle];
	//[formatter setMinimumIntegerDigits: 1];

	[textField setFormatter: formatter];
	[textField setDelegate: (id)self];
	[stepper setAction: @selector(takeDoubleValueFrom:)];
	[stepper setTarget: textField];

	[textField setTag: textFieldTag];
	[stepper setTag: stepperTag];

	[self addSubview: textField];
	[self addSubview: stepper];

	return self;
}

/** Returns YES to indicate that the receiver is a widget (or control in AppKit
terminology) on which actions should be dispatched. */
- (BOOL) isWidget
{
	return YES;
}

/** Returns the text field inserted as a subview inside the receiver. */
- (NSTextField *) textField
{
	return [self viewWithTag: textFieldTag];
}

/** Returns the stepper inserted as a subview inside the receiver. */
- (NSStepper *) stepper
{
	return [self viewWithTag: stepperTag];
}

- (NSNumberFormatter *) formatter
{
	NSNumberFormatter *formatter = [[self textField] formatter];
	ETAssert(formatter != nil);
	return formatter;
}

- (double) minValue
{
	return [[[self formatter] minimum] doubleValue];
}

- (void) setMinValue: (double)aValue
{
	[[self formatter] setMinimum: [NSNumber numberWithDouble: aValue]];
	[[self stepper] setMinValue: aValue];
}
	 
- (double) maxValue
{
	return [[[self formatter] maximum] doubleValue];
}

- (void) setMaxValue: (double)aValue
{
	[[self formatter] setMaximum: [NSNumber numberWithDouble: aValue]];
	[[self stepper] setMaxValue: aValue];
}

- (void) setDoubleValue: (double)aValue
{
	[[self textField] setDoubleValue: aValue];
	[[self stepper] setDoubleValue: aValue];
}

- (void) controlTextDidChange: (NSNotification *)aNotification
{
	NSText *fieldEditor = [[[self textField] window] fieldEditor: NO forObject: [self textField]];
	ETAssert(fieldEditor != nil);
	NSString *stringValue = [fieldEditor string];
	NSNumber *number = [[self formatter] numberFromString: stringValue];

	if (number == nil)
		return;

	[[self stepper] setDoubleValue: [number doubleValue]];
}

- (id) target
{
	return [[self textField] target];
}

- (void) setTarget: (id)aTarget
{
	[[self textField] setTarget: aTarget];
}

- (SEL) action
{
	return [[self textField] action];
}

- (void) setAction: (SEL)aSelector
{
	[[self textField] setAction: aSelector];
}

- (id) objectValue
{
	return [[self textField] objectValue];
}

- (void) setObjectValue: (id)aValue
{
	[[self textField] setObjectValue: aValue];
}

- (NSActionCell *) cell
{
	return [[self textField] cell];
}

@end
