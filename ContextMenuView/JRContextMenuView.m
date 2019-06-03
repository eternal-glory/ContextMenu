//
//  JRContextMenuView.m
//  JRCenterMenuView
//
//  Created by 一路捞 on 2019/6/3.
//  Copyright © 2019 literature. All rights reserved.
//

#import "JRContextMenuView.h"

#define JRShowAnimationID @"JRContextMenuViewRriseAnimationID"
#define JRDismissAnimationID @"JRContextMenuViewDismissAnimationID"

NSInteger const JRMainItemSize = 44;
NSInteger const JRMenuItemSize = 40;
NSInteger const JRBorderWidth  = 5;

CGFloat const   JRAnimationDuration = 0.2;
CGFloat const   JRAnimationDelay = JRAnimationDuration / 5;

@interface JRMenuItemLocation : NSObject

@property (nonatomic, assign) CGPoint position;

@property (nonatomic, assign) CGFloat angle;

@end

@implementation JRMenuItemLocation

@end

@interface JRContextMenuView () <UIGestureRecognizerDelegate, CAAnimationDelegate>
{
    CADisplayLink *_displayLink;
}

@property (nonatomic, assign) BOOL isShowing;

@property (nonatomic, assign) BOOL isPaning;

@property (nonatomic, assign) CGPoint recognizerLocation;

@property (nonatomic, assign) CGPoint curretnLocation;

@property (nonatomic, strong) NSMutableArray *menuItems;

@property (nonatomic, assign) CGFloat radius;

@property (nonatomic, assign) CGFloat arcAngle;

@property (nonatomic, assign) CGFloat angleBetweenItems;

@property (nonatomic, strong) NSMutableArray *itemLocations;

@property (nonatomic, assign) NSInteger prevIndex;

@property (nonatomic, assign) CGColorRef itemBGHighlightedColor;

@property (nonatomic, assign) CGColorRef itemBGColor;

@end

@implementation JRContextMenuView

- (instancetype)init {
    if (self = [super init]) {
        self.frame = UIScreen.mainScreen.bounds;
        self.backgroundColor  = [UIColor clearColor];
        _menuActionType = JRContextMenuActionTypePan;
        _displayLink = [CADisplayLink displayLinkWithTarget:self
                                                  selector:@selector(highlightMenuItemForPoint)];
        
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        self.itemLocations = [NSMutableArray array];
        self.menuItems = [NSMutableArray array];
        
        self.arcAngle = M_PI_2;
        self.radius = 90;
        self.itemBGColor = [UIColor grayColor].CGColor;
        self.itemBGHighlightedColor = [UIColor greenColor].CGColor;
        
    }
    return self;
}

- (void)addGestureRecognizerDetected:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded && self.menuActionType == JRContextMenuActionTypeTap) {
        [self showMenu:gestureRecognizer];
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.prevIndex = -1;
        CGPoint pointInView = [gestureRecognizer locationInView:gestureRecognizer.view];
        if (self.dataSource != nil && [self.dataSource respondsToSelector:@selector(shouldShowMenuAtPoint:)] && ![self.dataSource shouldShowMenuAtPoint:pointInView]){
            return;
        }
        [self showMenu:gestureRecognizer];
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        if (self.isShowing && self.menuActionType == JRContextMenuActionTypePan) {
            self.isPaning = YES;
            self.curretnLocation =  [gestureRecognizer locationInView:self];
        }
    }
    
    if( gestureRecognizer.state == UIGestureRecognizerStateEnded && self.menuActionType == JRContextMenuActionTypePan) {
        CGPoint menuAtPoint = [self convertPoint:self.recognizerLocation toView:gestureRecognizer.view];
        [self dismissWithSelectedIndexForMenuAtPoint:menuAtPoint];
    }
}

