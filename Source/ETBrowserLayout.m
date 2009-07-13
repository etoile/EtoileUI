/*  <title>ETBrowserLayout</title>

	ETBrowserLayout.m
	
	<abstract>Description forthcoming.</abstract>
 
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

#import <EtoileFoundation/Macros.h>
#import "ETBrowserLayout.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETCompatibility.h"

#import "FSBrowserCell.h"

#define DEFAULT_ROW_HEIGHT 20

/** ETBrowserLayout wraps AppKit NSBrowser control in term of EtoileUI architecture.
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
	- 'name', 'value', 'displayName' for text part of the row
	- 'icon' for icon part of the row
	'name' is never looked up directly but through 'displayName'.
	
	NOTE: row resizing based on -[ETLayoutItemGroup itemScaleFactor] isn't yet 
	supported.
*/

/* The browser delegate navigates the layout item tree by associating each cell 
   to its related item with [cell setRepresentedObject: item].
   Another way to navigate the layout item tree would to build index paths by
   using -[NSBrowser selectedCellInColumn:] for every columns and finding the
   index of each selected cell. The resulting index path could then be used 
   like that [browserItem itemAtIndexPath: indexPath]. However this method
   would involve to check the validity of the index path in case the layout 
   item tree has been modified since the last reload.
   The browser -path property cannot be used because it isn't always built from
   'identifier' property of the layout items. It may work in some cases when 
   'identifier' matches 'name', but never assumes this border case to be true.
   If no name is set on a layout item, the display name will be used (instead 
   of the identifier). Finally keep in mind, the 'identifier' property is used 
   to construct paths in the layout item tree and you should never write 
   code like [browserItem itemAtPath: [browser path]] in ETBrowserLayout. */


@implementation ETBrowserLayout

- (NSString *) nibName
{
	return @"BrowserPrototype";
}

- (void) setLayoutView: (NSView *)protoView
{
	[super setLayoutView: protoView];

	NSBrowser *browser = [self browser];
	
	[browser setCellClass: [FSBrowserCell class]];
	[browser setCellPrototype: AUTORELEASE([[FSBrowserCell alloc] init])];
	[browser setAction: @selector(click:)];
	[browser setDoubleAction: @selector(doubleClick:)];
	[browser setTarget: self];
	
	if ([browser delegate] == nil)
		[browser setDelegate: self];
}

- (NSBrowser *) browser
{
	return (NSBrowser *)[self layoutView];
}

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	NSBrowser *browserView = [self browser];
	
	// FIXME: Implement browser cell scaling to get 
	// -resizeLayoutItems:toScaleFactor: works as expected
	//[self resizeLayoutItems: items toScaleFactor: [[self layoutContext] itemScaleFactor]];
	
	// FIXME: The next lines shouldn't be needed but
	// -[ETWidgetLayout syncLayoutViewWithItem:] regularly overwrites what has 
	// been set in -setLayoutView:
	[browserView setDoubleAction: @selector(doubleClick:)];
	[browserView setAction: @selector(click:)];
	[browserView setTarget: self];		
	
	/* Only reload from the delegate if the layout item tree visible in the 
	   browser has been mutated */
	if (isNewContent)
	{
		if ([browserView delegate] == nil)
			[browserView setDelegate: self];

		// NOTE: -loadColumnZero reloads browser context unlike -setPath: @"/"
		[browserView loadColumnZero];
	}
}

- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	// NOTE: Always recompute row height from the original one to avoid really
	// value shifting quickly because of rounding.
	//float rowHeight = DEFAULT_ROW_HEIGHT * factor;
	int numberOfCols = [[self browser] numberOfVisibleColumns];
	NSMatrix *columnMatrix = nil;

	for (int i = 0; i < numberOfCols; i++)
	{
		NSSize newCellSize = NSZeroSize;
		
		columnMatrix = [[self browser] matrixInColumn: i];
		if (columnMatrix != nil)
		{
			newCellSize = [columnMatrix cellSize];
			newCellSize.height = DEFAULT_ROW_HEIGHT * factor;
			[columnMatrix setCellSize: newCellSize];

			ETDebugLog(@"Resize %@ cell size from %@ to %@", columnMatrix, 
				NSStringFromSize([columnMatrix cellSize]), 
				NSStringFromSize(newCellSize));
		}
	}
}

