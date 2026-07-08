// Minimal public-header stub for MobileVLCKit.
// MobileVLCKit is LGPL, © VideoLAN and VLC authors. Full framework is
// dynamically linked at runtime from VLC.app; only declarations required
// for tweak compilation are reproduced here.

#import <Foundation/Foundation.h>
#import <objc/message.h>

@class VLCMedia, VLCAudio, VLCTime;

@interface VLCTime : NSObject
@property (nonatomic, readonly) NSNumber *value;
@property (nonatomic, readonly) int intValue;
@property (nonatomic, readonly) NSString *stringValue;
@end

@interface VLCAudio : NSObject
@property (nonatomic) int volume;
@property (nonatomic, getter=isMuted) BOOL muted;
@end

@interface VLCMedia : NSObject
+ (instancetype)mediaWithURL:(NSURL *)url;
@end

@interface VLCMediaPlayer : NSObject
- (instancetype)init;
@property (nonatomic, strong) VLCMedia *media;
@property (nonatomic, readonly) VLCAudio *audio;
@property (nonatomic, readonly) VLCTime *time;
@property (nonatomic, readonly) VLCTime *remainingTime;
@property (nonatomic, readonly) BOOL isPlaying;
- (void)play;
- (void)pause;
- (void)stop;
@end

// Forwarding shim used by the tweak.
id objc_msgSend_stub(id self, SEL _cmd, ...);
