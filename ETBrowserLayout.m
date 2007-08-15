/*
	ETBrowserLayout.m
	
	Description forthcoming.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2007
 
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

#import <EtoileUI/ETBrowserLayout.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETViewLayout.h>
#import <EtoileUI/ETViewLayoutLine.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>

#import <EtoileUI/FSBrowserCell.h>


#define DEFAULT_ROW_HEIGHT 20

/** ETBrowserLayout wraps AppKit NSBrowser control in term of Container archictecture.
	ETBrowserLayout uses by default a custom NSBrowser that displays icon and 
	text in column rows. If you prefer a different style of row, you can 
	replace ETBrowserCell by your own subclass of NSBrowserCell.
	Defaults settings of ETBrowserLayout are:
	- 130 px column width
	- four visible columns max
	- no column titles
	- double-click replaces the path displayed in browser by putting the 
	  content of double-clicked item in column zero.
      Example:
	  /Applications/Fusion.app/Resources
	  If you double-click 'Resources', the browser path is reset to '/' but
	  this root path is now referencing '/Applications/Fusion.app/Resources' 
	  and not '/'. In other words, the browser doesn't display the
	  whole path anymore but only a portion.    
	  Model encapsulated by ETLayoutItem instances is accessed through the 
	properties classified by decreasing priority order:
	- 'name', 'value' for text part of the row
	- 'icon', 'image' for icon part of the row
	
	NOTE: row resizing based on -[ETContainer itemScaleFactor] isn't yet 
	supported.
*/


@implementation ETBrowserLayout

- (id) init
{
	self = [super init];
    
	if (self != nil)
	{
		BOOL nibLoaded = [NSBundle loadNibNamed: @"BrowserPrototype" owner: self];
		
		if (nibLoaded == NO)
		{
			NSLog(@"Failed to load nib BrowserPrototype");
			RELEASE(self);
			return nil;
		}
    }
    
	return self;
}

- (void) dealloc
{
	DESTROY(_displayViewPrototype);
	
	[super dealloc];
}

- (void) awakeFromNib
{
	//NSLog(@"Awaking from nib for %@", self);
	RETAIN(_displayViewPrototype);
	[(NSBrowser *)_displayViewPrototype setCellClass: [FSBrowserCell class]];
	[(NSBrowser *)_displayViewPrototype setCellPrototype: AUTORELEASE([[FSBrowserCell alloc] init])];
	[_displayViewPrototype removeFromSuperview];
}

- (void) renderWithLayoutItems: (NSArray *)items
{
	NSBrowser *browserView = nil;
	
	/* No display view proto available, a browser view needs needs to be created 
	   in code */
	if ([self displayViewPrototype] == nil)
	{
		//scrollView = [self scrollingBrowserView];
	}
	else
	{
		NSView *proto = [self displayViewPrototype];
		
		/* NSBrowser isn't enclosed in an NScrollView unlike NSTableView and NSOutlineView */
		if ([proto isKindOfClass: [NSBrowser class]])
		{
			browserView = (NSBrowser *)[self displayViewPrototype];
		}
		else
		{
			NSLog(@"WARNING: %@ display view prototype %@ isn't an NSBrowser instance", self, proto);
		}
	}
	
	if ([browserView superview] == nil)
	{
		[[self container] setDisplayView: browserView];
	}
	else if ([[browserView superview] isEqual: [self container]] == NO)
	{
		NSLog(@"WARNING: %@ of %@ should never have another "
			  @"superview than container parameter or nil.", browserView, self);
	}
	
	//[self resizeLayoutItems: items toScaleFactor: [container itemScaleFactor]];
	
	if ([browserView delegate] == nil)
		[browserView setDelegate: self];
		
	//[browserView setPathSeparator: @"/"];
	//[browserView setPath: @"/"]; //[[self container] path]];
	[browserView loadColumnZero];
	//[self resizeLayoutItems: items toScaleFactor: [container itemScaleFactor]];
}

- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	NSBrowser *browserView = (NSBrowser *)_displayViewPrototype;
	// NOTE: Always recompute row height from the original one to avoid really
	// value shifting quickly because of rounding.
	//float rowHeight = DEFAULT_ROW_HEIGHT * factor;
	int numberOfCols = [browserView numberOfVisibleColumns];
	NSMatrix *columnMatrix = nil;

	for (int i = 0; i < numberOfCols; i++)
	{
		NSSize newCellSize = NSZeroSize;
		
		columnMatrix = [browserView matrixInColumn: i];
		if (columnMatrix != nil)
		{
			newCellSize = [columnMatrix cellSize];
			newCellSize.height = DEFAULT_ROW_HEIGHT * factor;
			[columnMatrix setCellSize: newCellSize];
			NSLog(@"Resize %@ cell size from %@ to %@", columnMatrix, 
				NSStringFromSize([columnMatrix cellSize]), 
				NSStringFromSize(newCellSize));
		}
	}
}

