//
//  PhotoData.m
//  HW5
//
//  Created by Robert Lummis on 3/26/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import "PhotoData.h"
#import "FlickrFetcher.h"
#import "DataCache.h"

@implementation PhotoData

- (NSArray *) flickrPhotoArray {
    LOG
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

- (NSURL *) urlForPhoto:(NSDictionary *)photo {
    LOG
    NSURL *url;
    if ( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ) {
        url = [FlickrFetcher urlForPhoto:photo format:FlickrPhotoFormatOriginal];
    } else {
        url = [FlickrFetcher urlForPhoto:photo format:FlickrPhotoFormatLarge];
    }
    return url;
}

- (UIImage *) imageForURL:(NSURL *)url {
    NSData *imageData = [[DataCache sharedCache] imageDataForURL:url];
    return [[UIImage alloc] initWithData:imageData];
}

@end
