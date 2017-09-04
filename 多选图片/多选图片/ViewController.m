//
//  ViewController.m
//  滑动视图练习
//
//  Created by hglMac on 15-5-15.
//  Copyright (c) 2015年 mac. All rights reserved.
//


#import "ViewController.h"
#import "ZYQAssetPickerController.h"
#import "UIImage+ImageSimple.h"

@interface ViewController ()<UIScrollViewDelegate,UINavigationControllerDelegate,ZYQAssetPickerControllerDelegate,UIImagePickerControllerDelegate>
{
    UIScrollView *_bigScrollView;
    UIPageControl* _pageControl;
    NSTimer *_timer;
    UIAlertController *_alertController;
    
    NSMutableArray *_bigArray;//大数组
    NSMutableArray *_camearAry;//照相所获得照片的数组
    NSMutableArray *_picsAry;//相册所获得图片的数组
    
    NSMutableArray *_totalImgsAry;//照相拍摄和从相册选取图片的总和
    
    NSInteger imgCounts;
    
    UIButton *addBtn;//第一次初始化时，add按钮
    UIButton *_deletaBtn;//删除按钮
    UIButton *haddBtn;
    UIButton *addImagsBtn;
    
    NSInteger seletcTag;
    NSMutableArray *delBtnsAry;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"多选图片";
    //默认封面id
    seletcTag=10;
    
    _bigArray = [NSMutableArray array];
    _totalImgsAry = [NSMutableArray array];
    [self initUI];
}

-(void)initUI
{
    _bigScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 64, WIDTH, HEIGHT/2-100)];
    _bigScrollView.showsHorizontalScrollIndicator = NO;
    _bigScrollView.bounces = NO;
    _bigScrollView.delegate = self;
    _bigScrollView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:_bigScrollView];
    
    _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 0, WIDTH, 30)] ;
    _pageControl.center = CGPointMake(_bigScrollView.center.x, HEIGHT/2-60);
    _pageControl.currentPage = 0;
    _pageControl.pageIndicatorTintColor = [UIColor blueColor];
    _pageControl.currentPageIndicatorTintColor =[UIColor redColor];
    [self.view addSubview:_pageControl];
    [_pageControl addTarget:self action:@selector(pageControllerClick) forControlEvents:UIControlEventValueChanged];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
    
    addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.frame = CGRectMake(INTERVAL_WIDHT, _bigScrollView.frame.size.height+108, ADD_WIDTH, ADD_HEIGHT);
    addBtn.backgroundColor = RGB(87, 205, 66);
    [addBtn setImage:[UIImage imageNamed:@"ico_camera_increase"] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(imageBtn_click) forControlEvents:UIControlEventTouchUpInside];
    addBtn.adjustsImageWhenHighlighted = NO;
    [self.view addSubview:addBtn];
    
    
    _alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *cameralAction = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        //进入相机
        /*
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        imagePicker.allowsEditing = NO;
        [self presentViewController:imagePicker animated:YES completion:nil];
         */
    }];
    UIAlertAction *photoslAction = [UIAlertAction actionWithTitle:@"从相册选取" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        /**
         这里对上传张数进行控制，例如总张数是9张，然后第一次选择了3张相册照片，1张拍摄照片，再次进行选择时候对剩余还能选择照片的提醒和控制
         **/
        ZYQAssetPickerController *picker = [[ZYQAssetPickerController alloc] init];

        NSInteger imgNumber = _totalImgsAry.count;
       
        if (_totalImgsAry.count == 0) {
            picker.maximumNumberOfSelection = 9;
            SHOWALERT(@"你可以上传9张图片")
        }else
        {
            picker.maximumNumberOfSelection = 9-imgNumber;
            NSString *numberStr = [NSString stringWithFormat:@"还可以上传%ld张照片",9-imgNumber];
            SHOWALERT(numberStr)
        }

        //进入相册
        picker.assetsFilter = [ALAssetsFilter allPhotos];
        picker.showEmptyGroups=NO;
        picker.delegate=self;
        picker.selectionFilter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            if ([[(ALAsset*)evaluatedObject valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo]) {
                NSTimeInterval duration = [[(ALAsset*)evaluatedObject valueForProperty:ALAssetPropertyDuration] doubleValue];
                return duration >= 5;
            } else {
                return YES;
            }
        }];
        [self presentViewController:picker animated:YES completion:nil];
        
    }];
    
    [_alertController addAction:cancelAction];
    [_alertController addAction:cameralAction];
    [_alertController addAction:photoslAction];
}

