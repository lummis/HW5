//
//  DataCache.h
//  HW5
//
//  Created by Robert Lummis on 3/29/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

    //this is a singleton
    //caches image data (NSData, not UIImage or UIImageView)
    //gets data from a file if it exists and return it to caller
    //if file doesn't exist get data from flickr, save it to a file, return it to caller
    //caller of this class doesn't know whether the data came from a file or flickr
    //keep a TOC (table of contents) for cached data with network url, file name, data size
    //rearrange TOC each time so most recent is first
    //delete oldest files and their TOC entries when the total file space is too large
    //save the TOC to user defaults
    //at startup verify that the file names in the TOC match the actual files 

#import <Foundation/Foundation.h>

@interface DataCache : NSObject

+ (id) sharedCache;
- (NSData *) imageDataForURL:(NSURL *)url;

@end
