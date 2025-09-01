# TTFB Test Script

🚀 一个功能强大的TTFB（Time To First Byte）延迟测试工具，纯Shell实现，支持多语言界面和并发测试。

## 功能特点

- 🚀 **纯Shell实现**：兼容Debian/RedHat/Alpine/macOS系统，无需Python环境
- 🌐 **多语言支持**：支持中文/英文界面，启动时可选择语言
- ⚡ **并发测试**：支持多线程并发测试，提高测试效率
- 🎯 **精确测量**：分别测量DNS解析、TCP连接、TLS握手和TTFB时间
- 🔄 **强制回源**：通过404路径测试真实服务器性能，避免CDN缓存
- 📊 **详细统计**：提供平均值、最小值、最大值、中位数和标准差
- 🎨 **可视化显示**：5级性能分类，彩色状态指示器
- 📝 **Markdown输出**：支持Markdown格式输出，便于分享和文档化
- 🛠️ **自动依赖检测**：自动检测并提示安装缺失的系统依赖

## 性能分级标准

- 🟢 **优秀** (≤200ms): 网络延迟极低，用户体验优秀
- 🟡 **良好** (200-350ms): 网络延迟较低，用户体验良好  
- 🟠 **一般** (350-500ms): 网络延迟中等，用户体验尚可
- 🔴 **中等偏下** (500-700ms): 网络延迟较高，用户体验欠佳
- 🟣 **差** (>700ms): 网络延迟很高，用户体验较差

## 测试网站列表

脚本默认测试以下20个主流网站的稳定端点：

- Google、GitHub、Netflix、Spotify、Disney+
- Facebook、X(Twitter)、Instagram、TikTok、YouTube  
- Twitch、Pornhub、Apple、Steam、Office
- Telegram、Reddit、Discord、OpenAI(API)、Claude(API)

所有测试端点都经过优化，使用robots.txt、favicon.ico或generate_204等稳定路径，避免重定向问题。

> 📋 **详细说明**: 关于每个测试端点的选择原因和技术细节，请查看 [端点选择说明文档](ENDPOINTS_EXPLAINED.md)

## 系统要求

### 必需工具
- `curl` - HTTP请求工具
- `dig` 或 `nslookup` - DNS解析工具
- `bc` - 数学计算工具
- `column` - 表格格式化工具

### 支持系统
- **Debian/Ubuntu**: 自动安装 `curl dnsutils bc util-linux`
- **RHEL/CentOS/Fedora**: 自动安装 `curl bind-utils bc util-linux`  
- **Alpine Linux**: 自动安装 `curl bind-tools bc util-linux`
- **macOS**: 通过Homebrew安装依赖

脚本会自动检测缺失依赖并提示安装命令。

## 快速开始

### 🚀 一键运行（推荐）

**方式一：使用curl（推荐，macOS/Linux通用）**
```bash
curl -fsSL https://raw.githubusercontent.com/VoidNov/TTFB-Test-Script/main/ttfb-test.sh -o ttfb-test.sh && chmod +x ttfb-test.sh && ./ttfb-test.sh
```

**方式二：使用wget（Linux系统）**
```bash
wget -O ttfb-test.sh https://raw.githubusercontent.com/VoidNov/TTFB-Test-Script/main/ttfb-test.sh && chmod +x ttfb-test.sh && ./ttfb-test.sh
```

**方式三：Alpine Linux专用（容器环境）**
```bash
# 安装bash支持
sudo apk add --no-cache bash curl

# 下载并运行脚本
curl -fsSL https://raw.githubusercontent.com/VoidNov/TTFB-Test-Script/main/ttfb-test.sh -o ttfb-test.sh && chmod +x ttfb-test.sh && bash ./ttfb-test.sh
```

> **工具说明**：curl在大多数现代系统中预装（包括macOS），wget在某些Linux发行版中需要额外安装。脚本运行时会自动检测和提示安装所需依赖。

### 📥 手动下载

