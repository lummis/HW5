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

#define NRECENTS 5

@interface TitleTableVC ()
@property (nonatomic, strong) NSArray *alphabetizedPhotos;
@end

@implementation TitleTableVC

- (void) setPhotoArray:(NSArray *)photoArray {
    LOG
    _photoArray = photoArray;
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    LOG
    [super viewDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.recents = [[defaults arrayForKey:@"recents"] mutableCopy];
    self.sortByRecent = NO;
}

- (NSMutableArray *) recents {
    LOG
    if (!!!_recents) {
        _recents = [NSMutableArray arrayWithCapacity:1];
    }
    return _recents;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    LOG
    return [self.photoArray count];
}

- (NSArray *) alphabetizedPhotos {
    NSArray *array = [self.photoArray sortedArrayUsingComparator:^(id a, id b){
        return [ a[@"title"] caseInsensitiveCompare:b[@"title"] ];
    }];
    return array;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LOG
    static NSString *CellIdentifier = @"TableCell";
    AnyCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
        //description added to the following to avoid a crash if the content is NSNULL
    if (!!!self.sortByRecent) {
        cell.title.text = [ self.alphabetizedPhotos[indexPath.row][@"title"] description ];
        cell.subtitle.text = [ self.alphabetizedPhotos[indexPath.row][@"description"][@"_content"] description ];
    } else {
        cell.title.text = [ self.photoArray[indexPath.row][@"title"] description ];
        cell.subtitle.text = [ self.photoArray[indexPath.row][@"description"][@"_content"] description ];
    }
    
    return cell;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    LOG
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSDictionary *photo;
    NSString *title;
    
    if ( self.sortByRecent ) {
        photo = self.recents[indexPath.row];
        title = [[self.recents[indexPath.row] objectForKey:@"title"] description];
    } else {
        photo = self.alphabetizedPhotos[indexPath.row];
        title = [[self.alphabetizedPhotos[indexPath.row] objectForKey:@"title"] description];
    }
    
    NSURL *url = [FlickrFetcher urlForPhoto:photo format:FlickrPhotoFormatLarge];
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
