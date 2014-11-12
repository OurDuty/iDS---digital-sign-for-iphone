//
//  SamplesDataset.h
//  iDS
//
//  Created by Roman on 11.11.14.
//  Copyright (c) 2014 Roman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SamplesDataset : NSObject{
    sqlite3* database;
}
- (NSArray *)failedBankInfos;

@end