### 1. 下载并赋予执行权限
```bash
# 克隆仓库
git clone https://github.com/VoidNov/TTFB-Test-Script.git
cd TTFB-Test-Script
chmod +x ttfb-test.sh
```

### 2. 基本用法

```bash
# 使用默认设置测试所有网站
./ttfb-test.sh

# 显示详细信息（包含完整计时数据）
./ttfb-test.sh -a

# 测试指定网站
./ttfb-test.sh https://www.google.com https://www.github.com
```

### 3. 首次运行
脚本会自动检测系统依赖，如有缺失会提示安装命令。在Debian/Ubuntu系统上会询问是否自动安装。

### 高级选项

```bash
# 详细输出模式
./ttfb-test.sh -v

# 输出JSON格式结果
./ttfb-test.sh -j -o results.json

# 输出Markdown格式结果（便于分享）
./ttfb-test.sh -m

# 组合使用：详细版本的Markdown输出
./ttfb-test.sh -a -m

# 自定义测试参数
./ttfb-test.sh -n 3 -t 5 -w 8 -d 1
```

### 参数说明

| 参数 | 长参数 | 说明 | 默认值 |
|------|--------|------|--------|
| `-h` | `--help` | 显示帮助信息 | - |
| `-v` | `--verbose` | 详细输出模式 | false |
| `-a` | `--all` | 显示完整结果表格 | false |
| `-j` | `--json` | 输出JSON格式结果 | false |
| `-m` | `--markdown` | 输出Markdown格式结果 | false |
| `-o` | `--output FILE` | JSON输出文件名 | ttfb_results.json |
| `-n` | `--num-tests N` | 每URL测试次数 | 5 |
| `-t` | `--timeout N` | 超时秒数 | 10 |
| `-d` | `--delay N` | 测试间隔秒数 | 0.5 |
| `-w` | `--workers N` | 并发数 | 4 |
| `--no-progress` | - | 不显示进度条 | false |

## 输出说明

### 主要测试结果表格
- **主机**: 网站简化显示名称
- **状态**: HTTP状态码（✅2xx成功，🔄3xx重定向，❌4xx/5xx错误）
- **协议**: HTTP版本（1.1/2）
- **DNS**: DNS解析时间（毫秒）
- **连接**: TCP连接建立时间（毫秒）
- **TLS**: TLS握手时间（毫秒，HTTP站点为0）
- **TTFB**: 首字节响应时间（毫秒）
- **回源**: 强制回源TTFB时间（毫秒）

### 性能摘要表格
- **主机**: 网站名称
- **状态**: 状态指示器 + HTTP状态码
- **TTFB**: TTFB时间
- **等级**: 性能等级（优秀/良好/一般/中等偏下/差）

### ⚠️ 特别说明
- **AI API节点**: OpenAI(API)和Claude(API)节点返回401/403状态码是正常现象，因为这些是需要认证的API端点。测试重点在于网络连通性和响应时间，而非API调用成功。

## TTFB测量原理

TTFB使用curl的`time_starttransfer`时间，包含：
1. **DNS解析时间**: 域名到IP地址解析
2. **TCP连接时间**: 建立TCP连接
3. **TLS握手时间**: HTTPS加密握手（如适用）
4. **服务器响应时间**: 服务器处理请求并返回首字节的时间

公式：`TTFB = DNS时间 + 连接时间 + TLS时间 + 服务器处理时间`

## Markdown格式输出

使用`-m`参数可以输出Markdown格式的测试结果，便于复制到GitHub、Notion等平台：

```markdown
## 🎯 性能摘要

| 主机 | 状态 | TTFB | 等级 |
|------|------|------|------|
| Google | ✅204 | 133ms | 🟢 |
| Microsoft | ✅200 | 136ms | 🟢 |
| GitHub | ✅200 | 432ms | 🟠 |

## 📊 总体统计

- 🎯 **测试URL数**: 3
- ✅ **成功测试**: 3  
- 🌐 **平均DNS解析**: 5.3ms
- 🔗 **平均连接时间**: 2.7ms
- 🔒 **平均TLS握手**: 97.7ms
- ⚡ **平均TTFB**: 233.7ms
```

