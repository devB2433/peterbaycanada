#!/bin/bash

# 修改Nginx端口脚本
# 用途：将Nginx从80端口改到8080端口
# 使用方法：sudo bash change-port.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

NEW_PORT=8080
NGINX_CONF="/etc/nginx/sites-available/peterbay"

echo -e "${GREEN}=== 修改Nginx端口 ===${NC}"
echo "将端口从 80 改为 $NEW_PORT"
echo ""

# 1. 修改Nginx配置
echo -e "${YELLOW}[1/3] 修改Nginx配置...${NC}"
cat > $NGINX_CONF << 'EOF'
server {
    listen 8080;
    listen [::]:8080;
    server_name _;

    root /home/peterbaycanada/peterbaycanada;
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

# 2. 测试配置
echo -e "${YELLOW}[2/3] 测试Nginx配置...${NC}"
nginx -t

# 3. 重启Nginx
echo -e "${YELLOW}[3/3] 重启Nginx...${NC}"
systemctl restart nginx

SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}=== 修改完成！ ===${NC}"
echo ""
echo "Nginx现在监听端口: $NEW_PORT"
echo "服务器IP: $SERVER_IP"
echo "测试访问: http://$SERVER_IP:$NEW_PORT"
echo ""
echo -e "${YELLOW}Safeline配置：${NC}"
echo "上游服务器: http://$SERVER_IP:$NEW_PORT"
echo ""
echo -e "${GREEN}验证：${NC}"
echo "curl -I http://localhost:$NEW_PORT"
