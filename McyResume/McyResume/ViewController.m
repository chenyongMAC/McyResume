//
//  ViewController.m
//  McyResume
//
//  Created by 陈勇 on 15/11/5.
//  Copyright © 2015年 陈勇. All rights reserved.
//

#import "ViewController.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

#define  kReceivedTotal @"receivedTotal"
#define kTotal @"total"

#define kFileTmpName @"tmp.mp3"
#define kFileFinalName @"file.mp3"

@interface ViewController (){
    
    UILabel *_progressLabel;
    UIProgressView *_progressView;
    
    BOOL _isDownLoading; //是否正在下载
    
    double _totalLength; //文件大小
    double _receivedLength; //累加接收的数据包大小
    
    NSMutableData *_downloadData; //保存下载数据
    
    NSString *_filePath; //临时文件的路径
    
    //全局连接对象，用它来取消下载
    NSURLConnection *_connection;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _loadLocalData];
   
    
}

#pragma mark - 读取本地下载文件的数据
-(void) _loadLocalData {
    //1.读取本地化的plist文件，获取已下载数据量和文件总大小
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
   
    //2.接收数据长度
    _receivedLength = [[userDefault objectForKey:kReceivedTotal] doubleValue];
    
    //3.数据总长度
    _totalLength = [[userDefault objectForKey:kTotal] doubleValue];
    
    //4.设置progressLabel数值、progressView的样式(百分比显示)
    _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 70, 100, 20)];
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 100, kScreenWidth, 20)];
    _progressView.progressViewStyle = UIProgressViewStyleDefault;
    [self.view addSubview:_progressView];
    [self.view addSubview:_progressLabel];
    
    if (_totalLength > 0) {
        double progress = _receivedLength / _totalLength;
        _progressLabel.text = [NSString stringWithFormat:@"%.2f%%", progress * 100];
        _progressView.progress = progress;
        
    } else {
        _progressLabel.text = @"0";
        _progressView.progress = 0;
    }
}
- (IBAction)startBtn:(UIButton *)sender {
     NSString *urlString = @"http://111.1.21.133/mobileoc.music.tc.qq.com/174362794.flac?continfo=0E94ACE597217834CC0B2936DDF9E0047B328688C4A368B4&vkey=9ECC50554ADCBD8BB7622CB6734596E5410573BD428BD13FC6955D6A2C7A684D229D661D0D7ED81EC0E5FF62F00C5816A07B831A227B3DC7&guid=27238e629f2f6ffc850c749439bf81a1824fc41d&fromtag=53&uin=290363831";
    
//    NSString *urlString = @"http://img1.imgtn.bdimg.com/it/u=1150982377,473646300&fm=21&gp=0.jpg";
    
    [self downloadDataBegin:urlString];
}

- (IBAction)stopBtn:(UIButton *)sender {
    
    [self downloadDataPause];
}


