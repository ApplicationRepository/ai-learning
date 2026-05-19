#!/bin/bash

# 设置大文件的判定阈值（例如 100M）
SIZE_LIMIT="90M"
# 设置切片大小（例如 50M，确保 GitHub 允许提交）
CHUNK_SIZE="45M"
# 设置存放切片的根目录
OUTPUT_ROOT="split_files"

echo "🔍 开始扫描项目中大于 $SIZE_LIMIT 的大文件..."

# 使用 find 查找大于指定大小的文件，排除已经生成的切片目录和 .git 目录
find . -type f -size +"$SIZE_LIMIT" ! -path "./.git/*" ! -path "./$OUTPUT_ROOT/*" | while read -r file; do

    # 1. 获取文件名、后缀名
    filename=$(basename "$file")
    extension="${filename##*.}"

    # 如果文件没有后缀名，将其归类到 "no_ext" 文件夹
    if [ "$filename" == "$extension" ]; then
        extension="no_ext"
    fi

    # 2. 根据后缀名创建目标存放目录
    safe_filename=$(echo "$filename" | tr ' ' '_')
    target_dir="$OUTPUT_ROOT/$extension/${safe_filename}_chunks"
    mkdir -p "$target_dir"

    echo "------------------------------------------------"
    echo "📦 发现大文件: $file (${extension} 格式)"
    echo "⚡ 正在切分为 ${CHUNK_SIZE} 的区块..."

    # 3. 开始切分文件
    split -b "$CHUNK_SIZE" "$file" "$target_dir/part_"

    # 4. 【安全校验】检查是否成功生成了至少一个切片文件
    if [ -f "$target_dir/part_aa" ]; then
        echo "✅ 切片成功生成，正在删除本地原文件: $file"
        rm "$file"  # 👈 核心修改：安全删除原文件
    else
        echo "❌ 错误：$file 切片失败，保留原文件！"
        continue
    fi

    # 5. 将大文件的相对路径记录下来，供以后还原时知道它原本在哪个文件夹
    # 我们把路径关系写到切片目录下的一个隐藏文本里，这样还原脚本就能精确恢复
    echo "$file" > "$target_dir/.original_path"

done

echo "------------------------------------------------"
echo "✅ 所有大文件处理完毕！原文件已删除，切片已存入 /$OUTPUT_ROOT 目录。"
echo "🚀 现在你可以安全地执行 git add . 并提交了！"

