//
//  AnyCell.h
//  SPoT HW4
//
//  Created by Robert Lummis on 3/22/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnyCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *subtitle;

@end