#pragma mark -开始下载网络数据
-(void) downloadDataBegin:(NSString *)urlString {
    if (!_isDownLoading) {
        //1.构造URL
        NSURL *url = [NSURL URLWithString:urlString];
        
        //2.构造reuqest
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        //3.通过http下载请求头来设置继续下载的位置
        NSString *value = [NSString stringWithFormat:@"bytes=%i-", (int)_receivedLength];
        
        //4.根据读取到的“继续下载位置”,设置请求头
        [request setValue:value forHTTPHeaderField:@"Range"];
        
        NSLog(@"继续下载:%@", request.allHTTPHeaderFields);
        
        //5.发送异步网络请求
        _connection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        //6.此时正在下载
        _isDownLoading = YES;
        
#pragma mark -  创建临时目录，保证下载数据的安全性
        //1.创建临时目录
        _filePath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/tmp/%@", kFileTmpName];
        
        NSLog(@"%@", _filePath);    //下载文件临时目录
        
        //2.判断临时文件是否存在，如果不存在则创建
        if (![[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
            //1)先创建临时文件夹 文件夹
            NSString *dirPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/tmp"];
            [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
            //2)创建空的临时文件 文件
            [[NSFileManager defaultManager] createFileAtPath:_filePath contents:nil attributes:nil];
        }
    }

}

#pragma mark -暂停下载网络数据
-(void) downloadDataPause {
    //1.取消下载
    [_connection cancel];
    
    //2.把数据包存入文件
    [self appendFileData:_downloadData];
    
    //3.释放内存
    _downloadData.data = nil;
    [_downloadData setData:nil];
    
    //4.设置下载状态为 NO
    _isDownLoading = NO;
    
    
#pragma mark - 暂停时，保存已下载数据量和文件总数据量到本地
    //保证程序退出后下次进入仍能实现断点续传
    //存储的主要是下载的长度和文件总长度
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:@(_receivedLength) forKey:kReceivedTotal];
    [userDefault setObject:@(_totalLength) forKey:kTotal];
    
    //把数据同步写入到plist文件
    [userDefault synchronize];

}

#pragma mark -封装把数据写入文件，附加到文件的末尾的方法
- (void)appendFileData:(NSData *)data {
    
    if (data.length == 0 || _filePath.length == 0 ) {
        return;
    }
    
    //(1) 创建文件句柄
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    
    //(2）把文件位置指针定位到末尾
    [fileHandle seekToEndOfFile];
    
    //(3）写入数据
    [fileHandle writeData:data];
    
    //(4) 关闭文件
    [fileHandle closeFile];

}

#pragma mark - NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    //1.获取要下载的文件的请求头
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSDictionary *fields = httpResponse.allHeaderFields;
    
    //2.总大小的获取仅计算一次，后面断点续传不需要计算
    if (_totalLength == 0) {
        
        NSNumber *length = fields[@"Content-Length"];
        _totalLength = [length doubleValue];
    }
    
    //3.创建NSData来保存下载的数据
    _downloadData = [[NSMutableData alloc] init];
    
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [_downloadData appendData:data];
    
    //根据当前下载的数据包大小来刷新进度条和Label的显示
    _receivedLength += data.length;
    double progress = _receivedLength / _totalLength;
    
    _progressLabel.text = [NSString stringWithFormat:@"%.2f%%", progress * 100];
    _progressView.progress = progress;
    
    //当缓冲数据包超过500K时，则写入文件
    if (_downloadData.length > 500 * 1024) {
        
        //把数据写到文件末尾处
        [self appendFileData:_downloadData];
        
        //释放内存
        [_downloadData setData:nil];
        
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    //1.下载完成
    _isDownLoading = NO;
    _progressLabel.text = @"下载完成";
    
    //2.把数据写入文件
    [self appendFileData:_downloadData];
    
    //3.释放内存
    _downloadData.data = nil;

#pragma mark - 将下载完成的文件从临时目录剪切到目录目录
    NSFileManager *manager = [NSFileManager defaultManager];
    
    //1.确定目录文件路径
    NSString *targetFilePath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", kFileFinalName];
    
    //2.判断目标文件是否存在，如果存在把旧文件删除，准备剪切操作
    //###:(如果之前下载了该文件，现在在tmp目录中有了新下载的内容，要把之前的文件删除，保留最新的文件)
    if ([manager fileExistsAtPath:targetFilePath]) {
        [manager removeItemAtPath:targetFilePath error:nil];
    }
    
    //3.剪切方法的限制：不能把已存在文件覆盖，如果此文件存在，在剪切之前需要先删除
    [manager moveItemAtPath:_filePath toPath:targetFilePath error:nil];
    
    
#pragma mark - 下载完成时，清空本地数据存储
    _receivedLength = 0;
    _totalLength = 0;
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:@(_receivedLength) forKey:kReceivedTotal];
    [userDefault setObject:@(_totalLength) forKey:kTotal];
    
    //把数据同步写入到plist文件
    [userDefault synchronize];
    
    //4.下载完成后把已下载数据量和文件总大小清零。
//    _receivedLength = 0;
//    _totalLength = 0;
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
