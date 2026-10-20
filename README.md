# wg-home — WireGuard 一行安装（Debian/Ubuntu）

从 GitHub **管道下载执行**，或装完后从固定目录再跑。两种入口兼容；再跑 GitHub 一行会**覆盖更新**固定目录里的脚本。

安装目录写死在脚本里：`$HOME/.local/share/wg-setup`（不支持外部改路径）。管道执行时也会把脚本同步进该目录，因此**不必**先落到 `/tmp`。

本仓库脚本内 **不含** 私钥、公钥、Endpoint 或内网地址。

## 入口 A：GitHub 一行（装 / 更新）

把单引号里换成你手里的 **整份 conf 的 base64**（自己粘贴）：

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/devlink123/wg-setup/main/install-wg-home.sh | bash -s -- '这里粘贴整份conf的base64' \
  && ~/.local/share/wg-setup/wg-up.sh
```

示例（假数据，仅示意格式；请换成你自己的 base64）：

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/devlink123/wg-setup/main/install-wg-home.sh | bash -s -- 'W0ludGVyZmFjZV0KQWRkcmVzcyA9IDEwLjAuMC4yLzMyClByaXZhdGVLZXkgPSBBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUE9PQoKW1BlZXJdClB1YmxpY0tleSA9IEJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQj0K' \
  && ~/.local/share/wg-setup/wg-up.sh
```

效果：

- `curl | bash -s -- '…'` 传入 base64（单引号，避免 `+`/`/` 被壳吃掉）
- 缺工具时 `apt` 安装 `wireguard-tools`、`iproute2`、`iputils-ping`
- 配置写入 `/etc/wireguard/wg-home.conf`（权限 `600`）
- 把 `install-wg-home.sh` / `wg-up.sh` / `wg-down.sh` **同步进** `$HOME/.local/share/wg-setup`（覆盖更新）

只装不连：去掉末尾的 `&& ~/.local/share/wg-setup/wg-up.sh`。

注意：

1. **必须**带上 base64 参数；漏了空参数会走 `cat`，在 `curl|bash` 下容易踩坑。
2. 管道路径会再从 GitHub **多拉一次** 脚本同步到固定目录，需要外网。


若本地已有 conf 文件、想自己生成 base64 再粘贴：

```bash
base64 -w0 /path/to/wg.conf
# 把输出复制进上面的单引号里
```

## 入口 B：固定目录（日常）

```bash
~/.local/share/wg-setup/install-wg-home.sh '这里粘贴整份conf的base64'
~/.local/share/wg-setup/wg-up.sh
~/.local/share/wg-setup/wg-down.sh
```

## 验收建议

```bash
sudo wg show wg-home   # 应有 latest handshake；勿把私钥贴到日志
```

## 安全注意

- 只把 **整份 conf 的 base64** 交给脚本；密钥不上仓库。
- 粘贴进命令后 Shell 历史可能留下 base64；用完注意清理。
- 不要提交 `/etc/wireguard/*.conf`。

## 文件

| 文件 | 说明 |
|------|------|
| `install-wg-home.sh` | 安装入口；目录写死为 `$HOME/.local/share/wg-setup` |
| `wg-up.sh` | 仓库参考副本；安装时写到固定目录 |
| `wg-down.sh` | 同上 |
