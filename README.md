# Bay Tools 网站

个人网站项目，使用Python HTTP服务器部署，Safeline WAF处理SSL。

## 🔄 更新网站

### 本地修改后推送：

```bash
git add .
git commit -m "更新说明"
git push
```

### VPS上更新：

```bash
cd /home/peterbaycanada/peterbaycanada
bash update.sh
```

或手动更新：

```bash
cd /home/peterbaycanada/peterbaycanada
git pull
systemctl restart peterbay-web
```

## 📋 服务管理

```bash
# 查看服务状态
systemctl status peterbay-web

# 启动服务
systemctl start peterbay-web

# 停止服务
systemctl stop peterbay-web

# 重启服务
systemctl restart peterbay-web

# 查看日志
journalctl -u peterbay-web -f
```

## 🏗️ 架构

```
用户浏览器
    ↓ HTTPS (443)
Safeline WAF (处理SSL和WAF防护)
    ↓ HTTP (8080)
VPS Python HTTP服务器
    ↓
静态网站文件
```

## 📁 目录结构

```
/home/peterbaycanada/peterbaycanada/
├── index.html              # 首页
├── blog.html               # 博客页
├── product-1.html          # 产品页
├── product-2.html
├── product-3.html
├── pbc_logo_green.png      # Logo
└── update.sh               # 更新脚本
```

## 🛡️ Safeline配置

```
域名: 你的域名
端口: 443 (HTTPS)
上游服务器: http://VPS公网IP:8080
证书: 自动申请或上传
```

## 📞 联系方式

- GitHub: https://github.com/devB2433/peterbaycanada
- Email: dev.stbei@gmail.com
