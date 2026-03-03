#!/bin/bash

# Bay Tools 网站部署脚本（无SSL版本）
# 用途：部署网站到VPS，配置Nginx，准备SSL端口
# 使用方法：sudo bash deploy-no-ssl.sh

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

REPO_URL="https://github.com/devB2433/peterbaycanada.git"
WEB_ROOT="/home/peterbaycanada"
NGINX_CONF="/etc/nginx/sites-available/peterbay"

echo -e "${GREEN}=== Bay Tools 部署脚本（无SSL版本）===${NC}"
echo "仓库: $REPO_URL"
echo "部署路径: $WEB_ROOT"
echo ""

# 步骤1: 安装必要软件
echo -e "${YELLOW}[1/5] 安装必要软件...${NC}"
if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian
    apt-get update
    apt-get install -y nginx git
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    yum install -y epel-release
    yum install -y nginx git
else
    echo -e "${RED}不支持的系统${NC}"
    exit 1
fi

# 步骤2: 克隆或更新仓库
echo -e "${YELLOW}[2/5] 克隆/更新代码仓库...${NC}"
if [ -d "$WEB_ROOT" ]; then
    echo "仓库已存在，执行更新..."
    cd $WEB_ROOT
    git pull
else
    echo "克隆新仓库..."
    git clone $REPO_URL $WEB_ROOT
fi

# 设置权限
if command -v apt-get &> /dev/null; then
    chown -R www-data:www-data $WEB_ROOT
else
    chown -R nginx:nginx $WEB_ROOT
fi

# 步骤3: 配置Nginx（HTTP + HTTPS准备）
echo -e "${YELLOW}[3/5] 配置Nginx...${NC}"
cat > $NGINX_CONF << 'NGINX_EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;  # 接受所有域名

    root /home/peterbaycanada;
    index index.html;

    # 日志
    access_log /var/log/nginx/peterbay_access.log;
    error_log /var/log/nginx/peterbay_error.log;

    # 主要位置配置
    location / {
        try_files $uri $uri/ =404;
    }

    # 静态资源缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|webp)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}

# HTTPS配置（443端口）- 等待SSL证书配置
# server {
#     listen 443 ssl http2;
#     listen [::]:443 ssl http2;
#     server_name _;
#
#     root /home/peterbaycanada;
#     index index.html;
#
#     # SSL证书路径（配置域名后取消注释并修改）
#     # ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
#     # ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
#
#     # SSL配置
#     ssl_protocols TLSv1.2 TLSv1.3;
#     ssl_ciphers HIGH:!aNULL:!MD5;
#     ssl_prefer_server_ciphers on;
#
#     location / {
#         try_files $uri $uri/ =404;
#     }
#
#     location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|webp)$ {
#         expires 30d;
#         add_header Cache-Control "public, immutable";
#     }
# }
NGINX_EOF

# 启用站点
if [ ! -L "/etc/nginx/sites-enabled/peterbay" ]; then
    ln -s $NGINX_CONF /etc/nginx/sites-enabled/peterbay
fi

# 删除默认站点（如果存在）
if [ -L "/etc/nginx/sites-enabled/default" ]; then
    rm /etc/nginx/sites-enabled/default
fi

# 测试Nginx配置
echo -e "${YELLOW}测试Nginx配置...${NC}"
nginx -t

# 步骤4: 配置防火墙
echo -e "${YELLOW}[4/5] 配置防火墙（开放80和443端口）...${NC}"
if command -v ufw &> /dev/null; then
    # Ubuntu/Debian - UFW
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo "UFW防火墙规则已添加"
elif command -v firewall-cmd &> /dev/null; then
    # CentOS/RHEL - firewalld
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    echo "Firewalld防火墙规则已添加"
else
    echo "未检测到防火墙，请手动配置开放80和443端口"
fi

# 步骤5: 重启Nginx
echo -e "${YELLOW}[5/5] 重启Nginx...${NC}"
systemctl restart nginx
systemctl enable nginx

# 获取服务器IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}=== 部署完成！ ===${NC}"
echo ""
echo "网站已部署到: $WEB_ROOT"
echo "Nginx配置: $NGINX_CONF"
echo "服务器IP: $SERVER_IP"
echo ""
echo -e "${GREEN}访问方式：${NC}"
echo "HTTP: http://$SERVER_IP"
echo ""
echo -e "${YELLOW}下一步操作：${NC}"
echo "1. 配置你的域名和WAF"
echo "2. 域名配置完成后，运行以下命令申请SSL证书："
echo "   sudo certbot --nginx -d your-domain.com"
echo ""
echo -e "${GREEN}更新网站内容：${NC}"
echo "cd $WEB_ROOT && git pull"
echo ""
echo -e "${YELLOW}提示：${NC}"
echo "- 80端口已开放（HTTP）"
echo "- 443端口已准备好（等待SSL证书）"
echo "- Nginx配置文件中已预留HTTPS配置（注释状态）"
