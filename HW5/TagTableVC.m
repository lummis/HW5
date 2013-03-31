//
//  PhotoTableVCViewController.m
//  SPoT HW4
//
//  Created by Robert Lummis on 3/11/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import "TagTableVC.h"
#import "AnyCell.h"
#import "PhotoData.h"

@interface TagTableVC ()
@property (nonatomic, strong) PhotoData *db;
@end

@implementation TagTableVC

-(PhotoData *) db {
    if (!!!_db) {
        _db = [[PhotoData alloc] init];
    }
    return _db;
}

- (void) refreshPhotoArray {
    self.db.flickrPhotoArray = nil;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Tags";
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor orangeColor];
    self.refreshControl = refreshControl;
    [self.refreshControl addTarget:self action:@selector(refreshPhotoArray) forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.db.flickrTagDict count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if ( [cell isMemberOfClass:[AnyCell class]] ) {
        AnyCell *tagCell = (AnyCell *)cell;
        NSString *theTag = self.db.alphabetizedTags[indexPath.row];
        tagCell.title.text = [theTag capitalizedStringWithLocale:[NSLocale currentLocale]];
        int nPix = [ self.db.flickrTagDict[theTag] intValue];
        NSString *s = nPix == 1 ? @"photo" : @"photos";
        tagCell.subtitle.text = [[NSString stringWithFormat:@"%d ", nPix] stringByAppendingString:s];
    }
    return cell;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ( [sender isKindOfClass:[AnyCell class]] ) {
        AnyCell *cell = (AnyCell *)sender;
        NSString *selectedTag = [cell.title.text lowercaseString];
        if ( [segue.identifier isEqualToString:@"ShowTitles"] ) {
            if ( [segue.destinationViewController respondsToSelector:@selector(setPhotoArray:)] ) {
                NSMutableArray *itemsWithThisTag = [[NSMutableArray alloc] initWithCapacity:1];
                for (NSDictionary *d in self.db.flickrPhotoArray) {
                    LOG
                    if ( [d[@"tags"] rangeOfString:selectedTag].location != NSNotFound ) {
                        [itemsWithThisTag addObject:d];
                    }
                }
                [ segue.destinationViewController performSelector:@selector(setPhotoArray:) withObject:[itemsWithThisTag copy] ];
                if ( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ) {
                    [ segue.destinationViewController performSelector:@selector(setTitle:) withObject:[[NSString stringWithFormat:@"Photos with tag: "] stringByAppendingString:cell.title.text] ];
                } else {
                    [ segue.destinationViewController performSelector:@selector(setTitle:) withObject:cell.title.text ];
                }
            }
        }
    }
}

@end
