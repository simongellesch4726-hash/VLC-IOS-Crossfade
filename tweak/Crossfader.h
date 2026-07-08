#import <Foundation/Foundation.h>

@class VLCMediaPlayer;

typedef NS_ENUM(NSInteger, VLCCFCurve) {
    VLCCFCurveLinear = 0,
    VLCCFCurveEqualPower = 1,
};

@interface VLCCrossfader : NSObject

+ (instancetype)shared;

// Config (backed by NSUserDefaults suite com.lovable.vlccrossfade)
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) NSTimeInterval crossfadeDuration;      // seconds
@property (nonatomic, assign) NSTimeInterval playPauseFadeDuration;  // seconds
@property (nonatomic, assign) BOOL fadeOnPlayPause;
@property (nonatomic, assign) VLCCFCurve curve;

- (void)reloadPreferences;

// Called by hooks
- (void)attachToPlayer:(VLCMediaPlayer *)player;
- (void)tickForPlayer:(VLCMediaPlayer *)player;
- (void)fadeInPlayer:(VLCMediaPlayer *)player;
- (void)fadeOutPlayer:(VLCMediaPlayer *)player completion:(void(^)(void))completion;
- (BOOL)isCrossfadingForPlayer:(VLCMediaPlayer *)player;

@end