/* Selection */

// FIXME: Implements multiple selection support and sets selection by calling
// -setSelectionIndexPaths:. 
- (BOOL) browser: (NSBrowser *)sender selectCellWithString: (NSString *)title inColumn: (int)column
{
	BOOL selected = YES;
	NSString *path = [[sender pathToColumn: column] stringByAppendingPathComponent: title];
	ETLayoutItem *item = [[self layoutContext] itemAtPath: path];
	
	if (selected)
	{
		int row = [(ETLayoutItemGroup *)_layoutContext indexOfItem: item];

		// NOTE: Not really sure that's the best way to do it		
		[(ETLayoutItemGroup *)_layoutContext setSelectionIndex: row];
	}

	ETDebugLog(@"Cell selection did change to %@ in layout view %@ of %@", 
		[self selectionIndexPaths], [self layoutView], _layoutContext);
	
	return selected;
}

// FIXME: Implements multiple selection support and sets selection by calling
// -setSelectionIndexPaths:. 
// [sender selectedCells]; is probably helpful.
- (BOOL) browser: (NSBrowser *)sender selectRow: (int)row inColumn: (int)column
{
	BOOL selected = YES;
	
	// NOTE: Not really sure that's the best way to do it
	[(ETLayoutItemGroup *)_layoutContext setSelectionIndex: row];

	ETDebugLog(@"Row selection did change to %@ in layout view %@ of %@", 
		[self selectionIndexPaths], [self layoutView], _layoutContext);
	
	return selected;
}

/* Data Source */