//图片展示的方法
-(void)setUpdataImage:(NSMutableArray *)totalArray
{
    for (UIButton *adBtn in self.view.subviews) {
        if ([adBtn isKindOfClass:[UIButton class]]) {
            [adBtn removeFromSuperview];
        }
    }
    
    NSLog(@"---%lu",(unsigned long)totalArray.count);
    if (totalArray.count == 0) {
        addBtn.hidden = NO;
    }else
    {
        /**
         这里是把选取的照片，放到一个scrollview上展示
         **/
        _bigScrollView.contentSize = CGSizeMake(WIDTH *totalArray.count, 0);
        _pageControl.numberOfPages = totalArray.count;
        
        for (int i = 0; i<totalArray.count; i++) {
            
            UIImageView *imgview=[[UIImageView alloc] initWithFrame:CGRectMake(i*_bigScrollView.frame.size.width, 0, _bigScrollView.frame.size.width, _bigScrollView.frame.size.height)];
            imgview.contentMode=UIViewContentModeScaleAspectFill;
            imgview.clipsToBounds=YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                imgview.image = totalArray[i];
                [_bigScrollView addSubview:imgview];
            });
        }
        
        /**
         这里是把选取的照片展示到一个九宫格里面，类似于项目中上传图片的模块，还可以对图片进行标记
         **/
        NSInteger totalloc =  totalArray.count;//行数
        NSInteger coloc = 3;//列数
        CGFloat margin = (WIDTH - coloc*ADD_WIDTH)/4;//间隔
        
        if (totalArray.count >9) {
            SHOWALERT(@"只能上传9张图片")
        }else
        {
            for (int j = 0; j< totalloc; j++) {
                int row = j/coloc;
                int loc = j%coloc;
                
                CGFloat appViewx = margin +(margin +ADD_WIDTH)*loc;
                CGFloat appViewy = margin +(margin +ADD_HEIGHT)*row;
                
                //用来展示上传照片的按钮
                haddBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                haddBtn.frame =CGRectMake(appViewx,appViewy+ _bigScrollView.frame.size.height+80, ADD_WIDTH, ADD_HEIGHT);
                haddBtn.tag = j+1;
                [haddBtn setImage:totalArray[j] forState:UIControlStateNormal];
                [haddBtn addTarget:self action:@selector(addBg_imgClick:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:haddBtn];
                haddBtn.backgroundColor = [UIColor clearColor];
                haddBtn.userInteractionEnabled = YES;
                
                //删除按钮
                _deletaBtn = [[UIButton alloc]init];
                _deletaBtn=[UIButton buttonWithType:UIButtonTypeCustom];
                _deletaBtn.frame = CGRectMake(appViewx+(ADD_WIDTH - 20/2), appViewy+_bigScrollView.frame.size.height+80-20/2, 20, 20);
                [_deletaBtn setImage:[UIImage imageNamed:@"send_pic_del"] forState:UIControlStateNormal];
                _deletaBtn.tag = haddBtn.tag;
                [_deletaBtn addTarget:self action:@selector(hdeleteBtn_click:) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:_deletaBtn];
                
            }
            
            //算好坐标，在每次上传的照片总数后面（不够3张图片的情况下）初始化一个上传的按钮，绑定和初始view是创建的add按钮同一个方法
            addImagsBtn = [[UIButton alloc]init];
            addImagsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            NSInteger f = totalloc;
            addImagsBtn.tag = haddBtn.tag;
            NSInteger a = INTERVAL_WIDHT + f%3*70 +f%3*INTERVAL_WIDHT;
            NSInteger b = INTERVAL_WIDHT + f/3*70 +f/3*INTERVAL_WIDHT;
            addImagsBtn.frame = CGRectMake(a, b+_bigScrollView.frame.size.height + 80, ADD_WIDTH, ADD_HEIGHT);
            [addImagsBtn setBackgroundImage:[UIImage imageNamed:@"ico_camera_increase"] forState:UIControlStateNormal];
            [addImagsBtn addTarget: self action:@selector(imageBtn_click) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:addImagsBtn];
            
            if (totalArray.count == 0) {
                
                addImagsBtn.hidden = NO;
                self.view.backgroundColor = [UIColor redColor];
                
            }else if (totalArray.count == 9) {
                
                addImagsBtn.hidden = YES;
            }
        }
        
        
       //上传功能的话，直接在这里写就行
    }
    
}

