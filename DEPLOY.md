# Bay Tools 网站部署指南

## 快速部署到VPS

### 前置要求
- 一台VPS服务器（Ubuntu/Debian/CentOS）
- 域名已解析到VPS的IP地址
- SSH访问权限

### 首次部署

1. **上传部署脚本到VPS**
   ```bash
   scp deploy.sh root@your-vps-ip:/root/
   ```

2. **SSH登录VPS并运行部署脚本**
   ```bash
   ssh root@your-vps-ip
   sudo bash deploy.sh your-domain.com
   ```

3. **完成！**
   访问 `https://your-domain.com` 查看网站

### 后续更新流程

#### 方式1：本地修改 → GitHub → VPS更新（推荐）

**本地操作：**
```bash
# 修改文件后
git add .
git commit -m "描述你的修改"
git push
```

**VPS操作：**
```bash
# SSH登录VPS
ssh root@your-vps-ip

# 快速更新（推荐）
sudo bash /var/www/peterbaycanada/update.sh

# 或者手动更新
cd /var/www/peterbaycanada && git pull
```

#### 方式2：重新运行完整部署
```bash
sudo bash deploy.sh your-domain.com
```

## 脚本说明

### deploy.sh - 完整部署脚本
- 安装Nginx、Git、Certbot
- 克隆/更新代码仓库
- 配置Nginx
- 自动申请SSL证书（Let's Encrypt）
- 设置SSL自动续期

### update.sh - 快速更新脚本
- 仅更新代码
- 不修改Nginx配置
- 适合日常内容更新

## 目录结构

```
/var/www/peterbaycanada/     # 网站根目录
├── index.html               # 首页
├── blog.html                # 博客页
├── product-1.html           # 产品页1
├── product-2.html           # 产品页2
├── product-3.html           # 产品页3
├── pbc_logo_green.png       # Logo
└── ...
```

## Nginx配置

配置文件位置：`/etc/nginx/sites-available/peterbay`

查看配置：
```bash
sudo cat /etc/nginx/sites-available/peterbay
```

测试配置：
```bash
sudo nginx -t
```

重启Nginx：
```bash
sudo systemctl restart nginx
```

## SSL证书（自动化✅）

### 证书提供商
- **Let's Encrypt**（免费、自动化、受信任）
- 证书有效期：90天
- 自动续期：到期前30天

### 自动续期机制
部署脚本已自动配置证书续期，**完全无需人工干预**：

```bash
# 系统会自动运行（已配置）
systemctl enable certbot.timer   # 启用定时器
systemctl start certbot.timer    # 启动定时器
```

**工作原理：**
- 每天自动检查证书状态
- 到期前30天自动续期
- 续期成功后自动重载Nginx
- 失败时会记录到系统日志

### 检查SSL状态

运行SSL检查脚本：
```bash
sudo bash /var/www/peterbaycanada/ssl-check.sh
```

或手动检查：

**1. 查看证书信息**
```bash
sudo certbot certificates
```

**2. 查看自动续期状态**
```bash
sudo systemctl status certbot.timer
```

**3. 查看下次检查时间**
```bash
sudo systemctl list-timers certbot.timer
```

**4. 测试续期配置（不会真的续期）**
```bash
sudo certbot renew --dry-run
```
看到 "Congratulations, all simulated renewals succeeded" 说明配置正确。

### 证书文件位置
```
/etc/letsencrypt/live/your-domain.com/
├── fullchain.pem    # 完整证书链
├── privkey.pem      # 私钥
├── cert.pem         # 证书
└── chain.pem        # 中间证书
```

### 手动操作（通常不需要）

**手动续期：**
```bash
sudo certbot renew
```

**强制续期（即使未到期）：**
```bash
sudo certbot renew --force-renewal
```

**查看续期日志：**
```bash
sudo journalctl -u certbot.timer
```

### 常见问题

**Q: 证书会过期吗？**
A: 不会。自动续期已配置，系统会在到期前30天自动续期。

**Q: 如何知道续期是否成功？**
A: 运行 `sudo certbot certificates` 查看到期时间，或查看日志 `sudo journalctl -u certbot.timer`

**Q: 更换域名怎么办？**
A: 重新运行 `sudo bash deploy.sh new-domain.com`

**Q: 支持多个域名吗？**
A: 支持。修改deploy.sh中的certbot命令：
```bash
certbot --nginx -d domain1.com -d www.domain1.com -d domain2.com
```

## 日志查看

Nginx访问日志：
```bash
sudo tail -f /var/log/nginx/peterbay_access.log
```

Nginx错误日志：
```bash
sudo tail -f /var/log/nginx/peterbay_error.log
```

## 故障排查

### 网站无法访问
1. 检查Nginx状态：`sudo systemctl status nginx`
2. 检查配置：`sudo nginx -t`
3. 查看错误日志：`sudo tail -f /var/log/nginx/peterbay_error.log`

### SSL证书问题
1. 检查证书状态：`sudo certbot certificates`
2. 手动续期：`sudo certbot renew`

### Git更新失败
1. 检查仓库状态：`cd /var/www/peterbaycanada && git status`
2. 重置本地修改：`git reset --hard origin/main`
3. 重新拉取：`git pull`

## 安全建议

1. **定期更新系统**
   ```bash
   sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
   sudo yum update -y                       # CentOS
   ```

2. **配置防火墙**
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw allow 22/tcp
   sudo ufw enable
   ```

3. **监控SSL证书过期**
   - Let's Encrypt证书有效期90天
   - certbot会自动续期
   - 可以设置邮件提醒

## 联系信息

- GitHub: https://github.com/devB2433/peterbaycanada
- Email: dev.stbei@gmail.com
