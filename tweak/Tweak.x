#import "Crossfader.h"
#import "vendor/MobileVLCKit.framework/Headers/MobileVLCKit.h"
#import <UIKit/UIKit.h>

@interface VLCPlaybackService : NSObject
+ (instancetype)sharedInstance;
- (void)play;
- (void)pause;
- (void)stopPlayback;
- (void)next;
- (void)previous;
- (id)mediaPlayer;
@end

static NSTimer *gTickTimer = nil;

static void startTicker(VLCMediaPlayer *player) {
    if (gTickTimer) { [gTickTimer invalidate]; gTickTimer = nil; }
    __weak VLCMediaPlayer *wp = player;
    gTickTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *t) {
        VLCMediaPlayer *sp = wp;
        if (!sp) { [t invalidate]; return; }
        [[VLCCrossfader shared] tickForPlayer:sp];
    }];
}

static void stopTicker(void) {
    if (gTickTimer) { [gTickTimer invalidate]; gTickTimer = nil; }
}

%hook VLCPlaybackService

- (void)play {
    %orig;
    VLCMediaPlayer *p = [self mediaPlayer];
    [[VLCCrossfader shared] attachToPlayer:p];
    [[VLCCrossfader shared] fadeInPlayer:p];
    startTicker(p);
}

- (void)pause {
    VLCMediaPlayer *p = [self mediaPlayer];
    if (!p) { %orig; return; }
    [[VLCCrossfader shared] fadeOutPlayer:p completion:^{
        %orig;
    }];
}

- (void)stopPlayback {
    stopTicker();
    VLCMediaPlayer *p = [self mediaPlayer];
    if (!p) { %orig; return; }
    [[VLCCrossfader shared] fadeOutPlayer:p completion:^{
        %orig;
    }];
}

%end

%ctor {
    [[VLCCrossfader shared] reloadPreferences];
    // Reload prefs when the pane writes them.
    [[NSNotificationCenter defaultCenter] addObserverForName:@"com.lovable.vlccrossfade/prefsChanged"
                                                      object:nil queue:nil usingBlock:^(NSNotification *n) {
        [[VLCCrossfader shared] reloadPreferences];
    }];
}
