/*
	Copyright (C) 2016 Quentin Mathe
 
	Date:  August 2016
	License:  MIT  (see COPYING)
 */

#import "ETUIMetamodel.h"
#include <objc/runtime.h>

void ETPrepareUIMetamodel(ETModelDescriptionRepository *repo)
{
	BOOL wereRegisteredPreviously = ([repo descriptionForName: @"ETEdgeInsets"] != nil);

	if (wereRegisteredPreviously)
		return;

	ETEntityDescription *edgeInsetsEntity =
		[[ETCPrimitiveEntityDescription alloc] initWithName: @"ETEdgeInsets"];

	[repo addUnresolvedDescription: edgeInsetsEntity];

	NSMutableArray *warnings = [NSMutableArray array];

	[repo checkConstraints: warnings];
		
	if ([warnings isEmpty] == NO)
	{
		[NSException raise: NSInternalInconsistencyException
		            format: @"Failure on constraint check in repository %@:\n %@",
							repo, warnings];
	}
}