**Markdown输出特性：**
- 📋 **标准格式**：遵循GitHub Flavored Markdown规范
- 🎨 **彩球指示器**：🟢🟡🟠🔴🟣 表示性能等级
- 📊 **状态图标**：✅❌🔄 表示HTTP状态
- 📈 **完整统计**：包含所有性能指标和分级信息
- 📝 **易于分享**：可直接复制到文档或报告中

## 强制回源测试

为了测试真实的服务器性能（绕过CDN缓存），脚本会额外请求一个不存在的路径（如`/invalidpath404`），这通常会：
- 绕过CDN边缘缓存
- 直接访问源服务器
- 提供更准确的服务器响应时间测量

## 示例输出

```
================================================================================
TTFB延迟测试结果 - 修正版 (TTFB = DNS + 连接 + TLS + 服务器首字节响应时间)
================================================================================

📊 测试结果详情:

主机       状态  协议  DNS(ms)  连接(ms)  TLS(ms)  TTFB(ms)  回源(ms)
Google     204   2     4        0         93       133       216
Microsoft  200   2     7        4         79       136       266
GitHub     200   2     5        4         121      432       500

🎯 性能摘要 (视觉指示):

主机       状态   TTFB   等级
Google     ✅204  133ms  优秀
Microsoft  ✅200  136ms  优秀
GitHub     ✅200  432ms  一般

📊 总体统计:
  🎯 测试URL数: 3
  ✅ 成功测试: 3
  🌐 平均DNS解析: 5.3ms
  🔗 平均连接时间: 2.7ms
  🔒 平均TLS握手: 97.7ms
  ⚡ 平均TTFB: 233.7ms

📈 TTFB性能分级 (标准参考):
  🟢 优秀 (≤200ms): 2 个
  🟡 良好 (200-350ms): 0 个
  🟠 一般 (350-500ms): 1 个
  🔴 中等偏下 (500-700ms): 0 个
  🟣 差 (>700ms): 0 个
```

## 故障排除

### 常见问题

1. **依赖缺失**
   - 脚本会自动检测并提示安装命令
   - 手动安装：参考脚本输出的系统特定命令

2. **权限问题**
   - 确保脚本有执行权限：`chmod +x ttfb-test.sh`
   - 依赖安装可能需要sudo权限

3. **网络问题**
   - 某些网站可能被防火墙阻止
   - 代理环境下延迟会显著增加

4. **macOS兼容性**
   - 脚本兼容macOS的bash 3.2版本
   - 可能需要通过Homebrew安装部分依赖

5. **Alpine Linux容器环境**
   - 需要先安装bash支持：`apk add --no-cache bash`
   - 脚本会自动检测并安装所需依赖（util-linux等）
   - 确保容器有网络访问权限

### 调试模式

使用`-v`参数启用详细输出，查看每次测试的详细结果：

```bash
./ttfb-test.sh -v
```

## 许可证

MIT License

## 贡献指南

欢迎提交Issue和Pull Request来改进这个工具：

- 🐛 **Bug报告**：请详细描述问题和复现步骤
- ✨ **功能建议**：欢迎提出新功能想法
- 🔧 **代码贡献**：请遵循现有代码风格
- 📖 **文档改进**：帮助完善文档和示例

## 版本历史

- **v1.0** - 初始版本
  - ✅ 纯Shell实现，支持多系统
  - ✅ 19个主流网站稳定端点测试
  - ✅ 中英文双语界面
  - ✅ 并发测试和性能分级
  - ✅ 强制回源测试功能
  - ✅ 自动依赖检测和安装
  - ✅ JSON和Markdown格式输出
  - ✅ 交互式模式选择（详细/摘要，格式输出）
  - ✅ 性能等级指示器

## Star History

如果这个工具对您有帮助，请给个 ⭐ Star 支持一下！

## 开源协议

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情
