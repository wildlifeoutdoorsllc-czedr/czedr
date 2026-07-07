//
//  NSData+Encryption.h
//  Czedr
//
//  Created by Mind Roots New on 04/06/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Encryption)

-(NSData *)AES256EncryptWithKey:(NSString *)key;
-(NSData *)AES256DecryptWithKey:(NSString *)key;

@end
