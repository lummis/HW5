//
//  RecentsTableVC.m
//  SPoT HW4
//
//  Created by Robert Lummis on 3/16/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import "RecentsTableVC.h"

@implementation RecentsTableVC

- (void) viewWillAppear:(BOOL)animated {
    LOG
    [super viewWillAppear:NO];
    self.recents = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recents"] mutableCopy];
    [self setPhotoArray:self.recents];
    self.sortByRecent = YES;
    self.title = @"Recents";
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    LOG
    int recentsCount = [self.recents count];    //to make it get recents from userDefaults
    return recentsCount ;
}

@end
