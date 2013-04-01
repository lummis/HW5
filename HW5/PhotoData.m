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

- (void) updateFlickrPhotoArray {
    dispatch_queue_t dataFetchQ = dispatch_queue_create("dataFetchQ", NULL);
    dispatch_async( dataFetchQ, ^{
        self.flickrPhotoArray = [FlickrFetcher stanfordPhotos];
            //if we don't run something on the main queue we have to wait for the thread to time out
        dispatch_async(dispatch_get_main_queue(), ^{
            self.flickrTagDict = nil;   //make tag dict get created (or recreated)
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification
                                                                    notificationWithName:@"photoDataUpdated"
                                                                    object:self]];
        } );
    } );
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
    self.alphabetizedTags = [[_flickrTagDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    return _flickrTagDict;
    
//        //alternate sorting method
//    self.alphabetizedTags = [[_flickrTagDict allKeys] sortedArrayUsingComparator:^(id a, id b){
//        return [a caseInsensitiveCompare:b];
//    }];
    
}

- (NSURL *) urlForPhoto:(NSDictionary *)photo {
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
