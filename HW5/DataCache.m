//
//  DataCache.m
//  HW5
//
//  Created by Robert Lummis on 3/29/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import "DataCache.h"
#define CACHEDIRECTORYNAME @"HW5Files"

@interface DataCache()

    //TOC = Table of Contents. array of dicts, most recent first
    //each dict contains url, fileString for name of imageData file, size of imageData
@property (nonatomic, strong) NSMutableArray *cacheTOC;
@property (nonatomic, strong) NSString *cacheDirectoryName;
@property (nonatomic) NSUInteger maxCacheSize;

@end

@implementation DataCache

#pragma mark -  Singleton stuff

+(id) sharedCache {
    static DataCache *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[DataCache alloc] init];
    });
    return singleton;
}

-(id) init {
    LOG
    if ( ( self = [super init] ) ) {

    }
    return self;
}

    //array of urls and corresponding imageData file references, most recent first
- (NSMutableArray *) cacheTOC {
    LOG
    if (!!!_cacheTOC) {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        _cacheTOC = [[ud arrayForKey:@"cacheTOC"] mutableCopy];
        if (!!!_cacheTOC) {
            _cacheTOC = [[NSMutableArray alloc] initWithCapacity:1];
        }
        
        BOOL isDirectory = NO;
            //if _cacheTOC doesn't match actual files erase files and _cacheTOC
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *err;
        NSArray *fileNames = [fm contentsOfDirectoryAtPath:[self cacheDirectoryName] error:&err];
        
        [fm fileExistsAtPath:[fileNames lastObject] isDirectory:&isDirectory];
        if (err) {
            NSLog(@"cacheTOC invalid");
            [[[UIApplication sharedApplication] delegate] applicationWillTerminate:[UIApplication sharedApplication]];
            exit(1);
        }
        if ( [fileNames count] != [_cacheTOC count] ) { //lazy check; should really verify names and sizes
            [_cacheTOC removeAllObjects];
            [ud setObject:_cacheTOC forKey:@"cacheTOC"];
            [ud synchronize];
            BOOL ok = YES;
            for (NSString *fileName in fileNames) {
                ok = [fm removeItemAtPath:fileName error:&err];
                if (!!!ok) {
                    NSLog(@"error removing cache file: %@... err: %@", fileName, err);
                    [[[UIApplication sharedApplication] delegate] applicationWillTerminate:[UIApplication sharedApplication]];
                    exit(1);
                }
            }
        }
    }
    return _cacheTOC;
}

- (void) updateCacheWithURL:(NSURL *)url imageData:(NSData *)data {
    LOG
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
        [self saveCacheTOC];
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
    [self saveCacheTOC];
    
    NSLog(@"index: %d\n%@\n\n", index, self.cacheTOC);
}

- (NSData *) imageDataForURL:(NSURL *)url {
    LOG
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
    [self updateCacheWithURL:url imageData:imageData];
    return imageData;
}

- (NSData *) imageDataFromCacheForUrl:(NSURL *)url {
    LOG
    NSString *s = [self fileStringFromURL:url];
    NSData *d = [[NSData alloc] initWithContentsOfFile:s];
    return d;
}


- (void) saveCacheTOC {
    LOG
    [[NSUserDefaults standardUserDefaults] setObject:self.cacheTOC forKey:@"cacheTOC"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

    //remove the least recently used cacheTOC entries and the corresponding files
    //until all files use no more than self.maxCacheSize bytes
- (void) truncateCache {
    LOG
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

- (NSUInteger) maxCacheSize {
    if (!!!_maxCacheSize) {
        _maxCacheSize = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ?
        3500000 : 1500000;
    }
    return _maxCacheSize;
}

    //make ~/Library/Caches/HW5Files directory to hold the imageDate files for each photo in the cacheTOC
    //make the subdirectory if it doesn't already exist
- (NSString *) cacheDirectoryName {
    LOG
    if (!!!_cacheDirectoryName) {
        NSArray *cachesPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _cacheDirectoryName =  [[cachesPaths objectAtIndex:0] stringByAppendingPathComponent:CACHEDIRECTORYNAME];
        NSLog(@"_cacheDirectoryName: %@", _cacheDirectoryName);
        if ( !!! [[NSFileManager defaultManager] fileExistsAtPath:_cacheDirectoryName] ) {
            NSError *err;
            BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:_cacheDirectoryName
                                      withIntermediateDirectories:NO attributes:nil error:&err];
            if (!!!success) {
                NSLog(@"can't create %@ directory. err: %@", CACHEDIRECTORYNAME, err);
            }
        }
    }
    return _cacheDirectoryName;
}

    //make string version of file name for an imageData file, using url as a string
    //from url as a string get the substring after the last slash, remove extension (.jpg), prepend caches path
- (NSString *) fileStringFromURL:(NSURL *)url {
    LOG
    NSString *s0 = [url description];
    NSRange r0 = [s0 rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/"] options:NSBackwardsSearch];
    NSString *s1 = [s0 substringFromIndex:r0.location + 1]; //+1 to skip over last slash
    NSString *s2 = [s1 stringByDeletingPathExtension];
    return [self.cacheDirectoryName stringByAppendingPathComponent:s2];
}

- (void) saveImageData:(NSData *)data at:(NSString *)fileString {
    LOG
    dispatch_queue_t writeFileQ = dispatch_queue_create("writeFileQ", NULL);
    dispatch_async(writeFileQ, ^{
        NSError *err;
        BOOL status = [data writeToFile:fileString options:NSDataWritingAtomic error:&err];
        NSLog(@"writing data at fileString: %@... status: %d", fileString, status);
        NSLog(@"err: %@", err);
    } );
}

- (void) deleteFileAt:(NSString *)fileString {
    LOG
    dispatch_queue_t deleteFileQ = dispatch_queue_create("deleteFileQ", NULL);
    dispatch_async(deleteFileQ, ^{
        NSError *err;
        BOOL status = [[NSFileManager defaultManager] removeItemAtPath:fileString error:&err];
        NSLog(@"deleting file at fileString: %@... status: %d", fileString, status);
        if (err) NSLog(@"err: %@", err);
    } );
}

@end
