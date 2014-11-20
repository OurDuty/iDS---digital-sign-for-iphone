//
//  FirstViewController.m
//  iDS
//
//  Created by Roman on 10.11.14.
//  Copyright (c) 2014 Roman. All rights reserved.
//

#import "FirstViewController.h"
#import <sqlite3.h>

@interface FirstViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *info_label;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDictionary *appDefaults;
@property (strong, nonatomic) NSString *data;
@property (nonatomic) sqlite3 * samplesDB;
@property (nonatomic) int type;
@property (strong, nonatomic) NSString *status;
@property (strong, nonatomic) NSString *databasePath;
@end


@implementation FirstViewController
bool marker = true;
bool animate = true;
double timerInterval = 0.02f;
int numOfStartedMoves = 0;

- (void) setType:(int)type{
    _type = type;
}

- (void)saveStringToDocuments:(NSString*) stringToSave {
    NSString* documentsFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* fileName = @"savedString.txt";
    NSString* path = [documentsFolder stringByAppendingPathComponent:fileName];
    
    [[NSFileManager defaultManager] createFileAtPath:path contents:[stringToSave dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Free input"];
    NSArray *tabs =  self.tabBarController.viewControllers;
    UIViewController *tab1 = [tabs objectAtIndex:0];
    tab1.tabBarItem.image = nil;
    UIViewController *tab2 = [tabs objectAtIndex:1];
    tab2.tabBarItem.image = nil;
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@"Free input"];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@"Task mode"];
    
    //[[self.tabBarController.viewControllers objectAtIndex:0] setImage:[UIImage imageNamed:@"light_blue_circle.png"]];
    //[[self.tabBarController.viewControllers objectAtIndex:1] setImage:[UIImage imageNamed:@"light_blue_circle.png"]];
    
    marker = true;
    if(_type){
        _info_label.text = [NSString stringWithFormat:@"Task mode enabled, task id:%d;", _type];
        NSArray  *dirPaths;
        dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *fileName = [NSString stringWithFormat:@"task%d.mp4", _type];
        NSString *documentsDirectory = [dirPaths objectAtIndex:0];
        NSString *videoPath = [documentsDirectory stringByAppendingPathComponent:fileName];
        NSURL *fileURL = [NSURL fileURLWithPath:videoPath];
        MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc]initWithContentURL:fileURL];
        [moviePlayerViewController.moviePlayer setControlStyle:MPMovieControlStyleFullscreen];
        [moviePlayerViewController.moviePlayer setShouldAutoplay:YES];
        [moviePlayerViewController.moviePlayer setFullscreen:NO animated:YES];
        [moviePlayerViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [moviePlayerViewController.moviePlayer setScalingMode:MPMovieScalingModeNone];
        [moviePlayerViewController.moviePlayer setRepeatMode:MPMovieRepeatModeOne];
        [self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
    }
    
    NSString *docsDir;
    NSArray *dirPaths;
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];

    _databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: @"ids_database.db"]];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: _databasePath ] == NO)
    {
        const char *dbpath = [_databasePath UTF8String];
        if (sqlite3_open(dbpath, &_samplesDB) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt =
            "CREATE TABLE IF NOT EXISTS STATISTICS (ID INTEGER PRIMARY KEY AUTOINCREMENT, DATE DATE, TYPE INTEGER, STATS TEXT)";
            
            if (sqlite3_exec(_samplesDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                _status = @"Failed to create table STATISTICS";
            }
            sql_stmt =
            "CREATE TABLE IF NOT EXISTS TASKS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, VIDEOPATH TEXT, COUNTER INTEGER)";
            if (sqlite3_exec(_samplesDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                _status = @"Failed to create table TASKS";
            }
            sqlite3_close(_samplesDB);
        } else {
            _status = @"Failed to open/create database";
        }
    }
    
    animate = [[NSUserDefaults standardUserDefaults] boolForKey:@"enabled_preference"];
    self.label.text = @"Ready!";
    _data = [[NSString alloc]init];
    _data = @"";
    
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}


- (void) saveData:(NSString*)data
{
    NSDate *dateToday =[NSDate date];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *date = [format stringFromDate:dateToday];
    
    sqlite3_stmt    *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_samplesDB) == SQLITE_OK)
    {
        
        NSString *insertSQL = [NSString stringWithFormat:
                               @"INSERT INTO STATISTICS (type, date, stats) VALUES (\"%d\", \"%@\", \"%@\")",
                               _type, date, data];
        
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(_samplesDB, insert_stmt,
                           -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE && _type)
        {
            
                NSString *incrementSQL = [NSString stringWithFormat:
                                          @"UPDATE TASKS SET COUNTER = COUNTER + 1 WHERE ID = %d", _type];
                
                const char *increment_stmt = [incrementSQL UTF8String];
                if(sqlite3_exec(_samplesDB, increment_stmt, NULL, NULL, NULL) == SQLITE_OK){
                    //NSLog(@"Counter incrementer");
                } else {
                    //NSLog(@"Counter incremention failed!");
                }
            _status = @"Success!";
            
        } else {
            _status = @"Failed to add contact";
        }
        //NSLog(@"%@", _status);
        sqlite3_finalize(statement);
        sqlite3_close(_samplesDB);
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSTimer*)timer {
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:timerInterval target:self selector:@selector(onTick:) userInfo:nil repeats:YES];
    }
    return _timer;
}

- (void)onTick:(NSTimer*)timer {
    marker = true;
}

- (void)animateTimer:(NSTimer*)theTimer {
    [(UIImageView*)[theTimer userInfo] removeFromSuperview];
}

- (void)touchesEndedTimer:(NSTimer*) timer {
    numOfStartedMoves--;
    if(numOfStartedMoves == 0){
        self.label.text = @"Data was saved!";
        _data = [NSString stringWithFormat:@"%@-2, -2;", _data];
        [self saveData:_data];
        _data = @"";
    }
}




- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    self.label.text = [NSString stringWithFormat:@"Down: %d %d", (int)touchLocation.x, (int)touchLocation.y];
    animate = [[NSUserDefaults standardUserDefaults] boolForKey:@"enabled_preference"];
    numOfStartedMoves++;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    //NSLog(@"%d", marker);
    if(marker) {
        self.label.text = [NSString stringWithFormat:@"Moved: %d %d", (int)touchLocation.x, (int)touchLocation.y];
        _data = [NSString stringWithFormat:@"%@%d, %d;\n", _data, (int)touchLocation.x, (int)touchLocation.y];
        if(animate){
            UIImage * myImage = [UIImage imageNamed: @"light_blue_circle.png"];
            UIImageView * myImageView = [[UIImageView alloc] initWithFrame:CGRectMake((int)touchLocation.x, (int)touchLocation.y, 10, 10)];
            [myImageView setImage:myImage];
            [self.view addSubview:myImageView];
            [NSTimer scheduledTimerWithTimeInterval:1.0
                                                              target:self
                                                            selector:@selector(animateTimer:)
                                                            userInfo:myImageView repeats:NO];
        }
    }
    marker = false;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    self.label.text = [NSString stringWithFormat:@"Up: %d %d", (int)touchLocation.x, (int)touchLocation.y];
    _data = [NSString stringWithFormat:@"%@-1, -1;\n", _data];
    NSString* tmp = [[NSUserDefaults standardUserDefaults] stringForKey:@"timer_preference"];
    float timeInterval = [tmp floatValue];
    NSLog(@"%f", timeInterval);
    [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                      target:self
                                                    selector:@selector(touchesEndedTimer:)
                                                    userInfo:nil repeats:NO];
    
}

@end
