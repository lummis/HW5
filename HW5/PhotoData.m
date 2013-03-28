//
//  PhotoData.m
//  HW5
//
//  Created by Robert Lummis on 3/26/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#define MAXCACHESIZE 1500000    //1.5 million bytes

#import "PhotoData.h"
#import "FlickrFetcher.h"

@interface PhotoData()
@property (nonatomic, strong) NSString *baseFileName;

//TOC = Table of Contents. array of dicts, most recent first
//each dict contains url, fileString for name of imageData file, size of imageData
@property (nonatomic, strong) NSMutableArray *cacheTOC;

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
    if (!!!imageData) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        imageData = [[NSData alloc] initWithContentsOfURL:url];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
    NSLog(@"\nurl: %@    size of imageData in bytes: %d\n\n", url, imageData.length);
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    [self updateCacheTOCWithURL:url imageData:imageData];
    return image;
}

- (NSData *) imageDataFromCacheForUrl:(NSURL *)url {
    return nil;
}

- (void) updateCacheTOCWithURL:(NSURL *)url imageData:(NSData *)data {
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
    //until all files use no more than MAXCACHESIZE bytes
- (void) truncateCache {
    NSUInteger nFilesToKeep = 0;
    NSUInteger bytesUsed = 0;
    for (int i = 0; i < [self.cacheTOC count]; i++) {
        NSDictionary *d = [self.cacheTOC objectAtIndex:i];
        bytesUsed += [d[@"fileSize"] intValue];
        if (bytesUsed > MAXCACHESIZE) {
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

- (NSString *) baseFileName {
    if (!!!_baseFileName) {
        NSString *tempPath = NSTemporaryDirectory();
        NSString *deviceType;
        if ( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ) {
            deviceType = @"iPad";
        } else {
            deviceType = @"iPhone";
        }
        _baseFileName = [[tempPath stringByAppendingPathComponent:deviceType] stringByAppendingString:@"/"];
    }
    return _baseFileName;
}

- (NSString *) fileStringFromURL:(NSURL *)url {
    NSString *fileName = [[[url pathComponents] lastObject] stringByDeletingPathExtension];
    return [self.baseFileName stringByAppendingString:fileName];
}

- (void) deleteFileAt:(NSString *)fileString {
    NSLog(@"virtually deleting file at fileString: %@", fileString);
}

- (void) saveImageData:(NSData *)data at:(NSString *)fileString {
    NSLog(@"virtually storing data at fileString: %@", fileString);
}

@end
