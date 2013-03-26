//
//  TitleTableVC.m
//  SPoT HW4
//
//  Created by Robert Lummis on 3/12/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import "TitleTableVC.h"
#import "FlickrFetcher.h"
#import "AnyCell.h"
#import "PhotoData.h"

#define NRECENTS 5

@interface TitleTableVC ()
@property (nonatomic, strong) NSArray *alphabetizedTitles;
@property (nonatomic, strong) PhotoData *db;

@end

@implementation TitleTableVC

-(PhotoData *) db {
    if (!!!_db) {
        _db = [[PhotoData alloc] init];
    }
    return _db;
}

- (void) setPhotoArray:(NSArray *)photoArray {
    _photoArray = photoArray;
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.recents = [[defaults arrayForKey:@"recents"] mutableCopy];
    self.sortByRecent = NO;
}

- (NSMutableArray *) recents {
    if (!!!_recents) {
        _recents = [NSMutableArray arrayWithCapacity:1];
    }
    return _recents;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.photoArray count];
}

- (NSArray *) alphabetizedTitles {
    NSArray *array = [self.photoArray sortedArrayUsingComparator:^(id a, id b){
        return [ a[@"title"] caseInsensitiveCompare:b[@"title"] ];
    }];
    return array;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableCell";
    AnyCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
        //description added to the following to avoid a crash if the content is NSNULL
    if (!!!self.sortByRecent) {
        cell.title.text = [ self.alphabetizedTitles[indexPath.row][@"title"] description ];
        cell.subtitle.text = [ self.alphabetizedTitles[indexPath.row][@"description"][@"_content"] description ];
    } else {
        cell.title.text = [ self.photoArray[indexPath.row][@"title"] description ];
        cell.subtitle.text = [ self.photoArray[indexPath.row][@"description"][@"_content"] description ];
    }
    
    return cell;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSDictionary *photo;
    NSString *title;
    
    if ( self.sortByRecent ) {
        photo = self.recents[indexPath.row];
        title = [[self.recents[indexPath.row] objectForKey:@"title"] description];
    } else {
        photo = self.alphabetizedTitles[indexPath.row];
        title = [[self.alphabetizedTitles[indexPath.row] objectForKey:@"title"] description];
    }
    
    NSURL *url = [self.db urlForPhoto:photo];
    if ( [segue.identifier isEqualToString:@"ShowRecentImage"] || [segue.identifier isEqualToString:@"ShowImage"] ) {
        if ( [segue.destinationViewController respondsToSelector:@selector(setImageURL:)] ) {
            [segue.destinationViewController performSelector:@selector(setImageURL:) withObject:url];
            [segue.destinationViewController performSelector:@selector(setTitle:) withObject:title];
        }
    }
    
    [self.recents removeObject:photo];  //does nothing if photo is not present
    [self.recents insertObject:photo atIndex:0];
    [self truncateRecents];
    [[NSUserDefaults standardUserDefaults] setObject:self.recents forKey:@"recents"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) truncateRecents {
    while ( [self.recents count] > NRECENTS ) {
        [self.recents removeObjectAtIndex:NRECENTS];
    }
}

@end
