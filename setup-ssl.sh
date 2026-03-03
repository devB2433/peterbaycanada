#!/bin/bash

# SSL证书配置脚本
# 用途：域名配置完成后，申请和配置SSL证书
# 使用方法：sudo bash setup-ssl.sh your-domain.com

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

if [ -z "$1" ]; then
    echo -e "${RED}错误：请提供域名${NC}"
    echo "使用方法: sudo bash setup-ssl.sh your-domain.com"
    exit 1
fi

DOMAIN=$1

echo -e "${GREEN}=== SSL证书配置脚本 ===${NC}"
echo "域名: $DOMAIN"
echo ""

# 安装Certbot（如果还没有）
echo -e "${YELLOW}[1/3] 安装Certbot...${NC}"
if command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
elif command -v yum &> /dev/null; then
    yum install -y epel-release
    yum install -y certbot python3-certbot-nginx
fi

# 申请SSL证书
echo -e "${YELLOW}[2/3] 申请SSL证书...${NC}"
echo "正在为 $DOMAIN 申请Let's Encrypt证书..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect

# 设置自动续期
echo -e "${YELLOW}[3/3] 设置SSL证书自动续期...${NC}"
systemctl enable certbot.timer
systemctl start certbot.timer

echo ""
echo -e "${GREEN}=== SSL配置完成！ ===${NC}"
echo ""
echo "网站地址: https://$DOMAIN"
echo ""
echo -e "${GREEN}SSL证书信息：${NC}"
certbot certificates
echo ""
echo -e "${YELLOW}提示：${NC}"
echo "- SSL证书有效期：90天"
echo "- 自动续期：到期前30天自动续期"
echo "- 查看证书状态：sudo certbot certificates"
