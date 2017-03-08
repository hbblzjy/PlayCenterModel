//
//  PlayCenter.h
//  AudioDemo
//
//  Created by 1 on 15/5/14.
//  Copyright (c) 2015年 BBH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import "define.h"

@interface PlayCenter : NSObject
@property (nonatomic,strong) AVAudioPlayer *player;//音频对象
@property (nonatomic,strong) NSDictionary *musicInfo;//音频信息
@property(nonatomic,strong)NSArray *musicArray;//音频数组
@property(nonatomic,assign)NSInteger allNum;//音乐数量
@property(nonatomic,assign)NSInteger currentInt;//当前第几个音乐
@property(nonatomic,copy)NSString *currentUrlPathStr;//当前音频地址

//创建播放单例类
+ (PlayCenter *)shareCenter;
//记录音频播放的数组，并且根据点击的音频找到本地url地址，进行音乐播放
//- (NSDictionary *)play:(NSURL *)url;
- (NSDictionary *)play:(NSArray *)musicArray clickMusicPath:(NSDictionary *)urlDic;
//播放音频
- (void)play;
//暂停音频
- (void)pause;
//上一首
- (void)forwardItem;
//下一首
- (void)nextItem;
@end
