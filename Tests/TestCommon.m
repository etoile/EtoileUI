/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Model.h>
#import "TestCommon.h"

@implementation Person

@synthesize name = _name, emails = _emails, groupNames = _groupNames;

- (id) init
{
	SUPERINIT;
	ASSIGN(_name, @"John");
	ASSIGN(_emails, D(@"john@etoile.com", @"Work", @"john@nowhere.org", @"Home"));
	ASSIGN(_groupNames, A(@"Somebody", @"Nobody"));
	return self;
}

- (void) dealloc
{
	DESTROY(_name);
	DESTROY(_emails);
	DESTROY(_groupNames);
	[super dealloc];
}

- (NSArray *) propertyNames
{
	return [[super propertyNames]
			arrayByAddingObjectsFromArray: A(@"name", @"emails", @"groupNames")];
}

@end
