//
//  TaskTableTableViewController.m
//  iDS
//
//  Created by Roman on 11.11.14.
//  Copyright (c) 2014 Roman. All rights reserved.
//

#import "TaskTableTableViewController.h"
#import "FirstViewController.h"
#import "AVFoundation/AVFoundation.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>


@interface TaskTableTableViewController ()
@property (strong, nonatomic) FirstViewController *fv_controller;
@property (strong, nonatomic) MPMoviePlayerController * moviePlayer;
@property (strong, nonatomic) AVPlayer * avPlayer;
@property (nonatomic) int counter;
@end

@implementation TaskTableTableViewController

//NSMutableData* receivedData;
//NSString* currentURL;
//NSString* fileName;
UIProgressView *progress;
UIAlertView *av;
float expectedBytes;
-(void) updateArray{
    _items = [[NSMutableArray alloc] init];
    
    NSString *docsDir;
    NSArray  *dirPaths;
    sqlite3  *samplesBD;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir  = dirPaths[0];
    NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:  @"ids_database.db"]];
    //NSLog(@"%@", databasePath);
    const char *dbpath = [databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &samplesBD) == SQLITE_OK){
        sqlite3_stmt *statement;
        
        NSString * tmp = @"SELECT COUNT(*) FROM TASKS;";
        const char *tmp_query_stmt = [tmp UTF8String];
         if (sqlite3_prepare_v2(samplesBD, tmp_query_stmt, -1, &statement, nil)==SQLITE_OK) {
            _counter = sqlite3_column_int(statement, 0);
             //NSLog(@"%d", _counter);
         } else {
             NSLog(@"Count err!!!!");
         }
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM TASKS;"];
        const char *query_stmt = [sql UTF8String];
        
        
        if (sqlite3_prepare_v2(samplesBD, query_stmt, -1, &statement, nil)==SQLITE_OK) {
            while (sqlite3_step(statement)==SQLITE_ROW) {
    
                NSString *id_s = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                
                NSString *name = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                
               // NSString *path = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
                
                int counter = sqlite3_column_int(statement, 3);
                
                NSString* element = [NSString stringWithFormat:@"%@. %@ number of inputs: %d;", id_s, name, counter];
                NSLog(@"%@\n", element);
                [_items insertObject:element atIndex:[_items count]];
            }
            sqlite3_finalize(statement);
            sqlite3_close(samplesBD);
        }
    }
}

- (void)stopVideo:(AVPlayer*)player {
    [player pause];
    
}

-(void) updateTable{
    NSString *docsDir;
    NSArray  *dirPaths;
    sqlite3  *samplesBD;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir  = dirPaths[0];
    NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:  @"ids_database.db"]];
    //NSLog(@"%@", databasePath);
    const char *dbpath = [databasePath UTF8String];
    
    NSUInteger count = [_items count];
    //NSLog(@"count:%lu\n\n", (unsigned long)count);
    NSString* urlString = [NSString stringWithFormat: @"%@?vers=sig&db_vers=%lu", [[NSUserDefaults standardUserDefaults]stringForKey: @"download_preference"], count];
    NSLog(@"%@", urlString);
    NSURL *theURL = [NSURL URLWithString:urlString];
    NSString *doc = [NSString stringWithContentsOfURL:theURL encoding:NSUTF8StringEncoding error:nil];
    //NSLog(@"%@", doc);
    NSMutableArray *array = [NSMutableArray new];
    const char * doc_c = [doc UTF8String];
    NSMutableString * buffer = [NSMutableString new];
    for (int i = 0; i < [doc length]; i++){
        if(doc_c[i] == ';'){
            [array addObject:[NSString stringWithString: buffer]];
            [buffer setString:@""];
        } else
            [buffer appendFormat:@"%c", doc_c[i]];
    }
    
    av = [[UIAlertView alloc] initWithTitle:@"Downloading" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progress.frame = CGRectMake(0, 0, 200, 15);
    progress.bounds = CGRectMake(0, 0, 200, 15);
    progress.backgroundColor = [UIColor blackColor];
    
    [progress setUserInteractionEnabled:NO];
    [progress setTrackTintColor:[UIColor blueColor]];
    [progress setProgressTintColor:[UIColor redColor]];
    [av setValue:progress forKey:@"accessoryView"];
    [av show];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSLog(@"%lu", [array count]);
        for (int i = 0; i < [array count]; i++){
            NSString *fileName = [NSString stringWithFormat:@"task%lu.mp4", count+i+1];
            NSString *currentURL = array[i];
            [self downloadWithNsurlconnection: currentURL fileName:fileName];
        
            float progressive = (float)(i+1) / (float)([array count]+1);
            NSLog(@"%f", progressive);
            dispatch_async(dispatch_get_main_queue(), ^{
                [progress setProgress:progressive];
            });
        
        }
            [av dismissWithClickedButtonIndex:0 animated:YES];
    });
    
    

    for (int i = 0; i < [array count]; i++){
        NSString *fileName = [NSString stringWithFormat:@"task%lu.mp4", count+i+1];
        sqlite3_stmt *statement;
        NSString *documentsDirectory = [dirPaths objectAtIndex:0];
        NSString *videoPath = [documentsDirectory stringByAppendingPathComponent:fileName];
        NSString *insertSQL = [NSString stringWithFormat:
                               @"INSERT INTO TASKS (NAME, VIDEOPATH, COUNTER) VALUES (\"%@\", \"%@\", \"%d\");",
                               fileName, videoPath, 0];
        //NSLog(@"%@", insertSQL);
        const char *insert_stmt = [insertSQL UTF8String];
        if (sqlite3_open(dbpath, &samplesBD) == SQLITE_OK){
            if(sqlite3_prepare_v2(samplesBD, insert_stmt, -1, &statement, NULL)!= SQLITE_OK){
                //NSLog(@"ERROROROROROROR!!!!");
            } //else NSLog(@"added");
        } else {
            //NSLog(@"ERROROROROROROR!!!!");
        }
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
           //NSLog(@"Success!");
        } else {
            //NSLog(@"Failed to add contact");
        }
        sqlite3_finalize(statement);
        sqlite3_close(samplesBD);
    }
    
    
    [self updateArray];
    [self.tableView reloadData];
}
-(void) uploadSamples{
    NSString *docsDir;
    NSArray  *dirPaths;
    sqlite3  *samplesBD;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir  = dirPaths[0];
    NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:  @"ids_database.db"]];
    
    const char *dbpath = [databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &samplesBD) == SQLITE_OK){
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM STATISTICS"];
        const char *query_stmt = [sql UTF8String];
        char *errMsg;
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(samplesBD, query_stmt, -1, &statement, nil)==SQLITE_OK) {
            while (sqlite3_step(statement)==SQLITE_ROW) {
                
                NSString *id_s = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                
                NSString *data = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                
                int type = sqlite3_column_int(statement, 2);
                
                NSString *stats = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement,3)];
                
                //CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
                NSString *uuidString = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
                //NSLog(@"%@", uuidString);
                NSString* params = [NSString stringWithFormat:@"vers=sig&user=ios-%@&type=%d&date=%@&stats=%@", uuidString, type, data, stats]; // задаем параметры POST запроса
                NSURL* url = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults]stringForKey: @"upload_preference"]]; // куда отправлять
                NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
                request.HTTPMethod = @"POST";
                request.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding]; // следует обратить внимание на кодировку
                
                // теперь можно отправить запрос синхронно или асинхронно
                NSData *server_answer = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                if(![[[NSString alloc] initWithData:server_answer encoding:NSUTF8StringEncoding]  isEqual:  @"0"]){
                    //NSLog(@"error");
                    break;
                }
                
                 //NSAssert(self.connection != nil, @"Failure to create URL connection.");
                
                
                
                
                
                
                
                NSString *element = [NSString stringWithFormat:@"id: %@; data: %@; type: %d;", id_s, data, type];
                
                NSString *sql_tmp = [NSString stringWithFormat:@"DELETE FROM STATISTICS WHERE id='%@'", id_s];
                const char *sql_stmt = [sql_tmp UTF8String];
                
                if (sqlite3_exec(samplesBD, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    //NSLog(@"Failed to create table STATISTICS");
                }
                
                //NSLog(@"%@\n", element);
            }
            sqlite3_finalize(statement);
            sqlite3_close(samplesBD);
        }
    }
    //[self updateTable];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Task mode"];
    
    [self updateArray];
    
    UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(updateTable)];
    UIBarButtonItem *uploadButton =   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(uploadSamples)];

    self.navigationItem.rightBarButtonItem = downloadButton;
    self.navigationItem.leftBarButtonItem  = uploadButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



