# wg-home — WireGuard one-shot install (Debian/Ubuntu)

从命令行传入 **整份 WireGuard `.conf` 的 base64**，安装工具、写入 `/etc/wireguard/wg-home.conf`，并生成连接/断开脚本。

本仓库脚本内 **不含** 私钥、公钥、Endpoint 或内网地址；配置一律由调用方 base64 传入。

## 依赖

- Debian / Ubuntu（使用 `apt-get`）
- `sudo` 权限（写 `/etc/wireguard`、执行 `wg-quick`）

## 准备配置

1. 准备一份完整的 `wg-home.conf`（至少含 `[Interface]` 与 `[Peer]`）。
2. 编码为单行 base64（不要把明文私钥贴进聊天/仓库）：

```bash
base64 -w0 wg-home.conf
# macOS:
# base64 < wg-home.conf | tr -d '\n'
```

## 安装

```bash
chmod +x install-wg-home.sh
./install-wg-home.sh '<整份conf的base64>'
```

或从 stdin：

```bash
echo '<整份conf的base64>' | ./install-wg-home.sh -
```

安装脚本会：

- 若缺少 `wg-quick` / `ip` / `ping`，则 `apt` 安装 `wireguard-tools`、`iproute2`、`iputils-ping`
- 将解码后的配置写入 `/etc/wireguard/wg-home.conf`（权限 `600`）
- 在同目录生成（或覆盖）`wg-up.sh`、`wg-down.sh`

## 连接 / 断开

```bash
./wg-up.sh      # wg-quick up wg-home；若已存在冲突的 wg0 会先尝试 down
./wg-down.sh    # wg-quick down wg-home
```

`wg-up.sh` 的 `wg show` 输出会隐藏 private / preshared key。

## 验收建议

```bash
sudo wg show wg-home   # 应有 latest handshake；勿把私钥贴到日志
# 再 ping Peer AllowedIPs 内的可达主机
```

## 安全注意

- 只把 **整份 conf 的 base64** 交给本脚本；不要把私钥写进本仓库。
- 不要提交 `/etc/wireguard/*.conf` 或含密钥的运行报告。
- 分享仓库前确认脚本与 README 中无真实 IP / 密钥。

## 文件

| 文件 | 说明 |
|------|------|
| `install-wg-home.sh` | 从 base64 安装并写出 up/down 脚本 |
| `wg-up.sh` | 连接 `wg-home`（安装后也会再生成一份） |
| `wg-down.sh` | 断开 `wg-home` |
