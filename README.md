# wg-home — WireGuard 一行安装（Debian/Ubuntu）

从 GitHub 下载执行，或装完后从固定目录再跑。两种入口兼容；再跑 GitHub 一行会**覆盖更新**固定目录里的脚本。

固定目录（免 root、可写）：`~/.local/share/wg-setup`  
（可用 `WG_SETUP_DIR` 或 `XDG_DATA_HOME` 覆盖。）

本仓库脚本内 **不含** 私钥、公钥、Endpoint 或内网地址。

## 入口 A：GitHub 一行（装 / 更新）

```bash
curl -fsSL https://raw.githubusercontent.com/devlink123/wg-setup/main/install-wg-home.sh -o /tmp/install-wg-home.sh \
  && bash /tmp/install-wg-home.sh "$(base64 -w0 /path/to/wg.conf)" \
  && ~/.local/share/wg-setup/wg-up.sh
```

macOS 把 `base64 -w0 …` 换成 `base64 < /path/to/wg.conf | tr -d '\n'`。

效果：

- 先落到 `/tmp` 再跑（避免 `curl|bash` 丢路径）
- 缺工具时 `apt` 安装 `wireguard-tools`、`iproute2`、`iputils-ping`
- 配置写入 `/etc/wireguard/wg-home.conf`（权限 `600`）
- 把 `install-wg-home.sh` / `wg-up.sh` / `wg-down.sh` **同步进** `~/.local/share/wg-setup`（覆盖更新）

只装不连：去掉末尾的 `&& ~/.local/share/wg-setup/wg-up.sh`。

## 入口 B：固定目录（日常）

```bash
~/.local/share/wg-setup/install-wg-home.sh "$(base64 -w0 /path/to/wg.conf)"
~/.local/share/wg-setup/wg-up.sh
~/.local/share/wg-setup/wg-down.sh
```

## 验收建议

```bash
sudo wg show wg-home   # 应有 latest handshake；勿把私钥贴到日志
```

## 安全注意

- 只把 **整份 conf 的 base64** 交给脚本；密钥不上仓库。
- Shell 历史可能留下 base64；用完注意清理。
- 不要提交 `/etc/wireguard/*.conf`。

## 文件

| 文件 | 说明 |
|------|------|
| `install-wg-home.sh` | 安装入口；跑完同步到固定目录 |
| `wg-up.sh` | 仓库参考副本；安装时写到固定目录 |
| `wg-down.sh` | 同上 |
