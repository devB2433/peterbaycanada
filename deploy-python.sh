#!/bin/bash

# 简单Web服务器部署脚本
# 用途：使用Python启动简单HTTP服务器，不需要Nginx
# 使用方法：sudo bash deploy-python.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

WEB_ROOT="/home/peterbaycanada/peterbaycanada"
PORT=8080

echo -e "${GREEN}=== 简单Web服务器部署 ===${NC}"
echo ""

# 1. 停止并卸载Nginx（如果有）
echo -e "${YELLOW}[1/4] 停止并卸载Nginx...${NC}"
if systemctl is-active --quiet nginx; then
    systemctl stop nginx
    systemctl disable nginx
    echo "Nginx已停止"
fi

if command -v apt-get &> /dev/null; then
    apt-get remove -y nginx nginx-common
    apt-get autoremove -y
elif command -v yum &> /dev/null; then
    yum remove -y nginx
fi

# 2. 检查代码目录
echo -e "${YELLOW}[2/4] 检查代码目录...${NC}"
if [ ! -d "$WEB_ROOT" ]; then
    echo "错误：代码目录不存在: $WEB_ROOT"
    echo "请先执行: cd /home && git clone https://github.com/devB2433/peterbaycanada.git"
    exit 1
fi

# 3. 创建systemd服务
echo -e "${YELLOW}[3/4] 创建systemd服务...${NC}"
cat > /etc/systemd/system/peterbay-web.service << EOF
[Unit]
Description=Peter Bay Website
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$WEB_ROOT
ExecStart=/usr/bin/python3 -m http.server $PORT
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 4. 启动服务
echo -e "${YELLOW}[4/4] 启动Web服务...${NC}"
systemctl daemon-reload
systemctl enable peterbay-web
systemctl start peterbay-web

# 等待服务启动
sleep 2

SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}=== 部署完成！ ===${NC}"
echo ""
echo "网站目录: $WEB_ROOT"
echo "运行端口: $PORT"
echo "服务器IP: $SERVER_IP"
echo "访问地址: http://$SERVER_IP:$PORT"
echo ""
echo -e "${YELLOW}Safeline配置：${NC}"
echo "上游服务器: http://$SERVER_IP:$PORT"
echo ""
echo -e "${GREEN}管理命令：${NC}"
echo "查看状态: systemctl status peterbay-web"
echo "停止服务: systemctl stop peterbay-web"
echo "启动服务: systemctl start peterbay-web"
echo "重启服务: systemctl restart peterbay-web"
echo "查看日志: journalctl -u peterbay-web -f"
echo ""
echo -e "${GREEN}更新网站：${NC}"
echo "cd $WEB_ROOT && git pull && systemctl restart peterbay-web"
