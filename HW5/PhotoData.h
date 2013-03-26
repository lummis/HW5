//
//  PhotoData.h
//  HW5
//
//  Created by Robert Lummis on 3/26/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhotoData : NSObject
@property (nonatomic, strong) NSArray *flickrPhotoArray;
@property (nonatomic, strong) NSMutableDictionary *flickrTagDict;
@property (nonatomic, strong) NSArray *alphabetizedTags;

- (NSURL *) urlForPhoto:(NSDictionary *)photo;

@end