- (int) browser: (NSBrowser *)sender numberOfRowsInColumn: (int)column
{
	NSString *path = [sender pathToColumn: column];
	ETContainer *container = [self container];
	int count = 0;
	
	if (path == nil || [path isEqual: @""])
		path = @"/";
	
	path = [[[container path] stringByAppendingPathComponent: path] stringByStandardizingPath];
		
	count = [[container source] numberOfItemsAtPath: path inContainer: container];
	
	//NSLog(@"Returns %d as number of items in browser view %@", count, sender);
	
	return count;
}

#if 0
- (void) browser:(NSBrowser *)sender createRowsForColumn: (int)column inMatrix: (NSMatrix *)matrix
{
	NSString *path = [sender pathToColumn: column];
	ETContainer *container = [self container];
	int count = 0;
	
	if (path == nil || [path isEqual: @""])
		path = @"/";
	
	path = [[[container path] stringByAppendingPathComponent: path] stringByStandardizingPath];
		
	count = [[container source] numberOfItemsAtPath: path inContainer: container];
	
	NSLog(@"Returns %d as number of items in browser view %@", count, sender);
	
	//NSMutableArray *columnCells = [NSMutableArray array];
	NSSize newCellSize = [matrix cellSize];
	
	for (int i = 0; i < count; i ++)
		[matrix putCell: [[sender cellPrototype] copy] atRow: i column: column];
	
	//NSLog(@"Adds column cells %@ based on %@", columnCells, [[sender cellPrototype] copy]);
	
	// NOTE: Unable to make -addColumnWithCells: work so -putCell:atRow:column 
	// is used instead
	//[matrix addColumnWithCells: columnCells];
	
	newCellSize.height = DEFAULT_ROW_HEIGHT * [container itemScaleFactor];
	NSLog(@"Resize %@ cell size from %@ to %@", matrix, 
				NSStringFromSize([matrix cellSize]), 
				NSStringFromSize(newCellSize));
	[matrix setCellSize: newCellSize];
}
#endif

- (void) browser: (NSBrowser *)sender willDisplayCell: (id)cell atRow: (int)row column: (int)column
{
	NSString *path = [sender pathToColumn: column];
	ETLayoutItem *item = nil;
	ETContainer *container = [self container];
	
	if (path == nil || [path isEqual: @""])
		path = @"/";
	
	path = [[[container path] stringByAppendingPathComponent: path] stringByStandardizingPath];
	
	path = [path stringByAppendingPathComponent: [NSString stringWithFormat: @"%d", row]];
	item = [[container source] itemAtPath: path inContainer: container];
	
	if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		[cell setLeaf: NO];
	}
	else
	{
		[cell setLeaf: YES];
	}
	
	//NSLog(@"Returns %@ as object value in browser view %@", [item valueForProperty: @"name"], sender);
	
	[cell setStringValue: [item valueForProperty: @"name"]];

	if ([cell isKindOfClass: [NSBrowserCell class]])
	{
		NSImage *icon = [item valueForProperty: @"icon"];
		NSSize cellSize = [[sender matrixInColumn: column] cellSize];
		NSSize updatedIconSize = [icon size];
		
		/* Take care to resize image of brower cell to cell size computed by 
		   -resizeLayoutItems:toScaleFactor: */
		if ([cell isKindOfClass: [FSBrowserCell class]])
		{
			[cell setIconImage: icon];
		}
		else /* NSBrowserCell and other subclasses */
		{
			updatedIconSize.height = cellSize.height;
			updatedIconSize.width = updatedIconSize.height;
			[icon setSize: updatedIconSize];
			[cell setImage: icon];
		}
	}
}

- (ETLayoutItem *) clickedItem
{
	NSBrowser *browserView = (NSBrowser *)_displayViewPrototype;
	ETContainer *container = [self container];
	NSString *path = [container path];
	ETLayoutItem *item = nil;
	
	//selectedCell selectedColumn pathToColumn: selectedRowInColumn:
	//int rowIndex = [browserView selectedRowInColumn: [browserView selectedColumn]];
	path = [[path stringByAppendingPathComponent: [browserView path]] stringByStandardizingPath];
	item = [[container source] itemAtPath: path inContainer: container];
	
	//NSLog(@"-clickedItem in %@ with browser path %@", self, path);
	
	return item;
}

@end


// FIXME: We should remove this hack to simulate we are a scrollview.
@interface NSBrowser (EtoileETBrowserLayout)
- (NSView *) documentView;
@end

@implementation NSBrowser (EtoileETBrowserLayout)

/* ETContainer expects -displayView to be a scroll view, so we fake NSBrowser 
   to respond like NSScrollView. See -[ETContainer syncDisplayViewWithContainer] */
- (NSView *) documentView
{
	return self;
}

@end


