#!/usr/bin/env python3
"""
生成绿植管家App图标
"""

import sys
import os
from PIL import Image, ImageDraw, ImageFont
import math

def create_app_icon(size=1024):
    """创建App图标 - 纯白色背景版本"""
    # 创建图像 - 纯白色背景
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # 计算半径和中心
    center = size // 2
    radius = size // 2 - 50  # 稍微小一点，留出边距
    
    # 绘制圆形背景（浅绿色）
    draw.ellipse([center - radius, center - radius, 
                  center + radius, center + radius], 
                 fill=(232, 245, 233, 255))  # 浅绿色 #E8F5E9
    
    # 绘制水滴形状（简化版本，使用绘图函数而不是逐像素）
    drop_radius = radius * 0.5
    drop_top = center - int(drop_radius * 0.7)
    drop_bottom = center + int(drop_radius * 0.8)
    
    # 绘制水滴主体（蓝色圆形）
    draw.ellipse([center - drop_radius, drop_top, 
                  center + drop_radius, drop_bottom], 
                 fill=(33, 150, 243, 255))  # 蓝色 #2196F3
    
    # 绘制水滴尖端（更小的圆形在顶部）
    tip_radius = drop_radius * 0.3
    tip_top = drop_top - tip_radius // 2
    draw.ellipse([center - tip_radius, tip_top, 
                  center + tip_radius, tip_top + tip_radius * 2], 
                 fill=(33, 150, 243, 255))
    
    # 在水滴中绘制植物轮廓（简单的叶子形状）
    leaf_color = (255, 255, 255, 255)  # 白色
    
    # 绘制主茎（稍微粗一点）
    stem_width = int(drop_radius * 0.12)
    stem_top = center - int(drop_radius * 0.15)
    stem_bottom = center + int(drop_radius * 0.25)
    draw.rectangle([center - stem_width // 2, stem_top, 
                    center + stem_width // 2, stem_bottom], 
                   fill=leaf_color, outline=leaf_color)
    
    # 绘制叶子（更明显的三角形）
    leaf_size = int(drop_radius * 0.3)
    
    # 左侧叶子
    left_leaf = [
        (center - stem_width // 2, stem_top + leaf_size // 2),
        (center - stem_width // 2 - leaf_size, stem_top - leaf_size // 4),
        (center - stem_width // 2, stem_top - leaf_size // 4)
    ]
    draw.polygon(left_leaf, fill=leaf_color, outline=leaf_color)
    
    # 右侧叶子
    right_leaf = [
        (center + stem_width // 2, stem_top + leaf_size // 2),
        (center + stem_width // 2 + leaf_size, stem_top - leaf_size // 4),
        (center + stem_width // 2, stem_top - leaf_size // 4)
    ]
    draw.polygon(right_leaf, fill=leaf_color, outline=leaf_color)
    
    # 顶部叶子（更大更明显）
    top_leaf = [
        (center, stem_top - leaf_size // 1.5),
        (center - leaf_size // 1.5, stem_top - leaf_size // 4),
        (center + leaf_size // 1.5, stem_top - leaf_size // 4)
    ]
    draw.polygon(top_leaf, fill=leaf_color, outline=leaf_color)
    
    # 添加一个简单的圆形边框，让图标更有层次感
    border_width = 5
    draw.ellipse([center - radius - border_width, center - radius - border_width,
                  center + radius + border_width, center + radius + border_width],
                 outline=(200, 230, 200, 255), width=border_width)
    
    return img

def generate_all_sizes():
    """生成所有需要的尺寸"""
    # 需要的尺寸列表 (根据Contents.json)
    sizes = [
        # iOS 尺寸
        (1024, 1024, "universal"),
        # macOS 尺寸
        (16, 16, "mac"),
        (32, 32, "mac"),
        (128, 128, "mac"),
        (256, 256, "mac"),
        (512, 512, "mac"),
    ]
    
    # 创建输出目录
    output_dir = "绿植管家/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    # 先生成1024x1024的主图标
    main_icon = create_app_icon(1024)
    main_icon.save(os.path.join(output_dir, "icon_1024x1024.png"), "PNG")
    print(f"生成: icon_1024x1024.png")
    
    # 生成其他尺寸
    for width, height, platform in sizes:
        if width == 1024 and height == 1024:
            continue  # 已经生成
            
        # 创建缩放版本
        scaled = main_icon.resize((width, height), Image.Resampling.LANCZOS)
        
        # 保存1x版本
        filename = f"icon_{width}x{height}.png"
        scaled.save(os.path.join(output_dir, filename), "PNG")
        print(f"生成: {filename}")
        
        # 对于macOS尺寸，还需要2x版本
        if platform == "mac":
            filename_2x = f"icon_{width}x{height}@2x.png"
            scaled_2x = main_icon.resize((width * 2, height * 2), Image.Resampling.LANCZOS)
            scaled_2x.save(os.path.join(output_dir, filename_2x), "PNG")
            print(f"生成: {filename_2x}")

if __name__ == "__main__":
    # 检查PIL是否安装
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("错误: 需要安装Pillow库")
        print("请运行: pip3 install Pillow")
        sys.exit(1)
    
    print("开始生成绿植管家App图标...")
    generate_all_sizes()
    print("图标生成完成！")