- (int) browser: (NSBrowser *)sender numberOfRowsInColumn: (int)column
{
	ETLayoutItemGroup *item = nil;
	BOOL isFirstColumn = (0 == column);

	if (isFirstColumn)
	{
		item = _layoutContext;
	}
	else
	{
		// FIXME: Implement some sort of support for multiple selection in the 
		// right most column
		item = [[sender selectedCellInColumn: column - 1] representedObject];
	}
	NSAssert(item != nil, @"Parent item must never be nil in -browser:numberOfRowsInColumn:");
	NSAssert([item isGroup], @"Parent item must always be of ETLayoutItemGroup class kind");

	int nbOfItems = [[item arrangedItems] count];
	BOOL isFirstAccess = (0 == nbOfItems);

	if (isFirstAccess)
	{
		[item reloadIfNeeded];
		nbOfItems = [[item arrangedItems] count];	
	}
	
	ETDebugLog(@"Returns %d as number of items in browser view %@", nbOfItems, sender);
	
	return nbOfItems;
}

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)cell 
           atRow: (int)row 
          column: (int)column
{
	ETLayoutItemGroup *item = nil;
	BOOL isFirstColumn = (0 == column);
	
	if (isFirstColumn)
	{
		item = _layoutContext;
	}
	else
	{
		// FIXME: Implement some sort of support for multiple selection in the 
		// right most column
		item = [[sender selectedCellInColumn: column - 1] representedObject];
	}
	NSAssert(item != nil, @"Parent item must never be nil in -browser:numberOfRowsInColumn:");
	NSAssert([item isGroup], @"Parent item must always be of ETLayoutItemGroup class kind");

	ETLayoutItem *childItem = [[item arrangedItems] objectAtIndex: row];
	[cell setRepresentedObject: childItem];
	ETDebugLog(@"Set represented object %@ of cell %@", [cell representedObject], cell);

	if ([childItem isGroup])
	{
		[cell setLeaf: NO];
	}
	else
	{
		[cell setLeaf: YES];
	}

	// TODO: Let the developer customizes what value and icon are bound to and 
	// also makes use of a custom cell instead of FSBrowserCell. The best 
	// way is probably to provide a delegate method.
	id value = [childItem valueForProperty: kETDisplayNameProperty];

	NSAssert2(value != nil, @"Item %@ returns nil value in browser view %@ "
		@"and display name must never be nil", childItem, self);

	ETDebugLog(@"Returns %@ as object value in browser view %@", value, sender);
	
	/* See -tableView:objectValueForTableColumn:row: in ETTableLayout to 
	   understand -objectValue use. */
	[cell setStringValue: [value objectValue]];

	if ([cell isKindOfClass: [NSBrowserCell class]])
	{
		NSImage *icon = [childItem valueForProperty: kETIconProperty];
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

/* ETLayout overriden method. Called indirectly by -selectionIndexPaths in 
   -browserSelectionDidChange. */
- (NSArray *) selectedItems
{
	NSArray *selectedCells = [[self browser] selectedCells];
	NSMutableArray *selectedItems = 
		[NSMutableArray arrayWithCapacity: [selectedCells count]];
	
	FOREACH(selectedCells, aCell, NSCell *)
	{
		NSAssert([aCell representedObject] != nil, @"All browser cells must "
			@"have a represented object set");
		
		[selectedItems addObject: [aCell representedObject]];
	}

	return selectedItems;
}

/* We catch the selection change by receiving the action in -click: */
- (void) browserSelectionDidChange
{
	[self didChangeSelectionInLayoutView];
}

/* Actions */

/* NSBrowser action */
- (IBAction) click: (id)sender
{
	ETDebugLog(@"-click: row %d and column %d in %@", 
		[sender selectedRowInColumn: [sender selectedColumn]], 
		[sender selectedColumn], self);

	[self browserSelectionDidChange];
}

- (IBAction) doubleClick: (id)sender
{
	ETDebugLog(@"-doubleClick: row %d and column %d in %@", 
		[sender selectedRowInColumn: [sender selectedColumn]], 
		[sender selectedColumn], self);

	[self browserSelectionDidChange];

	[super doubleClick: sender];
}

- (ETLayoutItem *) doubleClickedItem
{
	ETLayoutItem *item = [[[self browser] selectedCell] representedObject];

	NSAssert(item != nil, @"All browser cells must have a represented object set");

	ETDebugLog(@"-doubleClickedItem %@ in %@ with browser path %@", item, self, 
		[[self browser] path]);
	
	return item;
}

@end


// FIXME: We should remove this hack to simulate we are a scrollview.
@interface NSBrowser (EtoileETBrowserLayout)
- (NSView *) documentView;
@end

@implementation NSBrowser (EtoileETBrowserLayout)

/* ETWidgetLayout expects -layoutView to be a scroll view, so we fake NSBrowser 
   to respond like NSScrollView. See -[ETWidgetLayout syncLayoutViewWithItem:]; */
- (NSView *) documentView
{
	return self;
}

@end

//
// Unused NSBrowser data source implementation
//

#if 0
- (void) browser:(NSBrowser *)sender createRowsForColumn: (int)column inMatrix: (NSMatrix *)matrix
{
	NSString *path = [sender pathToColumn: column];
	NSIndexPath *indexPath = nil;
	int count = 0;
	
	if (path == nil || [path isEqual: @""])
		path = @"/";
	
	indexPath = [[self layoutContext] indexPathForPath: path];
	NSAssert(indexPath != nil, @"Index path must never be nil in -browser:numberOfRowsInColumn:");
	
	count = [[[self layoutContext] source] itemGroup: [self layoutContext] numberOfItemsAtPath: indexPath];
	
	ETDebugLog(@"Returns %d as number of items in browser view %@", count, sender);
	
	//NSMutableArray *columnCells = [NSMutableArray array];
	NSSize newCellSize = [matrix cellSize];
	
	for (int i = 0; i < count; i ++)
		[matrix putCell: [[sender cellPrototype] copy] atRow: i column: column];
	
	//ETDebugLog(@"Adds column cells %@ based on %@", columnCells, [[sender cellPrototype] copy]);
	
	// NOTE: Unable to make -addColumnWithCells: work so -putCell:atRow:column 
	// is used instead
	//[matrix addColumnWithCells: columnCells];
	
	newCellSize.height = DEFAULT_ROW_HEIGHT * [[self layoutContext] itemScaleFactor];
	ETDebugLog(@"Resize %@ cell size from %@ to %@", matrix, 
				NSStringFromSize([matrix cellSize]), 
				NSStringFromSize(newCellSize));
	[matrix setCellSize: newCellSize];
}
#endif
