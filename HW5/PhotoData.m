//
//  PhotoData.m
//  HW5
//
//  Created by Robert Lummis on 3/26/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import "PhotoData.h"
#import "FlickrFetcher.h"

@interface PhotoData()
@property (nonatomic, strong) NSString *baseFileName;

//TOC = Table of Contents. array of dicts, most recent first
//each dict contains url, fileString for name of imageData file, size of imageData
@property (nonatomic, strong) NSMutableArray *cacheTOC;
@property (nonatomic) NSUInteger maxCacheSize;

@end

@implementation PhotoData

    //array of urls and corresponding imageData file references, most recent first
- (NSMutableArray *) cacheTOC {
    if (!!!_cacheTOC) {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        _cacheTOC = [[ud arrayForKey:@"cacheTOC"] mutableCopy];
        if (!!!_cacheTOC) {
             _cacheTOC = [[NSMutableArray alloc] initWithCapacity:1];
        }
    }
    return _cacheTOC;
}

- (NSUInteger) maxCacheSize {
    if (!!!_maxCacheSize) {
        _maxCacheSize = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ?
        3500000 : 1500000;
    }
    return _maxCacheSize;
}

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
    if ( !!!url ) return nil;
    
    NSData *imageData = [self imageDataFromCacheForUrl:url];
    if (imageData) {
        NSLog(@"got image data from file. length: %d", [imageData length]);
    } else {
        NSLog(@"did NOT get image data from file.");
    }
    if (!!!imageData) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        imageData = [[NSData alloc] initWithContentsOfURL:url];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
    NSLog(@"\nurl: %@    size of imageData in bytes: %d\n\n", url, imageData.length);
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    [self updateCacheWithURL:url imageData:imageData];
    return image;
}

- (void) updateCacheWithURL:(NSURL *)url imageData:(NSData *)data {
    NSInteger index = -1;
        //if url is in cache set index to its position
        //use url as string because NSUserDefaults can't store array containing NSURL objects
    for (int i = 0; i < [self.cacheTOC count]; i++) {
        NSDictionary *d = self.cacheTOC[i];
        if ( [d[@"urlString"] isEqualToString:[url absoluteString]] ) {
            index = i;
            break;
        }
    }
        //url was found; now move it to index 0
    if (index != -1) {
        id object = [self.cacheTOC objectAtIndex:index];
        [self.cacheTOC removeObjectAtIndex:index];
        [self.cacheTOC insertObject:object atIndex:0];
        [self persistCacheTOC];
        return;
    }
    
        //this is a new url so add to the cache
        //[url relativeString] and [url absoluteString] give the same string value
    NSString *fileString = [self fileStringFromURL:url];
    NSLog(@"fileString: %@", fileString);
    NSDictionary *urlDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             [url absoluteString], @"urlString",
                             fileString, @"fileString",
                             [NSNumber numberWithInt:data.length], @"fileSize",
                             nil];
    [self.cacheTOC insertObject:urlDict atIndex:0];
    [self saveImageData:data at:fileString];
    [self truncateCache];
    [self persistCacheTOC];

    NSLog(@"index: %d\n%@\n\n", index, self.cacheTOC);
}

- (void) persistCacheTOC {
    [[NSUserDefaults standardUserDefaults] setObject:self.cacheTOC forKey:@"cacheTOC"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

    //remove the least recently used cacheTOC entries and the corresponding files
    //until all files use no more than self.maxCacheSize bytes
- (void) truncateCache {
    NSUInteger nFilesToKeep = 0;
    NSUInteger bytesUsed = 0;
    for (int i = 0; i < [self.cacheTOC count]; i++) {
        NSDictionary *d = [self.cacheTOC objectAtIndex:i];
        bytesUsed += [d[@"fileSize"] intValue];
        if (bytesUsed > self.maxCacheSize) {
            break;
        } else {
            nFilesToKeep++;
        }
    }
    while ( [self.cacheTOC count] > nFilesToKeep ) {
        NSString *fileStringToDelete = [self.cacheTOC lastObject][@"fileString"];
        [self.cacheTOC removeLastObject];
        [self deleteFileAt:fileStringToDelete];
    }
}

- (NSData *) imageDataFromCacheForUrl:(NSURL *)url {
    NSString *s = [self fileStringFromURL:url];
    NSData *d = [[NSData alloc] initWithContentsOfFile:s];
    return d;
}

    //with url as a string, get the string after the last slash, remove extension (.jpg), prepend caches path
- (NSString *) fileStringFromURL:(NSURL *)url {
    NSString *s0 = [url description];
    NSRange r0 = [s0 rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/"] options:NSBackwardsSearch];
    NSString *s1 = [[s0 substringFromIndex:r0.location + 1] stringByDeletingPathExtension];
    return [self.baseFileName stringByAppendingPathComponent:s1];
}

- (NSString *) baseFileName {
    LOG
    if (!!!_baseFileName) {
        NSArray *cachesPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _baseFileName =  [cachesPaths objectAtIndex:0];
    }
    return _baseFileName;
}

- (void) deleteFileAt:(NSString *)fileString {
    dispatch_queue_t deleteFileQ = dispatch_queue_create("deleteFileQ", NULL);
    dispatch_async(deleteFileQ, ^{
        NSError *err;
        BOOL status = [[NSFileManager defaultManager] removeItemAtPath:fileString error:&err];
        NSLog(@"deleting file at fileString: %@... status: %d", fileString, status);
        if (err) NSLog(@"err: %@", err);
    } );
}

- (void) saveImageData:(NSData *)data at:(NSString *)fileString {
    dispatch_queue_t writeFileQ = dispatch_queue_create("writeFileQ", NULL);
    dispatch_async(writeFileQ, ^{
        NSError *err;
        BOOL status = [data writeToFile:fileString options:NSDataWritingAtomic error:&err];
        NSLog(@"writing data at fileString: %@... status: %d", fileString, status);
        NSLog(@"err: %@", err);
    } );
}

@end
