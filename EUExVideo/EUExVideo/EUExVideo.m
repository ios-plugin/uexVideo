//
//  EUExVideoMgr.m
//  webKitCorePalm
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExVideo.h"

#import "JSON.h"
#import "EUExBaseDefine.h"
#import "uexVideoRecorder.h"
#import "uexVideoMediaPlayer.h"
@interface EUExVideo()
@property (nonatomic,strong)uexVideoRecorder *recorder;
@property (nonatomic,strong)uexVideoMediaPlayer *player;
@end


#define UEX_VIDEO_KEY_TO_NSSTRING(x) ([NSString stringWithCString:#x encoding:NSUTF8StringEncoding])
#define UEX_VIDEO_GET_BOOLEAN_VALUE(dict,key,defaultValue) \
    BOOL key = info[UEX_VIDEO_KEY_TO_NSSTRING(key)] ? [info[UEX_VIDEO_KEY_TO_NSSTRING(key)] boolValue] : defaultValue;

#define UEX_VIDEO_GET_FLOAT_VALUE(dict,key,defaultValue) \
    CGFloat key = info[UEX_VIDEO_KEY_TO_NSSTRING(key)] ? [info[UEX_VIDEO_KEY_TO_NSSTRING(key)] floatValue] : defaultValue;


@implementation EUExVideo

-(id)initWithBrwView:(EBrowserView *) eInBrwView{
	if (self = [super initWithBrwView:eInBrwView]) {
	}
    
	return self;
}

-(void)dealloc{
    [self clean];
}

-(void)open:(NSMutableArray *)inArguments {
    if (inArguments.count == 0) {
        [self jsFailedWithOpId:0 errorCode:1210101 errorDes:UEX_ERROR_DESCRIBE_ARGS];
        return;
    }
    NSString *inPath = [inArguments objectAtIndex:0];
    if (inPath) {
        mPlayerObj = [[MediaPlayer alloc] init];
        [mPlayerObj initWithEuex:self];
        NSString *absPath = [super absPath:inPath];
        [mPlayerObj open:absPath];
    }else {
        [self jsFailedWithOpId:0 errorCode:1210101 errorDes:UEX_ERROR_DESCRIBE_ARGS];
    }
}


- (void)openPlayer:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return;
    }
    id info = [inArguments[0] JSONValue];
    if(!info || ![info isKindOfClass:[NSDictionary class]]){
        return;
    }
    if (!info[@"src"] || ![info[@"src"] isKindOfClass:[NSString class]]) {
        return;
    }
    NSString *path = info[@"src"];
    UEX_VIDEO_GET_FLOAT_VALUE(info, startTime, 0);
    UEX_VIDEO_GET_BOOLEAN_VALUE(info,autoStart,NO);
    UEX_VIDEO_GET_BOOLEAN_VALUE(info,forceFullScreen,NO);
    UEX_VIDEO_GET_BOOLEAN_VALUE(info,showCloseButton,NO);
    UEX_VIDEO_GET_BOOLEAN_VALUE(info,showScaleButton,NO);
    UEX_VIDEO_GET_FLOAT_VALUE(info, width,SCREEN_W);
    UEX_VIDEO_GET_FLOAT_VALUE(info, height,SCREEN_H);
    UEX_VIDEO_GET_FLOAT_VALUE(info, x,0);
    UEX_VIDEO_GET_FLOAT_VALUE(info, y,0);
    UEX_VIDEO_GET_BOOLEAN_VALUE(info,scrollWithWeb,NO);
    self.player = [[uexVideoMediaPlayer alloc]initWithEUExVideo:self];

    self.player.autoStart = autoStart;
    self.player.forceFullScreen = forceFullScreen;
    self.player.isScrollWithWeb = scrollWithWeb;
    self.player.showCloseButton = showCloseButton;
    self.player.showScaleButton = showScaleButton;
    [self.player openWithFrame:CGRectMake(x, y, width, height) path:path startTime:startTime];
}


- (void)closePlayer:(NSMutableArray *)inArguments{
    if (self.player) {
        [self.player close];
        self.player = nil;
    }
}


-(void)record:(NSMutableArray *)inArguments {
    uexVideoRecorder *recorder = [[uexVideoRecorder alloc]initWithEUExVideo:self];
    if(inArguments.count>0){
        id info = [inArguments[0] JSONValue];
        if(info[@"maxDuration"]){
            recorder.maxDuration = [info[@"maxDuration"] floatValue];
        }
        if(info[@"qualityType"]){
            recorder.resolution =[info[@"qualityType"] integerValue];
        }
        if(info[@"bitRateType"]){
            recorder.bitRateLevel =[info[@"bitRateType"] integerValue];
        }
        if(info[@"fileType"] && [info[@"fileType"] isKindOfClass:[NSString class]]){
            if ([[info[@"fileType"] lowercaseString] isEqual:@"mov"]) {
                recorder.fileType = uexVideoRecorderOutputFileTypeMOV;
            }
        }
    }
    self.recorder = recorder;
    [recorder statRecord];
    
    //[rVideoObj openVideoRecord:maxDuration qualityType:qualityType compressRatio:compressRatio fileType:fileType];
}
-(void)uexVideoWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData{
	if (inData) {
        NSString *cbStr=[NSString stringWithFormat:@"if(uexVideo.cbRecord != null){uexVideo.cbRecord(%d,%d,'%@');}",inOpId,inDataType,inData];
        [EUtility brwView:meBrwView evaluateScript:cbStr];
	}
}

- (void)callbackJSONWithName:(NSString *)name object:(id)obj{
    NSString *result = @"";
    NSString *cbStr =@"";
    if ([obj isKindOfClass:[NSNumber class]]) {
        cbStr = [NSString stringWithFormat:@"if(uexVideo.%@){uexVideo.%@(%@);}",name,name,obj];
        [EUtility brwView:meBrwView evaluateScript:cbStr];
        return;
    }
    
    if ([obj isKindOfClass:[NSString class]]) {
        result = obj;
    }else{
        result = [obj JSONFragment];
    }
    cbStr = [NSString stringWithFormat:@"if(uexVideo.%@){uexVideo.%@('%@');}",name,name,result];
    [EUtility brwView:meBrwView evaluateScript:cbStr];
}


-(void)clean{
    if (mPlayerObj) {
		mPlayerObj = nil;
	}
    if (self.recorder) {
        self.recorder = nil;
    }
    if (self.player) {
        [self.player close];
        self.player = nil;
    }
    
}

@end
