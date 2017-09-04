//
//  UIImage+ImageSimple.m
//  多选图片
//
//  Created by Hero11223 on 16/5/13.
//  Copyright © 2016年 zyy. All rights reserved.
//

#import "UIImage+ImageSimple.h"

@implementation UIImage (ImageSimple)

#pragma mark 压缩图片
- (UIImage*)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
