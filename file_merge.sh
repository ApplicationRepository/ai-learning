#!/bin/bash

OUTPUT_ROOT="split_files"

if [ ! -d "$OUTPUT_ROOT" ]; then
    echo "❌ 未找到 $OUTPUT_ROOT 目录，无需还原。"
    exit 1
fi

echo "🔄 开始根据切片还原大文件到原始路径..."

# 查找所有包含切片的文件夹
find "$OUTPUT_ROOT" -type d -name "*_chunks" | while read -r chunk_dir; do

    # 1. 读取原本的文件路径
    if [ -f "$chunk_dir/.original_path" ]; then
        original_file_path=$(cat "$chunk_dir/.original_path")
    else
        # 如果找不到路径记录，退回到当前目录下
        folder_name=$(basename "$chunk_dir")
        original_filename="${folder_name%_chunks}"
        original_file_path="./$original_filename"
    fi

    # 2. 如果原文件夹在本地不存在，自动创建父目录
    parent_dir=$(dirname "$original_file_path")
    mkdir -p "$parent_dir"

    # 3. 合并切片，并在【成功后】删除该文件的切片目录
    echo "------------------------------------------------"
    echo "组合 $chunk_dir/ 内的切片 -> $original_file_path"

    # 使用 && 确保只有合并成功了，才会执行后面的删除操作
    cat "$chunk_dir"/part_* > "$original_file_path" && rm -rf "$chunk_dir"

    if [ ! -d "$chunk_dir" ]; then
        echo "🧹 [清理] 该文件的分割切片已安全删除。"
    else
        echo "⚠️ [警告] 文件合并可能失败，保留了切片备份！"
    fi
done

echo "------------------------------------------------"

# 4. 【修复版】深度清理所有因还原产生的空子目录
echo "🧹 正在清理残留的空目录..."

# -mindepth 1 确保不从根目录开始删
# -type d -empty 查找所有空文件夹
# -delete 会从最内层开始往外层删（先删 csv/，再删 split_files/）
find "$OUTPUT_ROOT" -mindepth 1 -type d -empty -delete 2>/dev/null

# 最后检查总目录是否为空，如果是则彻底拔除
if [ -d "$OUTPUT_ROOT" ] && [ -z "$(ls -A "$OUTPUT_ROOT" 2>/dev/null)" ]; then
    rm -rf "$OUTPUT_ROOT"
    echo "✨ 检查发现 '$OUTPUT_ROOT' 目录已完全倒空，已自动将其彻底删除！"
else
    echo "📁 '$OUTPUT_ROOT' 目录内仍有其他非空文件，已保留该目录。"
fi