-(void)addBg_imgClick:(id)sender
{
    NSLog(@"---==-=-%ld",(long)seletcTag);
}

#pragma mark 删除图片
- (void)hdeleteBtn_click:(id)sender
{
    UIButton *delBtn = (UIButton *)sender;
    
    delBtnsAry = _totalImgsAry;
    
    delBtn.hidden = YES;
    
    haddBtn.hidden = YES;
    
    [delBtnsAry removeObjectAtIndex:delBtn.tag - 1];
    
    _totalImgsAry = [[NSMutableArray alloc]initWithArray:delBtnsAry];
    
    //隐藏
    UILabel *selectlabel = (UILabel *)[self.view viewWithTag:seletcTag];
    selectlabel.hidden=YES;
    if (seletcTag==delBtn.tag-1+10)//如果删除是选中的 ，默认选为第一个
    {
        seletcTag=10;
    }
    if (delBtn.tag-1+10<seletcTag)//如果删除的tag小于选中的tag，选中的tag减1
    {
        seletcTag=seletcTag-1;
    }
    SHOWALERT(@"删除成功")
    
    [self setUpdataImage:delBtnsAry];
}

-(void)imageBtn_click
{
    [self presentViewController:_alertController animated:YES completion:nil];
}

-(void)pageControllerClick
{
    [_bigScrollView setContentOffset:CGPointMake(_pageControl.currentPage*WIDTH, 0) animated:YES];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_timer setFireDate:[NSDate distantFuture]];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    _pageControl.currentPage = _bigScrollView.contentOffset.x/self.view.bounds.size.width;
    [self performSelector:@selector(disPast) withObject:nil afterDelay:2];
    
}
-(void)disPast
{
    [_timer setFireDate:[NSDate distantPast]];
}
static int count=1;
-(void)onTimer
{
    _pageControl.currentPage+=count;
    if (_pageControl.currentPage==_pageControl.numberOfPages-1||_pageControl.currentPage==0)count=-count;
    [_bigScrollView setContentOffset:CGPointMake(_pageControl.currentPage*WIDTH, 0) animated:YES];
    
}

#pragma mark 照相进入这里
-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    _camearAry = [NSMutableArray array];
    [_bigArray removeAllObjects];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (image==nil)
    {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    //压缩图片的方法，压缩的比例可以自己调整
    UIImage *newImg = [image imageWithImageSimple:image scaledToSize:CGSizeMake(300, 300)];
    
    /*
     在这里搜得到的newImg，可以直接展示
     */
    
    [_camearAry addObject:newImg];
    
    [_bigArray addObject:_camearAry];
    
    for (int l = 0; l<_bigArray.count; l++) {
        for (UIImage *hhImgs in _bigArray[l]) {
            [_totalImgsAry addObject:hhImgs];
        }
    }
    
    [self setUpdataImage:_totalImgsAry];
    
    //关闭相册界面
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark  相册进入这里
-(void)assetPickerController:(ZYQAssetPickerController *)picker didFinishPickingAssets:(NSMutableArray *)assets
{
    _picsAry = [NSMutableArray array];
    [_bigArray removeAllObjects];
    for (int i=0; i<assets.count; i++) {
        ALAsset *asset=assets[i];
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        CGImageRef imgRef = [assetRep fullResolutionImage];
        UIImage *tempImg = [UIImage imageWithCGImage:imgRef scale:assetRep.scale orientation:(UIImageOrientation)assetRep.orientation];
        UIImage *newImg = tempImg;
        [_picsAry addObject:newImg];
        
    }
    
    [_bigArray addObject:_picsAry];
    
    for (int j = 0; j<_bigArray.count; j++) {
        for (UIImage *hImgs in _bigArray[j]) {
            [_totalImgsAry addObject:hImgs];
        }
    }
    
    if (_totalImgsAry.count > 0) {
        addBtn.hidden = YES;
    }
    
    [self setUpdataImage:_totalImgsAry];

}



@end
