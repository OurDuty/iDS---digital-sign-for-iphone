//
//  TaskTableTableViewController.h
//  iDS
//
//  Created by Roman on 11.11.14.
//  Copyright (c) 2014 Roman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "AFNetworking.h"

@interface TaskTableTableViewController : UITableViewController{
    NSMutableArray *_items;
}

@end
