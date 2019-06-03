//
//  ViewController.m
//  ContextMenuView
//
//  Created by 一路捞 on 2019/6/3.
//  Copyright © 2019 literature. All rights reserved.
//

#import "ViewController.h"
#import "JRContextMenuView.h"

@interface ViewController () <JRContextOverlayViewDelegate, JRContextOverlayViewDataSource>

@property (nonatomic, strong) NSArray *datas;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.datas = @[@"facebook-white",@"twitter-white",@"google-plus-white",@"linkedin-white",@"pinterest-white"];
    
    JRContextMenuView *overlay = [[JRContextMenuView alloc] init];
    overlay.dataSource = self;
    overlay.delegate = self;
    overlay.menuActionType = JRContextMenuActionTypeTap;
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:overlay action:@selector(addGestureRecognizerDetected:)]];
}

- (NSInteger)numberOfMenuItems {
    return self.datas.count;
}

- (UIImage *)imageForItemAtIndex:(NSInteger)index {
    
    return [UIImage imageNamed:self.datas[index]];
}

- (void)didSelectItemAtIndex:(NSInteger)selectedIndex forMenuAtPoint:(CGPoint)point {
    NSString* msg = nil;
    switch (selectedIndex) {
        case 0:
            msg = @"Facebook Selected";
            break;
        case 1:
            msg = @"Twitter Selected";
            break;
        case 2:
            msg = @"Google Plus Selected";
            break;
        case 3:
            msg = @"Linkedin Selected";
            break;
        case 4:
            msg = @"Pinterest Selected";
            break;
            
        default:
            break;
    }
    UIAlertController *aler = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [aler addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:aler animated:YES completion:nil];
}


@end
