//
//  JRContextMenuView.h
//  JRCenterMenuView
//
//  Created by 一路捞 on 2019/6/3.
//  Copyright © 2019 literature. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, JRContextMenuActionType) {
    JRContextMenuActionTypeTap,
    JRContextMenuActionTypePan,
};

@protocol JRContextOverlayViewDataSource <NSObject>

- (NSInteger)numberOfMenuItems;

- (UIImage *)imageForItemAtIndex:(NSInteger)index;

@optional
- (BOOL)shouldShowMenuAtPoint:(CGPoint)point;

@end

@protocol JRContextOverlayViewDelegate <NSObject>

- (void)didSelectItemAtIndex:(NSInteger)selectedIndex forMenuAtPoint:(CGPoint)point;

@end

@interface JRContextMenuView : UIView

@property (nonatomic, weak) id<JRContextOverlayViewDataSource> dataSource;

@property (nonatomic, weak) id<JRContextOverlayViewDelegate> delegate;

@property (nonatomic, assign) JRContextMenuActionType menuActionType;

- (void)addGestureRecognizerDetected:(UIGestureRecognizer *)gestureRecognizer;

@end

NS_ASSUME_NONNULL_END
