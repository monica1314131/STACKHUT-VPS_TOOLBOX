#!/bin/bash

# 设置默认提交信息
COMMIT_MSG=${1:-"🔄 更新脚本文件"}

# 输出开始信息
echo "📤 正在上传文件到 GitHub..."
echo "📝 提交说明: $COMMIT_MSG"

# 添加所有更改
git add .

# 提交
git commit -m "$COMMIT_MSG"

# 推送
git push origin main

# 显示结果
if [ $? -eq 0 ]; then
  echo "✅ 上传成功！"
else
  echo "❌ 上传失败，请检查错误信息"
fi
