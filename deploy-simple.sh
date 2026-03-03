#!/bin/bash

# Bay Tools 简单部署脚本
# 用途：仅部署HTTP服务，SSL由WAF处理
# 使用方法：sudo bash deploy-simple.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

WEB_ROOT="/home/peterbaycanada"
NGINX_CONF="/etc/nginx/sites-available/peterbay"

echo -e "${GREEN}=== Bay Tools 部署脚本 ===${NC}"
echo ""

# 1. 安装Nginx
echo -e "${YELLOW}[1/4] 安装Nginx...${NC}"
if command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y nginx
elif command -v yum &> /dev/null; then
    yum install -y nginx
fi

# 2. 检查代码目录
echo -e "${YELLOW}[2/4] 检查代码目录...${NC}"
if [ ! -d "$WEB_ROOT" ]; then
    echo "错误：代码目录不存在: $WEB_ROOT"
    echo "请先执行: cd /home && git clone https://github.com/devB2433/peterbaycanada.git"
    exit 1
fi

# 设置权限
if command -v apt-get &> /dev/null; then
    chown -R www-data:www-data $WEB_ROOT
else
    chown -R nginx:nginx $WEB_ROOT
fi

# 3. 配置Nginx（仅HTTP）
echo -e "${YELLOW}[3/4] 配置Nginx...${NC}"
cat > $NGINX_CONF << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root /home/peterbaycanada;
    index index.html;

    access_log /var/log/nginx/peterbay_access.log;
    error_log /var/log/nginx/peterbay_error.log;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|webp|png)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

# 启用站点
if [ ! -L "/etc/nginx/sites-enabled/peterbay" ]; then
    ln -s $NGINX_CONF /etc/nginx/sites-enabled/peterbay
fi

# 删除默认站点
if [ -L "/etc/nginx/sites-enabled/default" ]; then
    rm /etc/nginx/sites-enabled/default
fi

# 测试配置
nginx -t

# 4. 启动Nginx
echo -e "${YELLOW}[4/4] 启动Nginx...${NC}"
systemctl restart nginx
systemctl enable nginx

SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}=== 部署完成！ ===${NC}"
echo ""
echo "网站目录: $WEB_ROOT"
echo "服务器IP: $SERVER_IP"
echo "访问地址: http://$SERVER_IP"
echo ""
echo -e "${GREEN}更新网站：${NC}"
echo "cd $WEB_ROOT && git pull"
echo ""
echo -e "${YELLOW}提示：${NC}"
echo "- 网站运行在80端口（HTTP）"
echo "- SSL由WAF处理"
echo "- Nginx配置: $NGINX_CONF"
