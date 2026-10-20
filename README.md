# wg-home — WireGuard 一行安装（Debian/Ubuntu）

从 GitHub **下载脚本到本地再执行**（不要先 clone）。传入整份 WireGuard `.conf` 的 base64，完成装包、写配置、生成连接脚本并可立刻连上。

本仓库脚本内 **不含** 私钥、公钥、Endpoint 或内网地址。

## 一行安装 + 配置 + 连接

把 `/path/to/wg.conf` 换成你的完整配置路径：

```bash
curl -fsSL https://raw.githubusercontent.com/devlink123/wg-setup/main/install-wg-home.sh -o /tmp/install-wg-home.sh && bash /tmp/install-wg-home.sh "$(base64 -w0 /path/to/wg.conf)" && /tmp/wg-up.sh
```

macOS 把 `base64 -w0` 换成 `base64 < /path/to/wg.conf | tr -d '\n'`。

说明：

- 先落到 `/tmp` 再跑，避免 `curl|bash` 时 `$0` 丢目录、写不出旁边的 `wg-up.sh`
- 缺工具时 `apt` 安装 `wireguard-tools`、`iproute2`、`iputils-ping`
- 配置写入 `/etc/wireguard/wg-home.conf`（权限 `600`）
- 同目录生成 `wg-up.sh`、`wg-down.sh`（上例即 `/tmp/`）

只装不连：去掉末尾的 `&& /tmp/wg-up.sh`。

## 断开

```bash
/tmp/wg-down.sh
```

`wg-up.sh` 的 `wg show` 会隐藏 private / preshared key。

## 验收建议

```bash
sudo wg show wg-home   # 应有 latest handshake；勿把私钥贴到日志
# 再 ping Peer AllowedIPs 内的可达主机
```

## 安全注意

- 只把 **整份 conf 的 base64** 交给脚本；密钥不上仓库。
- Shell 历史可能留下 base64；用完注意清理。
- 不要提交 `/etc/wireguard/*.conf`。

## 可选：已克隆本仓库时

```bash
./install-wg-home.sh "$(base64 -w0 /path/to/wg.conf)"
./wg-up.sh
```

## 文件

| 文件 | 说明 |
|------|------|
| `install-wg-home.sh` | 安装入口（base64 → conf + 旁路生成 up/down） |
| `wg-up.sh` | 仓库内参考副本；安装时写到脚本同目录 |
| `wg-down.sh` | 同上 |
