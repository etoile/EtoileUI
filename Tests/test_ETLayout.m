/*
	test_ETPickboard.m

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2008

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETTableLayout.h>
#import <EtoileUI/ETCompatibility.h>
#import <UnitKit/UnitKit.h>

@interface ETLayout (Private)
+ (NSString *) stripClassName;
+ (NSString *) stringBySpacingCapitalizedWordsOfString: (NSString *)name;
+ (NSString *) displayName;
+ (NSString *) aspectName;
@end

@interface ETLayout (UnitKitTests) <UKTest>
@end

/* Dummy class for testing */
@interface WXYBirdTableBirdBird : ETLayout
@end

@implementation WXYBirdTableBirdBird
+ (NSString *) typePrefix {	return @"WXY"; }
+ (NSString *) baseClassName { return @"Bird"; }
@end


@implementation ETLayout (UnitKitTests)

+ (void) testDisplayName
{
	UKStringsEqual(@"", [self displayName]);
	UKStringsEqual(@"Table", [ETTableLayout displayName]);
	UKStringsEqual(@"Bird Table Bird", [WXYBirdTableBirdBird displayName]);
}

+ (void) testStripClassName
{
	UKStringsEqual(@"", [self stripClassName]);
	UKStringsEqual(@"Table", [ETTableLayout stripClassName]);
	UKStringsEqual(@"BirdTableBird", [WXYBirdTableBirdBird stripClassName]);
}

+ (void) testStringBySpacingCapitalizedWordsOfString
{
	id string1 = @"layout";
	id string2 = @"myFunnyLayout";
	UKStringsEqual(string1, [self stringBySpacingCapitalizedWordsOfString: string1]);
	UKStringsEqual(@"my Funny Layout", [self stringBySpacingCapitalizedWordsOfString: string2]);

	string1 = @"Layout";
	string2 = @"MyFunnyLayout";
	id string3 = @"MyFunnyLayoutZ";
	UKStringsEqual(string1, [self stringBySpacingCapitalizedWordsOfString: string1]);
	UKStringsEqual(@"My Funny Layout", [self stringBySpacingCapitalizedWordsOfString: string2]);
	UKStringsEqual(@"My Funny Layout Z", [self stringBySpacingCapitalizedWordsOfString: string3]);

	string1 = @"XMLNode";
	string2 = @"unknownXMLNodeURL";
	UKStringsEqual(@"XML Node", [self stringBySpacingCapitalizedWordsOfString: string1]);
	UKStringsEqual(@"unknown XML Node URL", [self stringBySpacingCapitalizedWordsOfString: string2]);
}

+ (void) testAspectName
{
	UKStringsEqual(@"", [self aspectName]);
	UKStringsEqual(@"table", [ETTableLayout aspectName]);
	UKStringsEqual(@"birdTableBird", [WXYBirdTableBirdBird aspectName]);
}

@end
