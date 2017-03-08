//
//  PlayCenter.m
//  AudioDemo
//
//  Created by 1 on 15/5/14.
//  Copyright (c) 2015年 BBH. All rights reserved.
//

#import "PlayCenter.h"

@implementation PlayCenter
static PlayCenter *center = nil;
+ (PlayCenter *)shareCenter
{
    if (!center) {
        center = [PlayCenter new];
    }
    return center;
    
}
- (id)init{
    if (self = [super init]) {
        //后台播放音频设置
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        [session setActive:YES error:nil];
        
        //让app支持接受远程控制事件
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
        self.currentUrlPathStr = @"1";
        
    }
    return self;
}


- (NSDictionary *)play:(NSArray *)musicArray clickMusicPath:(NSDictionary *)urlDic{
    
    self.musicArray = [NSArray arrayWithArray:musicArray];
    self.allNum = musicArray.count;
    
    self.musicInfo = urlDic;
    
    for (int i = 0; i < self.allNum; i++) {
        NSDictionary *dic = self.musicArray[i];
        if ([dic[@"filename"] isEqualToString:urlDic[@"filename"]]) {
            self.currentInt = i;
        }
    }
    
    NSString *path1 = [NSString stringWithFormat:@"%@/%@",[[NSUserDefaults standardUserDefaults]objectForKey:MP3URLPATH],urlDic[@"filename"]];
    //判断当前的当前音频是否一致
    if (![path1 isEqualToString:self.currentUrlPathStr]) {
        //如果不一致，音频对象滞空
        //播放之前先滞空
        [self.player stop];
        self.player = nil;
        
        self.currentUrlPathStr = path1;
        
        //NSLog(@"。。。。。。/.....地址%@",path1);
    }
    
    NSURL *url = [NSURL fileURLWithPath:path1];
    
    //如果音频已经播放，不再重新播放
    if (self.player.playing) {
        return urlDic;
    }
    
    UIBackgroundTaskIdentifier bgTask = 0;
    //判断是否有音频对象，没有创建
    if (_player == nil) {
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    }
    
    if([UIApplication sharedApplication].applicationState== UIApplicationStateBackground) {
        
        //NSLog(@"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx后台播放");
        
        [_player play];
        
        UIApplication *app = [UIApplication sharedApplication];
        UIBackgroundTaskIdentifier newTask = [app beginBackgroundTaskWithExpirationHandler:nil];
        
        if(bgTask!= UIBackgroundTaskInvalid) {
            
            [app endBackgroundTask: bgTask];
            
        }
        bgTask = newTask;
        
    }else{
        
        //NSLog(@"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx前台播放");
        
        [_player prepareToPlay];
        [_player setVolume:1.0];
        _player.numberOfLoops = 1; //设置音乐播放次数  -1为一直循环
        [_player play]; //播放
        
        //NSLog(@"音频正在播放。。。。。。。");
        
    }
    return urlDic;
    
}
- (NSDictionary *)getPlayInfo:(NSURL *)fileURL
{

    //    AudioFileTypeID fileTypeHint = kAudioFileMP3Type;
    NSString *fileExtension = [[fileURL path] pathExtension];
    if (![fileExtension isEqual:@"mp3"] && ![fileExtension isEqual:@"m4a"])
    {
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        [dict setObject:@"未知标题" forKey:MPMediaItemPropertyAlbumTitle];
        [dict setObject:@"未知歌手" forKey:MPMediaItemPropertyArtist];
        
        return dict;
    }

    AudioFileID fileID  = nil;
    OSStatus err        = noErr;
    
    err = AudioFileOpenURL( (__bridge CFURLRef) fileURL, kAudioFileReadPermission, 0, &fileID );
    if( err != noErr ) {
        NSLog( @"AudioFileOpenURL failed" );
    }
    UInt32 id3DataSize  = 0;
    err = AudioFileGetPropertyInfo( fileID,   kAudioFilePropertyID3Tag, &id3DataSize, NULL );
    
    if( err != noErr ) {
        NSLog( @"AudioFileGetPropertyInfo failed for ID3 tag" );
    }
    NSDictionary *piDict = nil;
    UInt32 piDataSize   = sizeof( piDict );
    err = AudioFileGetProperty( fileID, kAudioFilePropertyInfoDictionary, &piDataSize, &piDict );
    if( err != noErr ) {
        NSLog( @"AudioFileGetProperty failed for property info dictionary" );
    }
    CFDataRef AlbumPic= nil;
    UInt32 picDataSize = sizeof(picDataSize);
    err =AudioFileGetProperty( fileID,   kAudioFilePropertyAlbumArtwork, &picDataSize, &AlbumPic);
    if( err != noErr ) {
        //NSLog( @"Get picture failed" );
    }
    
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    
    NSString * Album = [(NSDictionary*)piDict objectForKey:
                        [NSString stringWithUTF8String: kAFInfoDictionary_Album]];
    NSString * Artist = [(NSDictionary*)piDict objectForKey:
                         [NSString stringWithUTF8String: kAFInfoDictionary_Artist]];
    NSString * Title = [(NSDictionary*)piDict objectForKey:
                        [NSString stringWithUTF8String: kAFInfoDictionary_Title]];
    NSString * timeStr = [(NSDictionary*)piDict objectForKey:
                          [NSString stringWithUTF8String: kAFInfoDictionary_ApproximateDurationInSeconds]];
    if (Title != nil && Title.length>0 && ![Title isEqualToString:@"null"]) {
        [dict setObject:Title forKey:MPMediaItemPropertyAlbumTitle];
    }
    if (Artist != nil && Artist.length>0 && ![Artist isEqualToString:@"null"]) {
        [dict setObject:Artist forKey:MPMediaItemPropertyArtist];
    }
    if (Album != nil && Album.length>0 && ![Album isEqualToString:@"null"]) {
        [dict setObject:Album forKey:MPMediaItemPropertyTitle];
    }
    if (timeStr != nil && timeStr.length>0 && ![timeStr isEqualToString:@"null"]) {
        [dict setObject:timeStr forKey:MPMediaItemPropertyPlaybackDuration];
    }
    
    AVURLAsset *avURLAsset = [AVURLAsset URLAssetWithURL:fileURL
                                                 options:nil];
    for (NSString *format in [avURLAsset availableMetadataFormats]) {
        for (AVMetadataItem *metadataItem in [avURLAsset metadataForFormat:format]) {
            if ([metadataItem.commonKey isEqualToString:@"artwork"]) {
                //取出封面artwork，从data转成image显示
                NSObject *value = metadataItem.value;
                NSData *data = nil;
                if ([value isKindOfClass:[NSData class]]) {
                    data = (NSData *)value;
                }else{
                    data = [((NSDictionary *)value) objectForKey:@"data"];
                
                }
                MPMediaItemArtwork *mArt = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageWithData:data]];
                [dict setObject:mArt
                         forKey:MPMediaItemPropertyArtwork];
                break;
            }
        }
    }

    return dict;

}

- (void)forwardItem
{
    //根据当前播放的是第几个，进行下一个播放
    _currentInt--;
    if (_currentInt < 0) {
        _currentInt = self.allNum-1;
    }
    
    //这个地方获取到了本地音频的地址，所以可以直接播放上一首
    NSDictionary *dic = self.musicArray[_currentInt];
    
    //播放上一首之前先停止，然后注销
    //[self.player stop];
    //self.player = nil;
    [self play:_musicArray clickMusicPath:dic];
    
}
- (void)nextItem
{
    //根据当前播放的是第几个，进行下一个播放
    _currentInt++;
    if (_currentInt > self.allNum-1) {
        _currentInt = 0;
    }
    
    //这个地方获取到了本地音频的地址，所以可以直接播放上一首
    NSDictionary *dic = self.musicArray[_currentInt];
    
    //播放上一首之前先停止，然后注销
    //[self.player stop];
    //self.player = nil;
    [self play:_musicArray clickMusicPath:dic];
}
- (void)play
{
    if (self.player.playing) {
        return;
    }
    [self.player play];
}
- (void)pause
{
    [self.player pause];
}

@end