-(void)downloadWithNsurlconnection:(NSString*) url fileName:(NSString*) fileName
{
        /*NSURL *url = [NSURL URLWithString:link];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    receivedData = [[NSMutableData alloc] initWithLength:0];
    
    
    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self     startImmediately:YES];*/
    NSURLResponse* response = nil;
    
    NSURLRequest* urlRequest =  [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    NSData* downloaded_data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:nil] ;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *videoPath = [documentsDirectory stringByAppendingPathComponent:fileName];
    //NSLog(@"%@", videoPath);
    NSError *error;
    bool success = [downloaded_data writeToFile:videoPath options:0 error:&error];
    if (!success) {
        //NSLog(@"writeToFile failed with error %@", error);
    } else {
        //NSLog(@"File saved successfully!");
    }
}

/*
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    progress.hidden = NO;
    [receivedData setLength:0];
    expectedBytes = [response expectedContentLength];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
    float progressive = (float)[receivedData length] / (float)expectedBytes;
    [progress setProgress:progressive];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection willCacheResponse:    (NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pdfPath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    NSLog(@"%@", pdfPath);
    NSLog(@"Succeeded! Received %lu bytes of data",(unsigned long)[receivedData length]);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    
    
    
    NSError *error;
    bool success = [receivedData writeToFile:pdfPath options:0 error:&error];
    if (!success) {
        NSLog(@"writeToFile failed with error %@", error);
    } else {
        NSLog(@"File saved successfully!");
    }
    
    
    progress.hidden = YES;
    
    //DON'T DELETE THIS!!!!!
    //NSURL *fileURL = [NSURL fileURLWithPath:pdfPath];
    //MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc]initWithContentURL:fileURL];
    //[moviePlayerViewController.moviePlayer setControlStyle:MPMovieControlStyleFullscreen];
    //[moviePlayerViewController.moviePlayer setShouldAutoplay:YES];
    //[moviePlayerViewController.moviePlayer setFullscreen:NO animated:YES];
    //[moviePlayerViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    //[moviePlayerViewController.moviePlayer setScalingMode:MPMovieScalingModeNone];
    //[moviePlayerViewController.moviePlayer setRepeatMode:MPMovieRepeatModeOne];
    //[self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
    //[av dismissWithClickedButtonIndex:0 animated:YES];
}
*/
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    NSString *item = [_items objectAtIndex:indexPath.row];
    cell.textLabel.text = item;
    return cell;
}

- (void) viewWillAppear:(BOOL)animated{
    [self updateArray];
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _fv_controller = [storyboard instantiateViewControllerWithIdentifier:@"FirstView"];
    [_fv_controller setType: (int)indexPath.row + 1];
    [self.navigationController pushViewController:_fv_controller animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
