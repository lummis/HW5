//
//  PhotoData.m
//  HW5
//
//  Created by Robert Lummis on 3/26/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import "PhotoData.h"
#import "FlickrFetcher.h"

@implementation PhotoData

- (NSArray *) flickrPhotoArray {
    if (!!!_flickrPhotoArray){
        _flickrPhotoArray = [FlickrFetcher stanfordPhotos];
    }
    return _flickrPhotoArray;
}

@end
