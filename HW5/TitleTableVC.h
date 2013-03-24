//
//  TitleTableVC.h
//  SPoT HW4
//
//  Created by Robert Lummis on 3/12/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "PhotoVC.h"

@interface TitleTableVC : UITableViewController
@property (nonatomic, strong) NSArray *photoArray;   //array of dictionaries
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSMutableArray *recents;  //array of dictionaries of recently shown photos
@property (nonatomic) BOOL sortByRecent;   //NO for tagTable and titleTable, YES for recentsTable
@end
