#import "Crossfader.h"
#import "vendor/MobileVLCKit.framework/Headers/MobileVLCKit.h"
#import <math.h>

static NSString * const kPrefsSuite = @"com.lovable.vlccrossfade";

@interface VLCCrossfader ()
@property (nonatomic, weak) VLCMediaPlayer *primaryPlayer;
@property (nonatomic, strong) VLCMediaPlayer *secondaryPlayer;
@property (nonatomic, strong) dispatch_source_t rampTimer;
@property (nonatomic, assign) BOOL crossfading;
@end

@implementation VLCCrossfader

+ (instancetype)shared {
    static VLCCrossfader *s;
    static dispatch_once_t o;
    dispatch_once(&o, ^{ s = [VLCCrossfader new]; });
    return s;
}

- (instancetype)init {
    if ((self = [super init])) {
        [self reloadPreferences];
    }
    return self;
}

- (void)reloadPreferences {
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:kPrefsSuite];
    NSNumber *en = [d objectForKey:@"Enabled"];
    self.enabled = en ? en.boolValue : YES;
    NSNumber *dur = [d objectForKey:@"Duration"];
    self.crossfadeDuration = dur ? MAX(1.0, MIN(12.0, dur.doubleValue)) : 6.0;
    NSNumber *pp = [d objectForKey:@"FadeOnPlayPause"];
    self.fadeOnPlayPause = pp ? pp.boolValue : YES;
    NSNumber *ppd = [d objectForKey:@"PlayPauseFadeDuration"];
    self.playPauseFadeDuration = ppd ? MAX(0.05, MIN(2.0, ppd.doubleValue)) : 0.4;
    NSString *curve = [d stringForKey:@"Curve"];
    self.curve = [curve isEqualToString:@"linear"] ? VLCCFCurveLinear : VLCCFCurveEqualPower;
}

- (void)attachToPlayer:(VLCMediaPlayer *)player {
    self.primaryPlayer = player;
}

- (BOOL)isCrossfadingForPlayer:(VLCMediaPlayer *)player {
    return self.crossfading && self.primaryPlayer == player;
}

#pragma mark - Volume curves

static float curveOut(float t, VLCCFCurve c) {
    // t in [0,1], returns gain for outgoing (1 -> 0)
    if (c == VLCCFCurveLinear) return 1.0f - t;
    return cosf(t * (float)M_PI_2);
}

static float curveIn(float t, VLCCFCurve c) {
    if (c == VLCCFCurveLinear) return t;
    return sinf(t * (float)M_PI_2);
}

- (void)setVolume:(int)vol onPlayer:(VLCMediaPlayer *)p {
    @try {
        p.audio.volume = vol;
    } @catch (__unused NSException *e) {}
}

#pragma mark - Fade in/out (play/pause)

- (void)fadeInPlayer:(VLCMediaPlayer *)player {
    if (!self.fadeOnPlayPause || !player) return;
    NSTimeInterval dur = self.playPauseFadeDuration;
    VLCCFCurve c = self.curve;
    __weak VLCMediaPlayer *wp = player;
    [self setVolume:0 onPlayer:player];
    [self rampFrom:0.0 to:1.0 duration:dur block:^(float t, BOOL done) {
        VLCMediaPlayer *sp = wp;
        if (!sp) return;
        [self setVolume:(int)(curveIn(t, c) * 100.0f) onPlayer:sp];
        if (done) [self setVolume:100 onPlayer:sp];
    }];
}

- (void)fadeOutPlayer:(VLCMediaPlayer *)player completion:(void(^)(void))completion {
    if (!self.fadeOnPlayPause || !player) { if (completion) completion(); return; }
    NSTimeInterval dur = self.playPauseFadeDuration;
    VLCCFCurve c = self.curve;
    __weak VLCMediaPlayer *wp = player;
    [self rampFrom:0.0 to:1.0 duration:dur block:^(float t, BOOL done) {
        VLCMediaPlayer *sp = wp;
        if (!sp) { if (done && completion) completion(); return; }
        [self setVolume:(int)(curveOut(t, c) * 100.0f) onPlayer:sp];
        if (done) {
            [self setVolume:0 onPlayer:sp];
            if (completion) completion();
        }
    }];
}

