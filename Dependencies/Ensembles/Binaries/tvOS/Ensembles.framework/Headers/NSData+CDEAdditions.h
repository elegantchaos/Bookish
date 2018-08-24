//
//  NSData+CDEAdditions.h
//  Ensembles iOS
//
//  Created by Drew McCormack on 11/06/14.
//  Copyright (c) 2014 The Mental Faculty B.V. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (CDEAdditions)

- (NSString *)cde_md5Checksum;
- (NSData *)cde_sha256Hash;

+ (NSData *)cde_dataWithBase64EncodedString:(NSString *)string;
- (NSString *)cde_base64EncodedString;

@end