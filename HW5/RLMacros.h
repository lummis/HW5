//
//  RLMacros.h
//
//  Created by Robert Lummis on 2/11/13.
//  Copyright (c) 2013 Electric Turkey Software. All rights reserved.
//

#ifndef RLMacros_h
#define RLMacros_h

#define VARLOG(...) NSLog(__VA_ARGS__)

#define LOG VARLOG( @"\n|... THREAD: %@\n|... SELF:   %@\n|... METHOD: %@(%d)\n\n", \
[NSThread currentThread], self, NSStringFromSelector(_cmd), __LINE__) ;

#endif
