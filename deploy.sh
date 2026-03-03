#!/bin/bash

# Bay Tools 网站部署脚本
# 用途：自动化部署到VPS，包含SSL配置
# 使用方法：sudo bash deploy.sh your-domain.com

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

# 检查域名参数
if [ -z "$1" ]; then
    echo -e "${RED}错误：请提供域名${NC}"
    echo "使用方法: sudo bash deploy.sh your-domain.com"
    exit 1
fi

DOMAIN=$1
REPO_URL="https://github.com/devB2433/peterbaycanada.git"
WEB_ROOT="/var/www/peterbaycanada"
NGINX_CONF="/etc/nginx/sites-available/peterbay"

echo -e "${GREEN}=== Bay Tools 部署脚本 ===${NC}"
echo "域名: $DOMAIN"
echo "仓库: $REPO_URL"
echo ""

# 步骤1: 安装必要软件
echo -e "${YELLOW}[1/6] 安装必要软件...${NC}"
if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian
    apt-get update
    apt-get install -y nginx git certbot python3-certbot-nginx
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    yum install -y epel-release
    yum install -y nginx git certbot python3-certbot-nginx
else
    echo -e "${RED}不支持的系统${NC}"
    exit 1
fi

# 步骤2: 克隆或更新仓库
echo -e "${YELLOW}[2/6] 克隆/更新代码仓库...${NC}"
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

# 步骤3: 配置Nginx（HTTP）
echo -e "${YELLOW}[3/6] 配置Nginx...${NC}"
cat > $NGINX_CONF << 'NGINX_EOF'
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;

    root /var/www/peterbaycanada;
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
NGINX_EOF

# 替换域名占位符
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" $NGINX_CONF

# 启用站点
if [ ! -L "/etc/nginx/sites-enabled/peterbay" ]; then
    ln -s $NGINX_CONF /etc/nginx/sites-enabled/peterbay
fi

# 测试Nginx配置
echo -e "${YELLOW}测试Nginx配置...${NC}"
nginx -t

# 步骤4: 重启Nginx
echo -e "${YELLOW}[4/6] 重启Nginx...${NC}"
systemctl restart nginx
systemctl enable nginx

# 步骤5: 配置SSL证书
echo -e "${YELLOW}[5/6] 配置SSL证书...${NC}"
echo "正在为 $DOMAIN 申请Let's Encrypt证书..."
echo "注意：请确保域名已正确解析到此服务器IP"
read -p "按Enter继续，或Ctrl+C取消..."

certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect

# 步骤6: 设置自动续期
echo -e "${YELLOW}[6/6] 设置SSL证书自动续期...${NC}"
systemctl enable certbot.timer
systemctl start certbot.timer

echo ""
echo -e "${GREEN}=== 部署完成！ ===${NC}"
echo ""
echo "网站地址: https://$DOMAIN"
echo "配置文件: $NGINX_CONF"
echo "网站目录: $WEB_ROOT"
echo ""
echo -e "${GREEN}后续更新方法：${NC}"
echo "1. 本地修改后推送到GitHub:"
echo "   git add ."
echo "   git commit -m '更新说明'"
echo "   git push"
echo ""
echo "2. VPS上更新（两种方式）："
echo "   方式A: cd $WEB_ROOT && git pull"
echo "   方式B: sudo bash deploy.sh $DOMAIN"
echo ""
echo -e "${YELLOW}提示：SSL证书会自动续期，无需手动操作${NC}"
