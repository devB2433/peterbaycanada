#!/bin/bash

# Bay Tools 快速更新脚本
# 用途：快速更新网站内容（不重新配置Nginx和SSL）
# 使用方法：sudo bash update.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

WEB_ROOT="/var/www/peterbaycanada"

echo -e "${GREEN}=== Bay Tools 快速更新 ===${NC}"

if [ ! -d "$WEB_ROOT" ]; then
    echo "错误：网站目录不存在，请先运行 deploy.sh"
    exit 1
fi

echo -e "${YELLOW}正在更新代码...${NC}"
cd $WEB_ROOT
git pull

echo -e "${GREEN}更新完成！${NC}"
echo "更新时间: $(date)"
