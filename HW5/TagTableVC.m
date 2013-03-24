//
//  PhotoTableVCViewController.m
//  SPoT HW4
//
//  Created by Robert Lummis on 3/11/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import "TagTableVC.h"
#import "FlickrFetcher.h"
#import "AnyCell.h"

@interface TagTableVC ()
@property (nonatomic, strong) NSArray *flickrPhotoArray;
@property (nonatomic, strong) NSMutableDictionary *flickrTagDict;
@property (nonatomic, strong) NSArray *alphabetizedTags;
@end

@implementation TagTableVC

- (NSArray *) flickrPhotoArray {
    if (!!!_flickrPhotoArray){
        _flickrPhotoArray = [FlickrFetcher stanfordPhotos];
    }
    return _flickrPhotoArray;
}

//key is a photo tag. value is number of photos with that tag. a photo can have many tags
- (NSMutableDictionary *) flickrTagDict {
    if (!!!_flickrTagDict) {
        NSMutableDictionary *md = [[NSMutableDictionary alloc] initWithCapacity:15];
        for (NSDictionary *photo in self.flickrPhotoArray) {
            NSArray *currentTags = [photo[@"tags"] componentsSeparatedByString:@" "];
            for (NSString *tag in currentTags) {
                md[tag] = @( [md[tag] intValue] + 1 );   //increment count of photos with this tag
            }
            currentTags = nil;
        }
        [md removeObjectsForKeys:@[@"cs193pspot", @"portrait", @"landscape"]];
        _flickrTagDict = md;
    }
    
    self.alphabetizedTags = [[_flickrTagDict allKeys] sortedArrayUsingComparator:^(id a, id b){
        return [a caseInsensitiveCompare:b];
    }];
    
    return _flickrTagDict;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Tags";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.flickrTagDict count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSArray *keys = [self.flickrTagDict allKeys];
    
    static NSString *CellIdentifier = @"TableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if ( [cell isMemberOfClass:[AnyCell class]] ) {
        AnyCell *tagCell = (AnyCell *)cell;
        NSString *theTag = self.alphabetizedTags[indexPath.row];
        tagCell.title.text = [theTag capitalizedStringWithLocale:[NSLocale currentLocale]];
        int nPix = [ self.flickrTagDict[theTag] intValue];
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
                for (NSDictionary *d in self.flickrPhotoArray) {
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