- (void)highlightMenuItemForPoint {
    if (self.isShowing && self.isPaning) {
        CGFloat angle = [self angleBeweenStartinPoint:self.recognizerLocation endingPoint:self.curretnLocation];
        NSInteger closeToIndex = -1;
        for (int i = 0; i < self.menuItems.count; i++) {
            JRMenuItemLocation *itemLocation = [self.itemLocations objectAtIndex:i];
            if (fabs(itemLocation.angle - angle) < self.angleBetweenItems/2) {
                closeToIndex = i;
                break;
            }
        }
        
        if (closeToIndex >= 0 && closeToIndex < self.menuItems.count) {
            
            JRMenuItemLocation *itemLocation = [self.itemLocations objectAtIndex:closeToIndex];
            
            CGFloat distanceFromCenter = sqrt(pow(self.curretnLocation.x - self.recognizerLocation.x, 2)+ pow(self.curretnLocation.y-self.recognizerLocation.y, 2));
            
            CGFloat toleranceDistance = (self.radius - JRMainItemSize/(2*sqrt(2)) - JRMenuItemSize/(2*sqrt(2)) )/2;
            
            CGFloat distanceFromItem = fabs(distanceFromCenter - self.radius) - JRMenuItemSize/(2*sqrt(2)) ;
            
            if (fabs(distanceFromItem) < toleranceDistance ) {
                CALayer *layer = [self.menuItems objectAtIndex:closeToIndex];
                layer.backgroundColor = self.itemBGHighlightedColor;
                
                CGFloat distanceFromItemBorder = fabs(distanceFromItem);
                
                CGFloat scaleFactor = 1 + 0.5 *(1-distanceFromItemBorder/toleranceDistance) ;
                
                if (scaleFactor < 1.0) {
                    scaleFactor = 1.0;
                }
                
                // Scale
                CATransform3D scaleTransForm =  CATransform3DScale(CATransform3DIdentity, scaleFactor, scaleFactor, 1.0);
                
                CGFloat xtrans = cosf(itemLocation.angle);
                CGFloat ytrans = sinf(itemLocation.angle);
                
                CATransform3D transLate = CATransform3DTranslate(scaleTransForm, 10*scaleFactor*xtrans, 10*scaleFactor*ytrans, 0);
                layer.transform = transLate;
                
                if ( ( self.prevIndex >= 0 && self.prevIndex != closeToIndex)) {
                    [self resetPreviousSelection];
                }
                
                self.prevIndex = closeToIndex;
                
            } else if (self.prevIndex >= 0) {
                [self resetPreviousSelection];
            }
        } else {
            [self resetPreviousSelection];
        }
    }
}

#pragma mark - - - - TouchesBegan
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint menuAtPoint = CGPointZero;
    if ([touches count] == 1) {
        UITouch *touch = (UITouch *)[touches anyObject];
        CGPoint touchPoint = [touch locationInView:self];
        NSInteger menuItemIndex = [self indexOfClosestMatchAtPoint:touchPoint];
        if(menuItemIndex > -1) {
            menuAtPoint = [self.menuItems[menuItemIndex] position];
        }
        
        if((self.prevIndex >= 0 && self.prevIndex != menuItemIndex)) {
            [self resetPreviousSelection];
        }
        self.prevIndex = menuItemIndex;
    }
    
    [self dismissWithSelectedIndexForMenuAtPoint: menuAtPoint];
}

#pragma mark - - - 触发视图事件
- (void)dismissWithSelectedIndexForMenuAtPoint:(CGPoint)point {
    
    if([self.delegate respondsToSelector:@selector(didSelectItemAtIndex: forMenuAtPoint:)] && self.prevIndex >= 0){
        [self.delegate didSelectItemAtIndex:self.prevIndex forMenuAtPoint:point];
        self.prevIndex = -1;
    }
    [self hideMenu];
}

#pragma mark - - - 显示视图
- (void)showMenu:(UIGestureRecognizer *)gestureRecognizer {
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    self.recognizerLocation = [gestureRecognizer locationInView:self];
    
    self.layer.backgroundColor = [UIColor colorWithWhite:0.1f alpha:.8f].CGColor;
    self.isShowing = YES;
    [self animateMenu:YES];
    [self setNeedsDisplay];
}