#pragma mark - Crossfade near end

- (void)tickForPlayer:(VLCMediaPlayer *)player {
    if (!self.enabled || self.crossfading || !player) return;
    VLCTime *rem = player.remainingTime;
    if (!rem || rem.value == nil) return;
    NSInteger remMs = ABS(rem.intValue); // remainingTime is negative
    NSInteger triggerMs = (NSInteger)(self.crossfadeDuration * 1000.0);
    if (remMs > 0 && remMs <= triggerMs) {
        [self startCrossfadeFromPlayer:player];
    }
}

- (void)startCrossfadeFromPlayer:(VLCMediaPlayer *)outgoing {
    // Resolve next media via VLCPlaybackService (hooked)
    Class PBS = NSClassFromString(@"VLCPlaybackService");
    id svc = [PBS respondsToSelector:@selector(sharedInstance)] ? [PBS performSelector:@selector(sharedInstance)] : nil;
    if (!svc) return;

    VLCMedia *nextMedia = nil;
    SEL nextSel = NSSelectorFromString(@"nextMedia");
    if ([svc respondsToSelector:nextSel]) {
        nextMedia = ((VLCMedia *(*)(id, SEL))objc_msgSend_stub)(svc, nextSel);
    }
    if (!nextMedia) return;

    self.crossfading = YES;
    VLCMediaPlayer *incoming = [[NSClassFromString(@"VLCMediaPlayer") alloc] init];
    incoming.media = nextMedia;
    [self setVolume:0 onPlayer:incoming];
    [incoming play];
    self.secondaryPlayer = incoming;

    NSTimeInterval dur = self.crossfadeDuration;
    VLCCFCurve c = self.curve;
    __weak VLCMediaPlayer *wOut = outgoing;
    __weak VLCMediaPlayer *wIn = incoming;
    __weak typeof(self) ws = self;

    [self rampFrom:0.0 to:1.0 duration:dur block:^(float t, BOOL done) {
        VLCMediaPlayer *o = wOut; VLCMediaPlayer *i = wIn;
        if (o) [ws setVolume:(int)(curveOut(t, c) * 100.0f) onPlayer:o];
        if (i) [ws setVolume:(int)(curveIn(t, c) * 100.0f) onPlayer:i];
        if (done) {
            if (o) { [o stop]; }
            // Swap: promote incoming to primary via VLCPlaybackService if possible
            Class PBS2 = NSClassFromString(@"VLCPlaybackService");
            id svc2 = [PBS2 respondsToSelector:@selector(sharedInstance)] ? [PBS2 performSelector:@selector(sharedInstance)] : nil;
            SEL advSel = NSSelectorFromString(@"next");
            if (svc2 && [svc2 respondsToSelector:advSel]) {
                // Let VLC advance its queue index; the newly started player becomes primary.
                ((void(*)(id, SEL))objc_msgSend_stub)(svc2, advSel);
            }
            ws.secondaryPlayer = nil;
            ws.crossfading = NO;
        }
    }];
}

#pragma mark - Ramp helper

- (void)rampFrom:(float)from to:(float)to duration:(NSTimeInterval)duration block:(void(^)(float t, BOOL done))block {
    if (duration <= 0) { block(1.0f, YES); return; }
    dispatch_queue_t q = dispatch_get_main_queue();
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);
    uint64_t interval = (uint64_t)(1.0 / 30.0 * NSEC_PER_SEC);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, interval, interval / 4);
    __block NSTimeInterval elapsed = 0;
    NSTimeInterval step = 1.0 / 30.0;
    dispatch_source_set_event_handler(timer, ^{
        elapsed += step;
        float t = MIN(1.0, (float)(elapsed / duration));
        BOOL done = t >= 1.0f;
        block(t, done);
        if (done) dispatch_source_cancel(timer);
    });
    dispatch_resume(timer);
}

@end

// objc_msgSend forwarding shim (avoid direct casted objc_msgSend under ARC strict)
id objc_msgSend_stub(id self, SEL _cmd, ...) {
    return ((id(*)(id, SEL))objc_msgSend)(self, _cmd);
}
