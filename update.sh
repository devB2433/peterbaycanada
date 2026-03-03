#!/bin/bash

# Bay Tools 网站更新脚本
# 用途：更新网站代码并重启服务
# 使用方法：bash update.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

WEB_ROOT="/home/peterbaycanada/peterbaycanada"

echo -e "${GREEN}=== Bay Tools 更新脚本 ===${NC}"
echo ""

# 1. 检查目录
if [ ! -d "$WEB_ROOT" ]; then
    echo "错误：网站目录不存在: $WEB_ROOT"
    exit 1
fi

# 2. 更新代码
echo -e "${YELLOW}[1/2] 更新代码...${NC}"
cd $WEB_ROOT
git pull

# 3. 重启服务
echo -e "${YELLOW}[2/2] 重启服务...${NC}"
if systemctl is-active --quiet peterbay-web; then
    systemctl restart peterbay-web
    echo "服务已重启"
else
    echo "警告：peterbay-web 服务未运行"
fi

echo ""
echo -e "${GREEN}=== 更新完成！ ===${NC}"
echo "更新时间: $(date)"