#pragma mark - - - 销毁视图
- (void)hideMenu {
    if (self.isShowing) {
        self.layer.backgroundColor = [UIColor clearColor].CGColor;
        self.isShowing = NO;
        self.isPaning = NO;
        [self animateMenu:NO];
        [self setNeedsDisplay];
        [self removeFromSuperview];
    }
}

#pragma mark - - - 加载数据

- (void)setDataSource:(id<JRContextOverlayViewDataSource>)dataSource {
    _dataSource = dataSource;
    [self reloadData];
}

- (void)reloadData {
    [self.menuItems removeAllObjects];
    [self.itemLocations removeAllObjects];
    
    if (self.dataSource != nil) {
        NSInteger count = [self.dataSource numberOfMenuItems];
        for (int i = 0; i < count; i++) {
            UIImage *image = [self.dataSource imageForItemAtIndex:i];
            CALayer *layer = [self layerWithImage:image];
            [self.layer addSublayer:layer];
            [self.menuItems addObject:layer];
        }
    }
}

#pragma mark - - - 私有方法
- (CALayer *)layerWithImage:(UIImage *)image {
    CALayer *layer = [CALayer layer];
    layer.bounds = CGRectMake(0, 0, JRMenuItemSize, JRMenuItemSize);
    layer.cornerRadius = JRMenuItemSize/2;
    layer.borderColor = [UIColor whiteColor].CGColor;
    layer.borderWidth = JRBorderWidth;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeMake(0, -1);
    layer.backgroundColor = self.itemBGColor;
    
    CALayer* imageLayer = [CALayer layer];
    imageLayer.contents = (id) image.CGImage;
    imageLayer.bounds = CGRectMake(0, 0, JRMenuItemSize*2/3, JRMenuItemSize*2/3);
    imageLayer.position = CGPointMake(JRMenuItemSize/2, JRMenuItemSize/2);
    [layer addSublayer:imageLayer];
    return layer;
}

- (void)layoutMenuItems {
    [self.itemLocations removeAllObjects];
    
    CGSize itemSize = CGSizeMake(JRMenuItemSize, JRMenuItemSize);
    CGFloat itemRadius = sqrt(pow(itemSize.width, 2) + pow(itemSize.height, 2)) / 2;
    self.arcAngle = ((itemRadius * self.menuItems.count) / self.radius) * 1.5;
    
    NSUInteger count = self.menuItems.count;
    BOOL isFullCircle = (self.arcAngle == M_PI*2);
    NSUInteger divisor = (isFullCircle) ? count : count - 1;
    
    self.angleBetweenItems = self.arcAngle/divisor;
    
    for (int i = 0; i < self.menuItems.count; i++) {
        JRMenuItemLocation *location = [self locationForItemAtIndex:i];
        [self.itemLocations addObject:location];
        CALayer* layer = (CALayer*) [self.menuItems objectAtIndex:i];
        layer.transform = CATransform3DIdentity;
        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            CGFloat angle = [UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft ? M_PI_2 : -M_PI_2;
            layer.transform = CATransform3DRotate(CATransform3DIdentity, angle, 0, 0, 1);
        }
    }
}

- (JRMenuItemLocation *)locationForItemAtIndex:(NSUInteger)index {
    CGFloat itemAngle = [self itemAngleAtIndex:index];
    
    CGPoint itemCenter = CGPointMake(self.recognizerLocation.x + cosf(itemAngle) * self.radius,
                                     self.recognizerLocation.y + sinf(itemAngle) * self.radius);
    JRMenuItemLocation *location = [[JRMenuItemLocation alloc] init];
    location.position = itemCenter;
    location.angle = itemAngle;
    
    return location;
}

- (CGFloat)itemAngleAtIndex:(NSUInteger)index {
    float bearingRadians = [self angleBeweenStartinPoint:self.recognizerLocation endingPoint:self.center];
    
    CGFloat angle =  bearingRadians - self.arcAngle/2;
    
    CGFloat itemAngle = angle + (index * self.angleBetweenItems);
    
    if (itemAngle > 2 * M_PI) {
        itemAngle -= 2 * M_PI;
    } else if (itemAngle < 0) {
        itemAngle += 2 * M_PI;
    }
    return itemAngle;
}

