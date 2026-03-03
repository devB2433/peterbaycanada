#!/bin/bash

# SSL证书检查脚本
# 用途：检查SSL证书状态和自动续期配置

echo "=== SSL证书状态检查 ==="
echo ""

# 1. 查看所有证书
echo "1. 已安装的证书："
sudo certbot certificates

echo ""
echo "---"
echo ""

# 2. 检查自动续期定时器状态
echo "2. 自动续期定时器状态："
sudo systemctl status certbot.timer --no-pager

echo ""
echo "---"
echo ""

# 3. 查看下次续期时间
echo "3. 下次自动检查时间："
sudo systemctl list-timers certbot.timer --no-pager

echo ""
echo "---"
echo ""

# 4. 测试续期（不会真的续期，只是测试）
echo "4. 测试续期配置（dry-run）："
sudo certbot renew --dry-run

echo ""
echo "=== 检查完成 ==="
echo ""
echo "提示："
echo "- 证书有效期：90天"
echo "- 自动续期时间：到期前30天"
echo "- 如果看到 'Congratulations, all simulated renewals succeeded'，说明配置正确"
