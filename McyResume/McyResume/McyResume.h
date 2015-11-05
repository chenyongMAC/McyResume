//
//  McyResume.h
//  McyResume
//
//  Created by 陈勇 on 15/11/5.
//  Copyright © 2015年 陈勇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"


#pragma mark -Block方法
typedef void(^DownloadProgress)(CGFloat progress, CGFloat totalMBRead, CGFloat totalMBExpectedToRead);
typedef void(^DownloadSuccess)(AFHTTPRequestOperation *operation, id responseObject);
typedef void(^DownloadFailure)(AFHTTPRequestOperation *operation, NSError *error);


@interface McyResume : NSObject

#pragma mark - 下载方法
+ (AFHTTPRequestOperation *)downloadFileWithURLString:(NSString *)URLString
                                            cachePath:(NSString *)cachePath
                                        progressBlock:(DownloadProgress)progressBlock
                                         successBlock:(DownloadSuccess)successBlock
                                         failureBlock:(DownloadFailure)failureBlock;

#pragma mark - 暂停方法
+ (void)pauseWithOperation:(AFHTTPRequestOperation *)operation;


#pragma mark - 实例方法
- (void)pauseWithOperation:(AFHTTPRequestOperation *)operation;

- (AFHTTPRequestOperation *)downloadFileWithURLString:(NSString *)URLString
                                            cachePath:(NSString *)cachePath
                                        progressBlock:(DownloadProgress)progressBlock
                                         successBlock:(DownloadSuccess)successBlock
                                         failureBlock:(DownloadFailure)failureBlock;

#pragma mark - 获取文件大小
- (unsigned long long)fileSizeForPath:(NSString *)path;

@end