- (NSInteger)indexOfClosestMatchAtPoint:(CGPoint)point {
    int i = 0;
    for(CALayer *menuItemLayer in self.menuItems) {
        if(CGRectContainsPoint(menuItemLayer.frame, point)) {
            NSLog( @"Touched Layer at index: %i", i);
            return i;
        }
        i++;
    }
    return -1;
}

- (CGFloat)angleBeweenStartinPoint:(CGPoint)startingPoint endingPoint:(CGPoint)endingPoint {
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y);
    float bearingRadians = atan2f(originPoint.y, originPoint.x);
    bearingRadians = (bearingRadians > 0.0 ? bearingRadians : (M_PI*2 + bearingRadians));
    return bearingRadians;
}

- (void)resetPreviousSelection {
    if (self.prevIndex >= 0) {
        CALayer *layer = self.menuItems[self.prevIndex];
        JRMenuItemLocation* itemLocation = [self.itemLocations objectAtIndex:self.prevIndex];
        layer.position = itemLocation.position;
        layer.backgroundColor = self.itemBGColor;
        layer.transform = CATransform3DIdentity;
        self.prevIndex = -1;
    }
}

- (void)animateMenu:(BOOL)isShowing {
    if (isShowing) {
        [self layoutMenuItems];
    }
    
    for (NSUInteger index = 0; index < self.menuItems.count; index++) {
        CALayer *layer = self.menuItems[index];
        layer.opacity = 0;
        CGPoint fromPosition = self.recognizerLocation;
        
        JRMenuItemLocation* location = [self.itemLocations objectAtIndex:index];
        CGPoint toPosition = location.position;
        
        double delayInSeconds = index * JRAnimationDelay;
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithCGPoint:isShowing ? fromPosition : toPosition];
        positionAnimation.toValue = [NSValue valueWithCGPoint:isShowing ? toPosition : fromPosition];
        positionAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.45f :1.2f :0.75f :1.0f];
        positionAnimation.duration = JRAnimationDuration;
        positionAnimation.beginTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil] + delayInSeconds;
        [positionAnimation setValue:[NSNumber numberWithUnsignedInteger:index] forKey:isShowing ? JRShowAnimationID : JRDismissAnimationID];
        positionAnimation.delegate = (id)self;
        [layer addAnimation:positionAnimation forKey:@"riseAnimation"];
    }
}

- (void)animationDidStart:(CAAnimation *)anim {
    if([anim valueForKey:JRShowAnimationID]) {
        NSUInteger index = [[anim valueForKey:JRShowAnimationID] unsignedIntegerValue];
        CALayer *layer = self.menuItems[index];
        JRMenuItemLocation* location = [self.itemLocations objectAtIndex:index];
        CGFloat toAlpha = 1.0;
        layer.position = location.position;
        layer.opacity = toAlpha;
        
    } else if([anim valueForKey:JRDismissAnimationID]) {
        NSUInteger index = [[anim valueForKey:JRDismissAnimationID] unsignedIntegerValue];
        CALayer *layer = self.menuItems[index];
        CGPoint toPosition = self.recognizerLocation;
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        layer.position = toPosition;
        layer.backgroundColor = self.itemBGColor;
        layer.opacity = 0.0f;
        layer.transform = CATransform3DIdentity;
        [CATransaction commit];
    }
}

- (void)drawCircle:(CGPoint)locationOfTouch {
    CGContextRef ctx= UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextSetLineWidth(ctx, JRBorderWidth/2);
    CGContextSetRGBStrokeColor(ctx, 0.8, 0.8, 0.8, 1.0);
    CGContextAddArc(ctx, locationOfTouch.x, locationOfTouch.y, JRMainItemSize/2, 0.0, M_PI*2, YES);
    CGContextStrokePath(ctx);
}

- (void)drawRect:(CGRect)rect {
    if (self.isShowing) {
        [self drawCircle:self.recognizerLocation];
    }
}
@end
