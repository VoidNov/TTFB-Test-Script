#!/bin/bash

# TTFB Direct Testing Script - Shell Version
# Compatible with Debian, RedHat, Alpine Linux
# 直连TTFB延迟测试脚本 - Shell版本

set -e

# 脚本配置
SCRIPT_VERSION="1.0"
SCRIPT_NAME="TTFB Direct Test"

# 默认配置
DEFAULT_TESTS=5
DEFAULT_TIMEOUT=10
DEFAULT_DELAY=0.5
DEFAULT_WORKERS=4
DEFAULT_USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

# 默认测试URL列表 - 稳定端点避免CDN/重定向
DEFAULT_URLS=(
    "https://www.google.com/generate_204"
    "https://github.com/robots.txt"
    "https://fast.com/robots.txt"
    "https://www.spotify.com/robots.txt"
    "https://www.disneyplus.com/robots.txt"
    "https://www.facebook.com/robots.txt"
    "https://x.com/robots.txt"
    "https://www.instagram.com/robots.txt"
    "https://www.tiktok.com/robots.txt"
    "https://www.youtube.com/generate_204"
    "https://www.twitch.tv/robots.txt"
    "https://www.pornhub.com/robots.txt"
    "https://www.apple.com/library/test/success.html"
    "https://store.steampowered.com/favicon.ico"
    "https://connectivity.office.com/"
    "https://web.telegram.org/favicon.ico"
    "https://www.reddit.com/robots.txt"
    "https://discord.com/robots.txt"
    "https://api.openai.com/v1/chat/completions"
    "https://api.anthropic.com/v1/messages"
)

# 性能阈值 (毫秒) - 更新为标准参考值
EXCELLENT_THRESHOLD=200
GOOD_THRESHOLD=350
AVERAGE_THRESHOLD=500
BELOW_AVERAGE_THRESHOLD=700

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# URL到HOST名称映射函数 (兼容bash 3.2)
get_display_name() {
    local url="$1"
    case "$url" in
        "https://www.google.com/generate_204") echo "Google" ;;
        "https://github.com/robots.txt") echo "GitHub" ;;
        "https://fast.com/robots.txt") echo "Netflix" ;;
        "https://www.spotify.com/robots.txt") echo "Spotify" ;;
        "https://www.disneyplus.com/robots.txt") echo "Disney" ;;
        "https://www.facebook.com/robots.txt") echo "Facebook" ;;
        "https://x.com/robots.txt") echo "X/Twitter" ;;
        "https://www.instagram.com/robots.txt") echo "Instagram" ;;
        "https://www.tiktok.com/robots.txt") echo "TikTok" ;;
        "https://www.youtube.com/generate_204") echo "YouTube" ;;
        "https://www.twitch.tv/robots.txt") echo "Twitch" ;;
        "https://www.pornhub.com/robots.txt") echo "Pornhub" ;;
        "https://www.apple.com/library/test/success.html") echo "Apple" ;;
        "https://store.steampowered.com/favicon.ico") echo "Steam" ;;
        "https://connectivity.office.com/") echo "Office" ;;
        "https://web.telegram.org/favicon.ico") echo "Telegram" ;;
        "https://www.reddit.com/robots.txt") echo "Reddit" ;;
        "https://discord.com/robots.txt") echo "Discord" ;;
        "https://api.openai.com/v1/chat/completions") echo "OpenAI(API)" ;;
        "https://api.anthropic.com/v1/messages") echo "Claude(API)" ;;
        *) echo "$url" | sed -E 's|^https?://||' | cut -d'/' -f1 ;;
    esac
}

# 强制回源URL映射函数 (错误路径)
get_origin_url() {
    local url="$1"
    # 生成4-6位随机数
    local random_suffix=$(shuf -i 1000-999999 -n 1 2>/dev/null || echo $((RANDOM % 899999 + 100000)))
    # 生成时间戳避免404缓存
    local timestamp=$(date +%s%N | cut -b1-13)
    
    case "$url" in
        "https://www.google.com/generate_204") echo "https://www.google.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://github.com/robots.txt") echo "https://github.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://fast.com/robots.txt") echo "https://fast.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://www.spotify.com/robots.txt") echo "https://www.spotify.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://www.disneyplus.com/robots.txt") echo "https://www.disneyplus.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://www.facebook.com/robots.txt") echo "https://www.facebook.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://x.com/robots.txt") echo "https://x.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://www.instagram.com/robots.txt") echo "https://www.instagram.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://www.tiktok.com/robots.txt") echo "https://www.tiktok.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://www.youtube.com/generate_204") echo "https://www.youtube.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://www.twitch.tv/robots.txt") echo "https://www.twitch.tv/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://www.pornhub.com/robots.txt") echo "https://www.pornhub.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://www.apple.com/library/test/success.html") echo "https://www.apple.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://store.steampowered.com/favicon.ico") echo "https://store.steampowered.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://connectivity.office.com/") echo "https://connectivity.office.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://web.telegram.org/favicon.ico") echo "https://web.telegram.org/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://www.reddit.com/robots.txt") echo "https://www.reddit.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://discord.com/robots.txt") echo "https://discord.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://api.openai.com/v1/chat/completions") echo "https://api.openai.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        "https://api.anthropic.com/v1/messages") echo "https://api.anthropic.com/invalidpath${random_suffix}?_hb=${timestamp}" ;;
        *) echo "" ;;  # 未知URL返回空
    esac
}

# 语言设置
LANG_CODE="zh_CN"  # 默认简体中文

# 语言选择函数
choose_language() {
    echo "Choose language / 选择语言:"
    echo "1. 简体中文 (默认)"
    echo "2. English"
    echo
    echo -n "Please select (按回车键使用简体中文): "
    read -r choice
    
    case "$choice" in
        "2"|"en"|"english"|"English") 
            LANG_CODE="en_US"
            echo "Language set to English."
            ;;
        *) 
            LANG_CODE="zh_CN"
            echo "语言设置为简体中文。"
            ;;
    esac
    echo
}

# 文本翻译函数
get_text() {
    local key="$1"
    case "$LANG_CODE:$key" in
        "zh_CN:title") echo "TTFB Direct Test v1.0 - Shell版本" ;;
        "en_US:title") echo "TTFB Direct Test v1.0 - Shell Edition" ;;
        
        "zh_CN:test_config") echo "测试配置:" ;;
        "en_US:test_config") echo "Test Configuration:" ;;
        
        "zh_CN:url_count") echo "URL数量" ;;
        "en_US:url_count") echo "URL Count" ;;
        
        "zh_CN:tests_per_url") echo "每URL测试次数" ;;
        "en_US:tests_per_url") echo "Tests per URL" ;;
        
        "zh_CN:timeout") echo "超时时间" ;;
        "en_US:timeout") echo "Timeout" ;;
        
        "zh_CN:concurrency") echo "并发数" ;;
        "en_US:concurrency") echo "Concurrency" ;;
        
        "zh_CN:interval") echo "测试间隔" ;;
        "en_US:interval") echo "Test Interval" ;;
        
        "zh_CN:system") echo "系统" ;;
        "en_US:system") echo "System" ;;
        
        "zh_CN:concurrent_testing") echo "开始并发测试" ;;
        "en_US:concurrent_testing") echo "Starting concurrent testing" ;;
        
        "zh_CN:progress") echo "进度" ;;
        "en_US:progress") echo "Progress" ;;
        
        "zh_CN:results_title") echo "TTFB延迟测试结果 (TTFB = DNS + 连接 + TLS + 服务器首字节响应时间)" ;;
        "en_US:results_title") echo "TTFB Latency Test Results (TTFB = DNS + Connect + TLS + Server First Byte Response Time)" ;;
        
        "zh_CN:test_details") echo "📊 测试结果详情:" ;;
        "en_US:test_details") echo "📊 Test Result Details:" ;;
        
        "zh_CN:performance_summary") echo "🎯 性能摘要 (视觉指示):" ;;
        "en_US:performance_summary") echo "🎯 Performance Summary (Visual Indicators):" ;;
        
        "zh_CN:overall_stats") echo "📊 总体统计:" ;;
        "en_US:overall_stats") echo "📊 Overall Statistics:" ;;
        
        "zh_CN:test_url_count") echo "测试URL数" ;;
        "en_US:test_url_count") echo "Test URL Count" ;;
        
        "zh_CN:successful_tests") echo "成功测试" ;;
        "en_US:successful_tests") echo "Successful Tests" ;;
        
        "zh_CN:avg_dns") echo "平均DNS解析" ;;
        "en_US:avg_dns") echo "Average DNS Resolution" ;;
        
        "zh_CN:avg_connect") echo "平均连接时间" ;;
        "en_US:avg_connect") echo "Average Connection Time" ;;
        
        "zh_CN:avg_tls") echo "平均TLS握手" ;;
        "en_US:avg_tls") echo "Average TLS Handshake" ;;
        
        "zh_CN:avg_ttfb") echo "平均TTFB" ;;
        "en_US:avg_ttfb") echo "Average TTFB" ;;
        
        "zh_CN:performance_levels") echo "📈 TTFB性能分级 (标准参考):" ;;
        "en_US:performance_levels") echo "📈 TTFB Performance Levels (Standard Reference):" ;;
        
        "zh_CN:excellent") echo "优秀" ;;
        "en_US:excellent") echo "Excellent" ;;
        
        "zh_CN:good") echo "良好" ;;
        "en_US:good") echo "Good" ;;
        
        "zh_CN:average") echo "一般" ;;
        "en_US:average") echo "Average" ;;
        
        "zh_CN:below_average") echo "中等偏下" ;;
        "en_US:below_average") echo "Below Average" ;;
        
        "zh_CN:poor") echo "差" ;;
        "en_US:poor") echo "Poor" ;;
        
        "zh_CN:total_time") echo "总测试时间" ;;
        "en_US:total_time") echo "Total Test Time" ;;
        
        "zh_CN:seconds") echo "秒" ;;
        "en_US:seconds") echo "seconds" ;;
        
        "zh_CN:metrics_explanation") echo "📋 指标说明:" ;;
        "en_US:metrics_explanation") echo "📋 Metrics Explanation:" ;;
        
        "zh_CN:help_note") echo "包含DNS解析时间测量，可帮助诊断网络问题" ;;
        "en_US:help_note") echo "Includes DNS resolution time measurement to help diagnose network issues" ;;
        
        "zh_CN:count_unit") echo "个" ;;
        "en_US:count_unit") echo "items" ;;
        
        "zh_CN:table_header_main") echo "主机\t状态\t协议\tDNS(ms)\t连接(ms)\tTLS(ms)\tTTFB(ms)\t回源(ms)" ;;
        "en_US:table_header_main") echo "HOST\tSTATUS\tHTTP\tDNS(ms)\tCONNECT(ms)\tTLS(ms)\tTTFB(ms)\tORIGIN(ms)" ;;
        
        "zh_CN:table_header_summary") echo "主机\t状态\tTTFB\t等级" ;;
        "en_US:table_header_summary") echo "HOST\tSTATUS\tTTFB\tLEVEL" ;;
        
        *) echo "$key" ;;
    esac
}

# 全局变量
VERBOSE=false
JSON_OUTPUT=false
JSON_FILE="ttfb_results.json"
MARKDOWN_OUTPUT=false
SHOW_PROGRESS=true
SHOW_ALL=false
TEMP_DIR="/tmp/ttfb_$$"
TEST_URLS=()
NUM_TESTS=$DEFAULT_TESTS
TIMEOUT=$DEFAULT_TIMEOUT
DELAY=$DEFAULT_DELAY
WORKERS=$DEFAULT_WORKERS

# 系统检测 - 增强多发行版支持
detect_system() {
    # 检测操作系统
    case "$(uname -s)" in
        "Darwin")
            OS="macos"
            OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
            ;;
        "Linux")
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                # 标准化OS名称以便依赖检查使用
                case "$ID" in
                    "ubuntu"|"debian"|"linuxmint"|"pop")
                        OS="$ID"
                        ;;
                    "rhel"|"centos"|"fedora"|"rocky"|"almalinux"|"ol")
                        OS="$ID"
                        ;;
                    "alpine")
                        OS="alpine"
                        ;;
                    "arch"|"manjaro"|"endeavouros")
                        OS="$ID"
                        ;;
                    "opensuse"|"opensuse-leap"|"opensuse-tumbleweed"|"sles")
                        OS="opensuse"
                        ;;
                    *)
                        # 尝试从ID_LIKE中推断
                        if echo "$ID_LIKE" | grep -q "debian"; then
                            OS="debian"
                        elif echo "$ID_LIKE" | grep -q "rhel\|fedora"; then
                            OS="fedora"
                        elif echo "$ID_LIKE" | grep -q "arch"; then
                            OS="arch"
                        else
                            OS="$ID"
                        fi
                        ;;
                esac
                OS_VERSION="$VERSION_ID"
            elif [ -f /etc/redhat-release ]; then
                OS="rhel"
                OS_VERSION=$(cat /etc/redhat-release | sed -E 's/.*release ([0-9]+).*/\1/' 2>/dev/null || echo "unknown")
            elif [ -f /etc/alpine-release ]; then
                OS="alpine"
                OS_VERSION=$(cat /etc/alpine-release 2>/dev/null || echo "unknown")
            else
                OS="linux"
                OS_VERSION="unknown"
            fi
            ;;
        *)
            OS="unknown"
            OS_VERSION="unknown"
            ;;
    esac
    
    # 检测架构
    ARCH=$(uname -m)
    
    # 检测shell类型
    SHELL_TYPE=$(ps -p $$ -o comm= 2>/dev/null | sed 's/^-//' || echo "bash")
    
    if [ "$VERBOSE" = true ]; then
        echo "系统信息: $OS $OS_VERSION ($ARCH, $SHELL_TYPE)"
    fi
}

# 检测column工具的正确包名
detect_column_package() {
    local os="$1"
    case "$os" in
        "debian"|"ubuntu")
            # 根据用户提供的精确方案，按照新到旧的包依赖顺序
            # util-linux -> bsdextrautils -> bsdmainutils
            echo "util-linux bsdextrautils bsdmainutils"
            ;;
        *)
            echo "util-linux"
            ;;
    esac
}

# 检查必需工具
check_dependencies() {
    local missing_tools=()
    local missing_packages=()
    
    # 检查curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_tools+=("curl")
        missing_packages+=("curl")
    fi
    
    
    # 检查bc (计算)
    if ! command -v bc >/dev/null 2>&1; then
        missing_tools+=("bc")
        missing_packages+=("bc")
    fi
    
    # 检查column (表格格式化)
    if ! command -v column >/dev/null 2>&1; then
        missing_tools+=("column")
        local column_packages
        column_packages=$(detect_column_package "$OS")
        # 对于Debian/Ubuntu，添加所有候选包到missing_packages
        if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
            for pkg in $column_packages; do
                missing_packages+=("$pkg")
            done
        else
            missing_packages+=("$column_packages")
        fi
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}错误: 缺少必需工具: ${missing_tools[*]}${NC}" >&2
        echo
        
        # 提供自动安装选项
        local auto_install=false
        if [ "$OS" != "macos" ] && [ "$EUID" != "0" ] && (command -v sudo >/dev/null 2>&1 || command -v doas >/dev/null 2>&1); then
            echo -n -e "${YELLOW}是否尝试自动安装缺失的依赖？ [Y/n]: ${NC}"
            read -r reply
            if [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]; then
                auto_install=true
            fi
        elif [ "$EUID" = "0" ]; then
            echo -n -e "${YELLOW}是否尝试自动安装缺失的依赖？ [Y/n]: ${NC}"
            read -r reply
            if [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]; then
                auto_install=true
            fi
        fi
        
        if [ "$auto_install" = true ]; then
            echo
            echo "尝试自动安装依赖..."
            
            local install_success=true
            local sudo_cmd=""
            
            # 确定权限提升命令
            if [ "$EUID" != "0" ]; then
                if command -v sudo >/dev/null 2>&1; then
                    sudo_cmd="sudo"
                elif command -v doas >/dev/null 2>&1; then
                    sudo_cmd="doas"
                else
                    echo -e "${RED}错误: 需要root权限，但未找到sudo或doas命令${NC}" >&2
                    install_success=false
                fi
            fi
            
            if [ "$install_success" = true ]; then
                case "$OS" in
                    "debian"|"ubuntu")
                        echo "更新包列表..."
                        if ! ${sudo_cmd} apt-get update; then
                            echo -e "${RED}包列表更新失败${NC}" >&2
                            install_success=false
                        else
                            # 首先安装非column相关的包
                            local non_column_packages=()
                            local column_packages=()
                            
                            for pkg in "${missing_packages[@]}"; do
                                if [[ "$pkg" =~ ^(util-linux|bsdextrautils|bsdmainutils)$ ]]; then
                                    column_packages+=("$pkg")
                                else
                                    non_column_packages+=("$pkg")
                                fi
                            done
                            
                            # 先安装非column包
                            if [ ${#non_column_packages[@]} -gt 0 ]; then
                                echo "安装基础依赖包: ${non_column_packages[*]}"
                                ${sudo_cmd} apt-get install -y "${non_column_packages[@]}" || true
                            fi
                            
                            # 实施用户提供的一键修复方案 (按新到旧顺序尝试column包)
                            if ! command -v column >/dev/null 2>&1; then
                                echo "按照优先级顺序安装column工具..."
                                echo "尝试安装 util-linux (Debian 12/13+ 首选)..."
                                ${sudo_cmd} apt-get install -y util-linux || true
                                
                                # 验证安装结果
                                if ! command -v column >/dev/null 2>&1; then
                                    echo "尝试安装 bsdextrautils (Debian 11/12/13 常见)..."
                                    ${sudo_cmd} apt-get install -y bsdextrautils || true
                                fi
                                
                                # 再次验证
                                if ! command -v column >/dev/null 2>&1; then
                                    echo "尝试安装 bsdmainutils (Debian 10 及更早版本)..."
                                    ${sudo_cmd} apt-get install -y bsdmainutils || true
                                fi
                                
                                # 最终验证
                                if command -v column >/dev/null 2>&1; then
                                    echo -e "${GREEN}column 工具安装成功！${NC}"
                                    which column && column --version 2>/dev/null || echo "column 已安装但无版本信息"
                                else
                                    echo -e "${RED}column 工具安装失败，请手动安装${NC}" >&2
                                fi
                            fi
                            
                            # 检查是否还有缺失的工具
                            local still_missing=()
                            for tool in curl bc column; do
                                if ! command -v "$tool" >/dev/null 2>&1; then
                                    still_missing+=("$tool")
                                fi
                            done
                            if [ ${#still_missing[@]} -gt 0 ]; then
                                install_success=false
                            fi
                        fi
                        ;;
                    "rhel"|"centos"|"fedora"|"rocky"|"almalinux")
                        # 检查是否使用dnf或yum
                        local pkg_mgr=""
                        if command -v dnf >/dev/null 2>&1; then
                            pkg_mgr="dnf"
                        elif command -v yum >/dev/null 2>&1; then
                            pkg_mgr="yum"
                        else
                            echo -e "${RED}错误: 未找到dnf或yum包管理器${NC}" >&2
                            install_success=false
                        fi
                        
                        if [ -n "$pkg_mgr" ]; then
                            echo "使用 $pkg_mgr 安装依赖包: ${missing_packages[*]}"
                            if ! ${sudo_cmd} "$pkg_mgr" install -y "${missing_packages[@]}"; then
                                echo -e "${RED}包安装失败${NC}" >&2
                                install_success=false
                            fi
                        fi
                        ;;
                    "alpine")
                        echo "安装依赖包: ${missing_packages[*]}"
                        if ! ${sudo_cmd} apk add "${missing_packages[@]}"; then
                            echo -e "${RED}包安装失败${NC}" >&2
                            install_success=false
                        fi
                        ;;
                    "arch"|"manjaro")
                        echo "安装依赖包: ${missing_packages[*]}"
                        if ! ${sudo_cmd} pacman -S --noconfirm "${missing_packages[@]}"; then
                            echo -e "${RED}包安装失败${NC}" >&2
                            install_success=false
                        fi
                        ;;
                    *)
                        echo -e "${RED}不支持的操作系统自动安装: $OS${NC}" >&2
                        install_success=false
                        ;;
                esac
            fi
            
            if [ "$install_success" = true ]; then
                echo -e "${GREEN}依赖安装成功！${NC}"
                echo
                # 重新检查所有工具
                local remaining_missing=()
                if ! command -v curl >/dev/null 2>&1; then
                    remaining_missing+=("curl")
                fi
                if ! command -v bc >/dev/null 2>&1; then
                    remaining_missing+=("bc")
                fi
                if ! command -v column >/dev/null 2>&1; then
                    remaining_missing+=("column")
                fi
                
                if [ ${#remaining_missing[@]} -gt 0 ]; then
                    echo -e "${YELLOW}警告: 仍有工具缺失: ${remaining_missing[*]}${NC}" >&2
                    echo "请手动安装这些工具后重新运行脚本。"
                    exit 1
                else
                    echo -e "${GREEN}所有依赖工具已就绪！${NC}"
                    return 0
                fi
            else
                echo -e "${RED}自动安装失败，请手动安装${NC}" >&2
            fi
        fi
        
        # 显示手动安装指令
        echo
        echo "手动安装建议:"
        case "$OS" in
            "debian"|"ubuntu")
                echo -e "${BLUE}  # Debian/Ubuntu 一键修复方案 (按新到旧依次尝试):${NC}"
                echo "  sudo apt-get update"
                echo "  sudo apt-get install -y util-linux        # Debian 12/13+ 首选"
                echo "  command -v column >/dev/null || sudo apt-get install -y bsdextrautils   # Debian 11/12/13 常见"
                echo "  command -v column >/dev/null || sudo apt-get install -y bsdmainutils    # Debian 10 及更早"
                echo "  # 验证安装:"
                echo "  which column && column --version"
                echo
                echo -e "${BLUE}  # 其他必需依赖:${NC}"
                echo "  sudo apt-get install -y curl bc"
                ;;
            "rhel"|"centos"|"fedora"|"rocky"|"almalinux")
                echo -e "${BLUE}  # RHEL/CentOS/Fedora/Rocky/AlmaLinux:${NC}"
                if command -v dnf >/dev/null 2>&1; then
                    echo "  sudo dnf install curl bc util-linux"
                else
                    echo "  sudo yum install curl bc util-linux"
                fi
                ;;
            "alpine")
                echo -e "${BLUE}  # Alpine Linux:${NC}"
                echo "  sudo apk add curl bc util-linux"
                ;;
            "arch"|"manjaro")
                echo -e "${BLUE}  # Arch Linux/Manjaro:${NC}"
                echo "  sudo pacman -S curl bc util-linux"
                ;;
            "macos")
                echo -e "${BLUE}  # macOS:${NC}"
                echo "  # 使用 Homebrew:"
                echo "  brew install curl bc util-linux"
                echo
                echo "  # 使用 MacPorts:"
                echo "  sudo port install curl bc util-linux"
                ;;
            *)
                echo -e "${BLUE}  # 通用指令:${NC}"
                echo "  请安装: curl, bc, column"
                echo "  这些工具通常在以下包中:"
                echo "  - curl: curl"
                echo "  - bc: bc"
                echo "  - column: bsdextrautils/bsdmainutils/util-linux"
                ;;
        esac
        echo
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

用法: $0 [选项] [URL...]

选项:
  -h, --help          显示此帮助信息
  -v, --verbose       详细输出模式
  -a, --all           显示完整结果表格 (默认只显示核心信息)
  -j, --json          输出JSON格式结果
  -m, --markdown      输出Markdown格式结果
  -o, --output FILE   JSON输出文件名 (默认: $JSON_FILE)
  -n, --num-tests N   每URL测试次数 (默认: $DEFAULT_TESTS)
  -t, --timeout N     超时秒数 (默认: $DEFAULT_TIMEOUT)
  -d, --delay N       测试间隔秒数 (默认: $DEFAULT_DELAY)
  -w, --workers N     并发数 (默认: $DEFAULT_WORKERS)
  --no-progress       不显示进度条

示例:
  $0                                    # 使用默认URL列表，简洁显示
  $0 -a                                 # 显示完整表格信息
  $0 -m                                 # 输出Markdown格式
  $0 https://www.google.com             # 测试单个URL
  $0 -v -j -n 3 https://www.github.com # 详细输出,JSON格式,测试3次
  $0 -a -m --no-progress --timeout 5   # 完整信息,Markdown格式,无进度条,5秒超时

默认测试网站 (${#DEFAULT_URLS[@]}个):
EOF
    for i in "${!DEFAULT_URLS[@]}"; do
        printf "  %2d. %s\n" $((i+1)) "${DEFAULT_URLS[$i]}"
    done
}


# 单个URL详细测试
test_single_url() {
    local url="$1"
    local test_id="$2"
    local hostname display_name
    local results_file="$TEMP_DIR/result_${test_id}"
    local times_file="$TEMP_DIR/times_${test_id}"
    local errors=0
    local total_ttfb=0 total_origin_ttfb=0
    local dns_times=()
    local connect_times=()
    local tls_times=()
    local ttfb_times=()
    local origin_ttfb_times=()
    local status_codes=()
    
    # 获取显示名称
    display_name="$(get_display_name "$url")"
    
    # 提取主机名
    hostname=$(echo "$url" | sed -E 's|^https?://||' | cut -d'/' -f1)
    
    # 注意: times_file 只在有成功测试时才创建
    
    if [ "$VERBOSE" = true ]; then
        echo "  开始测试: $hostname"
    fi
    
    # 执行多次测试 (正常URL + 强制回源URL)
    for i in $(seq 1 $NUM_TESTS); do
        local timing_result origin_timing_result
        
        # 1. 测试正常URL (可能使用CDN缓存)
        timing_result=$(curl -w '%{time_namelookup}|%{time_connect}|%{time_appconnect}|%{time_pretransfer}|%{time_starttransfer}|%{http_code}|%{http_version}' \
                            -o /dev/null \
                            -s \
                            --max-time "$TIMEOUT" \
                            -H "User-Agent: $DEFAULT_USER_AGENT" \
                            --compressed \
                            -H "Accept-Language: en-US,en;q=0.8" \
                            "$url" 2>/dev/null)
        
        # 2. 测试错误路径强制回源URL (避免CDN缓存)
        local origin_url="$(get_origin_url "$url")"
        if [ -n "$origin_url" ]; then
            origin_timing_result=$(curl -w '%{time_namelookup}|%{time_connect}|%{time_appconnect}|%{time_pretransfer}|%{time_starttransfer}|%{http_code}|%{http_version}' \
                                -o /dev/null \
                                -s \
                                --max-time "$TIMEOUT" \
                                -H "User-Agent: $DEFAULT_USER_AGENT" \
                                --compressed \
                                -H "Accept-Language: en-US,en;q=0.8" \
                                "$origin_url" 2>/dev/null)
        fi
        
        if [ -n "$timing_result" ] && [ "$timing_result" != "0000000" ]; then
            # 解析计时结果
            local dns_time connect_time tls_time pretransfer_time starttransfer_time http_code http_version
            
            dns_time=$(echo "$timing_result" | cut -d'|' -f1)
            connect_time=$(echo "$timing_result" | cut -d'|' -f2) 
            tls_time=$(echo "$timing_result" | cut -d'|' -f3)
            pretransfer_time=$(echo "$timing_result" | cut -d'|' -f4)
            starttransfer_time=$(echo "$timing_result" | cut -d'|' -f5)
            http_code=$(echo "$timing_result" | cut -d'|' -f6)
            http_version=$(echo "$timing_result" | cut -d'|' -f7)
            
            # 正确计算各个时间段 (根据curl文档和用户参考数据)
            local dns_ms connect_ms tls_ms actual_ttfb
            
            # DNS时间: time_namelookup (纯DNS解析时间)
            dns_ms=$(echo "$dns_time * 1000" | bc)
            
            # TCP连接时间: time_connect - time_namelookup (TCP握手时间，不包括DNS)
            connect_ms=$(echo "($connect_time - $dns_time) * 1000" | bc)
            
            # TLS握手时间: time_appconnect - time_connect (TLS握手时间，不包括DNS和TCP)
            if [ "$tls_time" != "0.000000" ] && [ "$tls_time" != "0" ]; then
                tls_ms=$(echo "($tls_time - $connect_time) * 1000" | bc)
            else
                tls_ms="0"
            fi
            
            # TTFB: time_starttransfer (从请求开始到收到第一个字节的总时间)
            # 这包括: DNS + TCP连接 + TLS握手 + 服务器处理时间
            actual_ttfb=$(echo "$starttransfer_time * 1000" | bc)
            
            # 验证HTTP状态码
            if [ "$http_code" -ge 100 ] && [ "$http_code" -lt 600 ]; then
                dns_times+=("$dns_ms")
                connect_times+=("$connect_ms")
                tls_times+=("$tls_ms")
                ttfb_times+=("$actual_ttfb")
                status_codes+=("$http_code")
                total_ttfb=$(echo "$total_ttfb + $actual_ttfb" | bc)
                
                # 处理强制回源测试结果
                local origin_ttfb="N/A"
                if [ -n "$origin_timing_result" ] && [ "$origin_timing_result" != "0000000" ]; then
                    local origin_starttransfer=$(echo "$origin_timing_result" | cut -d'|' -f5)
                    local origin_http_code=$(echo "$origin_timing_result" | cut -d'|' -f6)
                    
                    # 只关心TTFB时间，不管状态码(404是预期的)
                    if [ "$origin_starttransfer" != "0.000000" ] && [ "$origin_starttransfer" != "0" ]; then
                        origin_ttfb=$(echo "$origin_starttransfer * 1000" | bc)
                        origin_ttfb_times+=("$origin_ttfb")
                        total_origin_ttfb=$(echo "$total_origin_ttfb + $origin_ttfb" | bc)
                    fi
                fi
                
                if [ "$VERBOSE" = true ]; then
                    printf "    测试 %d/%d: DNS:%.0fms 连接:%.0fms TLS:%.0fms TTFB:%.0fms 回源:%.0fms [%s]\n" \
                           "$i" "$NUM_TESTS" "$dns_ms" "$connect_ms" "$tls_ms" "$actual_ttfb" "$origin_ttfb" "$http_code"
                fi
            else
                errors=$((errors + 1))
                if [ "$VERBOSE" = true ]; then
                    echo "    测试 $i/$NUM_TESTS: 失败 (状态码: $http_code)"
                fi
            fi
        else
            errors=$((errors + 1))
            if [ "$VERBOSE" = true ]; then
                echo "    测试 $i/$NUM_TESTS: 失败 (连接错误)"
            fi
        fi
        
        # 测试间隔
        if [ "$i" -lt "$NUM_TESTS" ] && [ "$DELAY" != "0" ]; then
            sleep "$DELAY"
        fi
    done
    
    # 计算统计信息
    local successful_tests=${#ttfb_times[@]}
    
    if [ "$successful_tests" -gt 0 ]; then
        # 计算各项平均值
        local avg_dns avg_connect avg_tls avg_ttfb
        local total_dns=0 total_connect=0 total_tls=0
        
        for dns in "${dns_times[@]}"; do
            total_dns=$(echo "$total_dns + $dns" | bc)
        done
        
        for conn in "${connect_times[@]}"; do
            total_connect=$(echo "$total_connect + $conn" | bc)
        done
        
        for tls in "${tls_times[@]}"; do
            total_tls=$(echo "$total_tls + $tls" | bc)
        done
        
        avg_dns=$(echo "scale=1; $total_dns / $successful_tests" | bc)
        avg_connect=$(echo "scale=1; $total_connect / $successful_tests" | bc)
        avg_tls=$(echo "scale=1; $total_tls / $successful_tests" | bc)
        avg_ttfb=$(echo "scale=1; $total_ttfb / $successful_tests" | bc)
        
        # 计算强制回源平均TTFB
        local avg_origin_ttfb="N/A"
        local successful_origin_tests=${#origin_ttfb_times[@]}
        if [ "$successful_origin_tests" -gt 0 ]; then
            avg_origin_ttfb=$(echo "scale=1; $total_origin_ttfb / $successful_origin_tests" | bc)
        fi
        
        # 获取最常见的HTTP状态码和版本
        local status_code http_ver
        status_code=$(printf '%s\n' "${status_codes[@]}" | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
        
        # 获取HTTP版本 (取第一个成功测试的版本)
        if [ ${#ttfb_times[@]} -gt 0 ]; then
            http_ver="$http_version"  # 使用最后一个成功测试的版本
        else
            http_ver="N/A"
        fi
        
        # 计算TTFB统计
        local min_ttfb max_ttfb median_ttfb stdev_ttfb
        
        # 将TTFB时间写入临时文件用于计算统计值 - 修复macOS兼容性
        if [ ${#ttfb_times[@]} -gt 0 ]; then
            # 确保临时文件目录存在
            mkdir -p "$(dirname "$times_file")"
            printf '%s\n' "${ttfb_times[@]}" > "$times_file"
            
            min_ttfb=$(printf '%s\n' "${ttfb_times[@]}" | sort -n | head -1)
            max_ttfb=$(printf '%s\n' "${ttfb_times[@]}" | sort -n | tail -1)
        else
            # 如果没有成功的测试，创建空的times_file并设置默认值
            mkdir -p "$(dirname "$times_file")"
            touch "$times_file"
            min_ttfb="0"
            max_ttfb="0"
        fi
        
        # 中位数计算
        if [ ${#ttfb_times[@]} -gt 0 ]; then
            if [ $((successful_tests % 2)) -eq 1 ]; then
                median_ttfb=$(printf '%s\n' "${ttfb_times[@]}" | sort -n | sed -n "$((successful_tests / 2 + 1))p")
            else
                local mid1 mid2
                mid1=$(printf '%s\n' "${ttfb_times[@]}" | sort -n | sed -n "$((successful_tests / 2))p")
                mid2=$(printf '%s\n' "${ttfb_times[@]}" | sort -n | sed -n "$((successful_tests / 2 + 1))p")
                median_ttfb=$(echo "scale=1; ($mid1 + $mid2) / 2" | bc)
            fi
            
            # 标准差计算
            local variance=0
            for ttfb in "${ttfb_times[@]}"; do
                variance=$(echo "$variance + ($ttfb - $avg_ttfb)^2" | bc)
            done
            stdev_ttfb=$(echo "scale=1; sqrt($variance / $successful_tests)" | bc -l)
        else
            # 如果没有成功的测试，设置默认值
            median_ttfb="0"
            stdev_ttfb="0"
        fi
        
        # 写入结果
        cat > "$results_file" << EOF
url="$url"
hostname="$hostname"
display_name="$display_name"
status_code="$status_code"
http_version="$http_ver"
tests="$successful_tests"
errors="$errors"
avg_dns="$avg_dns"
avg_connect="$avg_connect" 
avg_tls="$avg_tls"
avg_ttfb="$avg_ttfb"
avg_origin_ttfb="$avg_origin_ttfb"
min_ttfb="$min_ttfb"
max_ttfb="$max_ttfb"
median_ttfb="$median_ttfb"
stdev_ttfb="$stdev_ttfb"
all_ttfb_times="$(IFS=,; echo "${ttfb_times[*]}")"
all_origin_ttfb_times="$(IFS=,; echo "${origin_ttfb_times[*]}")"
timestamp="$(date -Iseconds)"
EOF
    else
        # 全部失败的情况
        cat > "$results_file" << EOF
url="$url"
hostname="$hostname"
display_name="$display_name"
status_code="000"
tests="0"
errors="$errors"
avg_dns="0"
avg_connect="0"
avg_tls="0"
avg_ttfb=""
avg_origin_ttfb="N/A"
timestamp="$(date -Iseconds)"
EOF
    fi
}

# 并发测试执行器 - 修复macOS兼容性
run_concurrent_tests() {
    local pids=()
    local active_jobs=0
    local completed=0
    local total=${#TEST_URLS[@]}
    local job_counter=0
    
    mkdir -p "$TEMP_DIR"
    
    echo "$(get_text "concurrent_testing") ($(get_text "concurrency"): $WORKERS)..."
    
    for i in "${!TEST_URLS[@]}"; do
        # 控制并发数量 - 修复macOS wait兼容性
        while [ $active_jobs -ge $WORKERS ]; do
            # macOS兼容的等待策略
            local finished_jobs=0
            local new_pids=()
            
            for pid in "${pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    new_pids+=("$pid")
                else
                    # 进程已完成
                    wait "$pid" 2>/dev/null || true
                    finished_jobs=$((finished_jobs + 1))
                fi
            done
            
            pids=("${new_pids[@]}")
            active_jobs=${#pids[@]}
            completed=$((completed + finished_jobs))
            
            if [ "$SHOW_PROGRESS" = true ]; then
                printf "\r进度: %d/%d (%.1f%%)" $completed $total $(echo "scale=1; $completed * 100 / $total" | bc)
            fi
            
            # 如果没有进程完成，稍等片刻再检查
            if [ $finished_jobs -eq 0 ]; then
                sleep 0.1
            fi
        done
        
        # 启动新的测试任务
        test_single_url "${TEST_URLS[$i]}" "$i" &
        pids+=("$!")
        active_jobs=$((active_jobs + 1))
        job_counter=$((job_counter + 1))
    done
    
    # 等待所有剩余任务完成 - 更安全的等待策略
    while [ ${#pids[@]} -gt 0 ]; do
        local finished_jobs=0
        local new_pids=()
        
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                new_pids+=("$pid")
            else
                # 进程已完成
                wait "$pid" 2>/dev/null || true
                finished_jobs=$((finished_jobs + 1))
            fi
        done
        
        pids=("${new_pids[@]}")
        completed=$((completed + finished_jobs))
        
        if [ "$SHOW_PROGRESS" = true ]; then
            printf "\r进度: %d/%d (%.1f%%)" $completed $total $(echo "scale=1; $completed * 100 / $total" | bc)
        fi
        
        # 如果还有进程在运行，稍等片刻再检查
        if [ ${#pids[@]} -gt 0 ]; then
            sleep 0.1
        fi
    done
    
    if [ "$SHOW_PROGRESS" = true ]; then
        echo # 新行
    fi
}


# 使用TSV格式生成完美对齐的表格
generate_tsv_table() {
    local table_data="$1"
    # 使用column命令实现完美的列对齐
    echo "$table_data" | column -t -s $'\t'
}

# ANSI颜色辅助函数
strip_ansi() {
    sed -E 's/\x1B\[[0-9;]*[mK]//g'
}

# 为特定单元格添加背景色（仅用于状态指示器）
format_status_indicator() {
    local status="$1"
    local status_class=$((status / 100))
    
    case $status_class in
        2)  echo "✅" ;;    # 2xx Success
        3)  echo "🔄" ;;    # 3xx Redirect  
        4|5) echo "❌" ;;   # 4xx/5xx Error
        *) echo "❓" ;;     # Others
    esac
}

# 为TTFB添加性能指示器
# 获取性能等级彩球
get_performance_text() {
    local ttfb="$1"
    local ttfb_int
    ttfb_int=$(printf "%.0f" "$ttfb")
    
    if [ "$ttfb_int" -le $EXCELLENT_THRESHOLD ]; then
        echo "🟢"
    elif [ "$ttfb_int" -le $GOOD_THRESHOLD ]; then
        echo "🟡"
    elif [ "$ttfb_int" -le $AVERAGE_THRESHOLD ]; then
        echo "🟠"
    elif [ "$ttfb_int" -le $BELOW_AVERAGE_THRESHOLD ]; then
        echo "🔴"
    else
        echo "🟣"
    fi
}

format_ttfb_indicator() {
    local ttfb="$1"
    local ttfb_int
    
    ttfb_int=$(printf "%.0f" "$ttfb")
    
    if [ "$ttfb_int" -le $EXCELLENT_THRESHOLD ]; then
        echo "🟢"    # 优秀: 绿色圆点
    elif [ "$ttfb_int" -le $GOOD_THRESHOLD ]; then
        echo "🟡"    # 良好: 黄色圆点
    elif [ "$ttfb_int" -le $AVERAGE_THRESHOLD ]; then
        echo "🟠"    # 一般: 橙色圆点
    elif [ "$ttfb_int" -le $BELOW_AVERAGE_THRESHOLD ]; then
        echo "🔴"    # 中等偏下: 红色圆点
    else
        echo "🟣"    # 差: 紫色圆点
    fi
}

# Markdown输出功能函数

# 获取性能等级彩球 (复用并适配现有函数)
get_performance_emoji() {
    local ttfb="$1"
    local ttfb_int
    ttfb_int=$(printf "%.0f" "$ttfb")
    
    if [ "$ttfb_int" -le $EXCELLENT_THRESHOLD ]; then
        echo "🟢"
    elif [ "$ttfb_int" -le $GOOD_THRESHOLD ]; then
        echo "🟡"
    elif [ "$ttfb_int" -le $AVERAGE_THRESHOLD ]; then
        echo "🟠"
    elif [ "$ttfb_int" -le $BELOW_AVERAGE_THRESHOLD ]; then
        echo "🔴"
    else
        echo "🟣"
    fi
}

# 获取状态指示器 (复用现有函数逻辑)
get_status_indicator() {
    format_status_indicator "$1"
}

# 生成Markdown格式的详细测试结果表格
generate_markdown_detailed_table() {
    local sorted_results="$1"
    
    if [ "$LANG_CODE" = "zh_CN" ]; then
        echo "## 📊 测试结果详情"
    else
        echo "## 📊 Test Result Details"
    fi
    echo ""
    if [ "$LANG_CODE" = "zh_CN" ]; then
        echo "| 主机 | 状态 | 协议 | DNS(ms) | 连接(ms) | TLS(ms) | TTFB(ms) | 回源(ms) |"
    else
        echo "| HOST | STATUS | HTTP | DNS(ms) | CONNECT(ms) | TLS(ms) | TTFB(ms) | ORIGIN(ms) |"
    fi
    echo "|------|------|------|---------|----------|---------|----------|----------|"
    
    while read -r result_file; do
        if [ -f "$result_file" ] && [ -s "$result_file" ]; then
            # 清空变量
            unset url hostname display_name status_code http_version avg_dns avg_connect avg_tls avg_ttfb avg_origin_ttfb tests errors
            # 加载变量
            if ! . "$result_file" 2>/dev/null; then
                continue
            fi
            
            # 验证必要字段
            if [ -z "$hostname" ] || [ -z "$avg_ttfb" ] || [ "$avg_ttfb" = "" ]; then
                continue
            fi
            
            # 格式化数值
            local dns_str=$(printf "%.0f" "$avg_dns")
            local connect_str=$(printf "%.0f" "$avg_connect")
            local tls_str=$(printf "%.0f" "$avg_tls")
            local ttfb_str=$(printf "%.0f" "$avg_ttfb")
            
            # 格式化回源TTFB
            local origin_str
            if [ "$avg_origin_ttfb" = "N/A" ] || [ -z "$avg_origin_ttfb" ]; then
                origin_str="N/A"
            else
                origin_str=$(printf "%.0f" "$avg_origin_ttfb")
            fi
            
            local host_display="${display_name:-$hostname}"
            
            echo "| $host_display | $status_code | ${http_version:-N/A} | $dns_str | $connect_str | $tls_str | $ttfb_str | $origin_str |"
        fi
    done <<< "$sorted_results"
    
    echo ""
}

# 生成Markdown格式的性能摘要表格
generate_markdown_summary_table() {
    local sorted_results="$1"
    
    if [ "$LANG_CODE" = "zh_CN" ]; then
        echo "## 🎯 性能摘要"
    else
        echo "## 🎯 Performance Summary"
    fi
    echo ""
    if [ "$LANG_CODE" = "zh_CN" ]; then
        echo "| 主机 | 状态 | TTFB | 等级 |"
    else
        echo "| HOST | STATUS | TTFB | LEVEL |"
    fi
    echo "|------|------|------|------|"
    
    while read -r result_file; do
        if [ -f "$result_file" ] && [ -s "$result_file" ]; then
            # 清空变量
            unset url hostname display_name status_code http_version avg_dns avg_connect avg_tls avg_ttfb avg_origin_ttfb tests errors
            # 加载变量
            if ! . "$result_file" 2>/dev/null; then
                continue
            fi
            
            # 验证必要字段
            if [ -z "$hostname" ] || [ -z "$avg_ttfb" ] || [ "$avg_ttfb" = "" ]; then
                continue
            fi
            
            # 获取指示器
            local status_indicator=$(get_status_indicator "$status_code")
            local performance_emoji=$(get_performance_emoji "$avg_ttfb")
            local ttfb_str=$(printf "%.0f" "$avg_ttfb")
            local host_display="${display_name:-$hostname}"
            
            echo "| $host_display | ${status_indicator}$status_code | ${ttfb_str}ms | $performance_emoji |"
        fi
    done <<< "$sorted_results"
    
    echo ""
}

# 生成Markdown格式的总体统计
generate_markdown_statistics() {
    local sorted_results="$1"
    local successful_count="$2"
    local total_ttfb="$3"
    local total_dns="$4"
    local total_connect="$5"
    local total_tls="$6"
    
    if [ "$LANG_CODE" = "zh_CN" ]; then
        echo "## 📊 总体统计"
    else
        echo "## 📊 Overall Statistics"
    fi
    echo ""
    
    if [ $successful_count -gt 0 ]; then
        local avg_dns=$(echo "scale=1; $total_dns / $successful_count" | bc)
        local avg_connect=$(echo "scale=1; $total_connect / $successful_count" | bc)
        local avg_tls=$(echo "scale=1; $total_tls / $successful_count" | bc)
        local avg_ttfb_overall=$(echo "scale=1; $total_ttfb / $successful_count" | bc)
        
        if [ "$LANG_CODE" = "zh_CN" ]; then
            echo "- 🎯 **测试URL数**: ${#TEST_URLS[@]}"
            echo "- ✅ **成功测试**: $successful_count"
            echo "- 🌐 **平均DNS解析**: ${avg_dns}ms"
            echo "- 🔗 **平均连接时间**: ${avg_connect}ms"
            echo "- 🔒 **平均TLS握手**: ${avg_tls}ms"
            echo "- ⚡ **平均TTFB**: ${avg_ttfb_overall}ms"
        else
            echo "- 🎯 **Test URL Count**: ${#TEST_URLS[@]}"
            echo "- ✅ **Successful Tests**: $successful_count"
            echo "- 🌐 **Average DNS Resolution**: ${avg_dns}ms"
            echo "- 🔗 **Average Connection Time**: ${avg_connect}ms"
            echo "- 🔒 **Average TLS Handshake**: ${avg_tls}ms"
            echo "- ⚡ **Average TTFB**: ${avg_ttfb_overall}ms"
        fi
    fi
    
    echo ""
    
    # 性能分级统计
    local excellent=0 good=0 average=0 below_average=0 poor=0
    
    while read -r result_file; do
        if [ -f "$result_file" ] && [ -s "$result_file" ]; then
            unset avg_ttfb
            if . "$result_file" 2>/dev/null && [ -n "$avg_ttfb" ] && [ "$avg_ttfb" != "" ]; then
                local ttfb_int=$(printf "%.0f" "$avg_ttfb")
                if [ "$ttfb_int" -le $EXCELLENT_THRESHOLD ]; then
                    excellent=$((excellent + 1))
                elif [ "$ttfb_int" -le $GOOD_THRESHOLD ]; then
                    good=$((good + 1))
                elif [ "$ttfb_int" -le $AVERAGE_THRESHOLD ]; then
                    average=$((average + 1))
                elif [ "$ttfb_int" -le $BELOW_AVERAGE_THRESHOLD ]; then
                    below_average=$((below_average + 1))
                else
                    poor=$((poor + 1))
                fi
            fi
        fi
    done <<< "$sorted_results"
    
    if [ "$LANG_CODE" = "zh_CN" ]; then
        echo "## 📈 TTFB性能分级"
        echo ""
        echo "| 等级 | 阈值 | 数量 | 指示器 |"
        echo "|------|------|------|--------|"
        echo "| 优秀 | ≤${EXCELLENT_THRESHOLD}ms | $excellent | 🟢 |"
        echo "| 良好 | ${EXCELLENT_THRESHOLD}-${GOOD_THRESHOLD}ms | $good | 🟡 |"
        echo "| 一般 | ${GOOD_THRESHOLD}-${AVERAGE_THRESHOLD}ms | $average | 🟠 |"
        echo "| 中等偏下 | ${AVERAGE_THRESHOLD}-${BELOW_AVERAGE_THRESHOLD}ms | $below_average | 🔴 |"
        echo "| 差 | >${BELOW_AVERAGE_THRESHOLD}ms | $poor | 🟣 |"
    else
        echo "## 📈 TTFB Performance Levels"
        echo ""
        echo "| Level | Threshold | Count | Indicator |"
        echo "|-------|-----------|-------|-----------|"
        echo "| Excellent | ≤${EXCELLENT_THRESHOLD}ms | $excellent | 🟢 |"
        echo "| Good | ${EXCELLENT_THRESHOLD}-${GOOD_THRESHOLD}ms | $good | 🟡 |"
        echo "| Average | ${GOOD_THRESHOLD}-${AVERAGE_THRESHOLD}ms | $average | 🟠 |"
        echo "| Below Average | ${AVERAGE_THRESHOLD}-${BELOW_AVERAGE_THRESHOLD}ms | $below_average | 🔴 |"
        echo "| Poor | >${BELOW_AVERAGE_THRESHOLD}ms | $poor | 🟣 |"
    fi
    echo ""
}

# 显示测试结果
display_results() {
    # 如果输出markdown格式，不清屏
    if [ "$MARKDOWN_OUTPUT" = false ]; then
        # 清屏
        clear
    fi
    
    # 如果不是markdown输出，显示普通格式的标题
    if [ "$MARKDOWN_OUTPUT" = false ]; then
        echo "================================================================================"
        echo "$(get_text "results_title")"
        echo "================================================================================"
    fi
    
    # 读取所有结果
    local results=()
    local successful=()
    local failed=()
    
    for i in "${!TEST_URLS[@]}"; do
        local result_file="$TEMP_DIR/result_$i"
        if [ -f "$result_file" ] && [ -s "$result_file" ]; then
            results+=("$result_file")
            
            # 检查是否成功 - 加强校验
            local avg_ttfb
            avg_ttfb=$(grep "^avg_ttfb=" "$result_file" 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "")
            if [ -n "$avg_ttfb" ] && [ "$avg_ttfb" != "" ] && [ "$avg_ttfb" != "0" ]; then
                successful+=("$result_file")
            else
                failed+=("$result_file")
            fi
        else
            # 结果文件不存在或为空，记录为失败
            if [ -n "${TEST_URLS[$i]}" ]; then
                local hostname
                hostname=$(echo "${TEST_URLS[$i]}" | sed -E 's|^https?://||' | cut -d'/' -f1)
                echo "警告: 未找到 ${hostname} 的测试结果文件: $result_file" >&2
            fi
        fi
    done
    
    if [ ${#successful[@]} -gt 0 ]; then
        # 按平均TTFB排序
        local sorted_results
        sorted_results=$(for file in "${successful[@]}"; do
            avg_ttfb=$(grep "^avg_ttfb=" "$file" 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "0")
            echo "$avg_ttfb $file"
        done | sort -n | cut -d' ' -f2-)
        
        # 如果是markdown输出，使用不同的处理逻辑
        if [ "$MARKDOWN_OUTPUT" = true ]; then
            # 输出markdown格式
            if [ "$LANG_CODE" = "zh_CN" ]; then
                echo "# TTFB 延迟测试报告"
                echo ""
                echo "_测试时间: $(date '+%Y-%m-%d %H:%M:%S')_"
            else
                echo "# TTFB Latency Test Report"
                echo ""
                echo "_Test Time: $(date '+%Y-%m-%d %H:%M:%S')_"
            fi
            echo ""
            
            # 计算统计数据
            local total_ttfb=0
            local total_dns=0
            local total_connect=0
            local total_tls=0
            local count=0
            
            while read -r result_file; do
                if [ -f "$result_file" ] && [ -s "$result_file" ]; then
                    unset url hostname display_name status_code http_version avg_dns avg_connect avg_tls avg_ttfb avg_origin_ttfb tests errors
                    if . "$result_file" 2>/dev/null; then
                        if [ -n "$hostname" ] && [ -n "$avg_ttfb" ] && [ "$avg_ttfb" != "" ]; then
                            total_ttfb=$(echo "$total_ttfb + $avg_ttfb" | bc 2>/dev/null || echo "$total_ttfb")
                            total_dns=$(echo "$total_dns + $avg_dns" | bc 2>/dev/null || echo "$total_dns")
                            total_connect=$(echo "$total_connect + $avg_connect" | bc 2>/dev/null || echo "$total_connect")
                            total_tls=$(echo "$total_tls + $avg_tls" | bc 2>/dev/null || echo "$total_tls")
                            count=$((count + 1))
                        fi
                    fi
                fi
            done <<< "$sorted_results"
            
            # 根据SHOW_ALL决定是否显示详细表格
            if [ "$SHOW_ALL" = true ]; then
                generate_markdown_detailed_table "$sorted_results"
            fi
            
            # 始终显示摘要表格
            generate_markdown_summary_table "$sorted_results"
            
            # 显示统计信息
            generate_markdown_statistics "$sorted_results" "$count" "$total_ttfb" "$total_dns" "$total_connect" "$total_tls"
            
            echo "---"
            echo ""
            if [ "$LANG_CODE" = "zh_CN" ]; then
                echo "**说明**: TTFB = DNS解析时间 + TCP连接时间 + TLS握手时间 + 服务器首字节响应时间"
            else
                echo "**Note**: TTFB = DNS resolution time + TCP connection time + TLS handshake time + Server first byte response time"
            fi
            
            # markdown模式下不显示后续的普通格式内容
            return
        fi
        
        # 显示结果和统计（用于计算总体数据）
        local total_ttfb=0
        local total_dns=0
        local total_connect=0
        local total_tls=0
        local count=0
        
        # 如果使用-a参数，显示详细测试结果表格
        if [ "$SHOW_ALL" = true ]; then
            echo
            echo "$(get_text "test_details")"
            echo
            
            # 生成TSV数据
            local tsv_data
            tsv_data="$(get_text "table_header_main")\n"
        fi
        
        while read -r result_file; do
            if [ -f "$result_file" ] && [ -s "$result_file" ]; then
                # 清空变量
                unset url hostname display_name status_code http_version avg_dns avg_connect avg_tls avg_ttfb avg_origin_ttfb tests errors
                # 加载变量 - 加强错误处理
                if ! . "$result_file" 2>/dev/null; then
                    echo "警告: 无法加载结果文件: $result_file" >&2
                    continue
                fi
                
                # 验证必要字段
                if [ -z "$hostname" ] || [ -z "$avg_ttfb" ] || [ "$avg_ttfb" = "" ]; then
                    echo "警告: 结果文件数据不完整: $result_file" >&2
                    continue
                fi
                
                # 格式化数值（保留0位小数）
                local dns_str connect_str tls_str ttfb_str origin_ttfb_str host_display
                dns_str=$(printf "%.0f" "$avg_dns")
                connect_str=$(printf "%.0f" "$avg_connect") 
                tls_str=$(printf "%.0f" "$avg_tls")
                ttfb_str=$(printf "%.0f" "$avg_ttfb")
                
                # 格式化回源TTFB
                if [ "$avg_origin_ttfb" = "N/A" ] || [ -z "$avg_origin_ttfb" ]; then
                    origin_ttfb_str="N/A"
                else
                    origin_ttfb_str=$(printf "%.0f" "$avg_origin_ttfb")
                fi
                
                # 使用简化的显示名称
                host_display="${display_name:-$hostname}"
                
                # 只有在SHOW_ALL=true时才添加TSV行数据
                if [ "$SHOW_ALL" = true ]; then
                    tsv_data+="${host_display}\t${status_code}\t${http_version:-N/A}\t${dns_str}\t${connect_str}\t${tls_str}\t${ttfb_str}\t${origin_ttfb_str}\n"
                fi
                
                # 统计 - 防止bc计算错误
                total_ttfb=$(echo "$total_ttfb + $avg_ttfb" | bc 2>/dev/null || echo "$total_ttfb")
                total_dns=$(echo "$total_dns + $avg_dns" | bc 2>/dev/null || echo "$total_dns")
                total_connect=$(echo "$total_connect + $avg_connect" | bc 2>/dev/null || echo "$total_connect")
                total_tls=$(echo "$total_tls + $avg_tls" | bc 2>/dev/null || echo "$total_tls")
                count=$((count + 1))
            fi
        done <<< "$sorted_results"
        
        # 只有在SHOW_ALL=true时才显示详细表格
        if [ "$SHOW_ALL" = true ]; then
            # 使用column命令生成完美对齐的表格
            printf "%b" "$tsv_data" | column -t -s $'\t'
        fi
        
        # 性能摘要表格（使用TSV + column方式生成）
        echo
        echo
        echo "$(get_text "performance_summary")"
        echo
        
        # 生成摘要TSV数据
        local summary_tsv="$(get_text "table_header_summary")\n"
        
        while read -r result_file; do
            if [ -f "$result_file" ] && [ -s "$result_file" ]; then
                # 清空变量
                unset url hostname display_name status_code http_version avg_dns avg_connect avg_tls avg_ttfb tests errors
                # 加载变量
                if ! . "$result_file" 2>/dev/null; then
                    continue
                fi
                
                # 验证必要字段
                if [ -z "$hostname" ] || [ -z "$avg_ttfb" ] || [ "$avg_ttfb" = "" ]; then
                    continue
                fi
                
                # 确定指示符
                local ttfb_int ttfb_indicator status_indicator
                ttfb_int=$(printf "%.0f" "$avg_ttfb")
                
                # 获取指示符
                status_indicator=$(format_status_indicator "$status_code")
                ttfb_indicator=$(format_ttfb_indicator "$avg_ttfb")
                performance_text=$(get_performance_text "$avg_ttfb")
                
                # 添加摘要行到TSV (使用简化显示名称和性能文字)
                local host_display="${display_name:-$hostname}"
                summary_tsv+="${host_display}\t${status_indicator}${status_code}\t${ttfb_int}ms\t${performance_text}\n"
            fi
        done <<< "$sorted_results"
        
        # 显示摘要表格
        printf "%b" "$summary_tsv" | column -t -s $'\t'
        
        # 总体统计
        if [ $count -gt 0 ]; then
            local overall_ttfb overall_dns overall_connect overall_tls
            overall_ttfb=$(echo "scale=1; $total_ttfb / $count" | bc)
            overall_dns=$(echo "scale=1; $total_dns / $count" | bc)
            overall_connect=$(echo "scale=1; $total_connect / $count" | bc)
            overall_tls=$(echo "scale=1; $total_tls / $count" | bc)
            
            echo
            echo "$(get_text "overall_stats")"
            echo "  🎯 $(get_text "test_url_count"): ${#TEST_URLS[@]}"
            echo "  ✅ $(get_text "successful_tests"): $count"
            echo "  🌐 $(get_text "avg_dns"): ${overall_dns}ms"
            echo "  🔗 $(get_text "avg_connect"): ${overall_connect}ms"
            echo "  🔒 $(get_text "avg_tls"): ${overall_tls}ms"
            echo "  ⚡ $(get_text "avg_ttfb"): ${overall_ttfb}ms"
        fi
        
        # TTFB性能分级 - 更新为5级分类系统
        local excellent_count=0 good_count=0 average_count=0 below_avg_count=0 poor_count=0
        while read -r result_file; do
            if [ -f "$result_file" ] && [ -s "$result_file" ]; then
                unset avg_ttfb
                if . "$result_file" 2>/dev/null && [ -n "$avg_ttfb" ] && [ "$avg_ttfb" != "" ]; then
                    local ttfb_int
                    ttfb_int=$(printf "%.0f" "$avg_ttfb" 2>/dev/null || echo "0")
                    
                    if [ "$ttfb_int" -le $EXCELLENT_THRESHOLD ]; then
                        excellent_count=$((excellent_count + 1))
                    elif [ "$ttfb_int" -le $GOOD_THRESHOLD ]; then
                        good_count=$((good_count + 1))
                    elif [ "$ttfb_int" -le $AVERAGE_THRESHOLD ]; then
                        average_count=$((average_count + 1))
                    elif [ "$ttfb_int" -le $BELOW_AVERAGE_THRESHOLD ]; then
                        below_avg_count=$((below_avg_count + 1))
                    else
                        poor_count=$((poor_count + 1))
                    fi
                fi
            fi
        done <<< "$sorted_results"
        
        echo
        echo "$(get_text "performance_levels")"
        echo "  🟢 $(get_text "excellent") (≤${EXCELLENT_THRESHOLD}ms): $excellent_count $(get_text "count_unit")"
        echo "  🟡 $(get_text "good") (${EXCELLENT_THRESHOLD}-${GOOD_THRESHOLD}ms): $good_count $(get_text "count_unit")"
        echo "  🟠 $(get_text "average") (${GOOD_THRESHOLD}-${AVERAGE_THRESHOLD}ms): $average_count $(get_text "count_unit")"
        echo "  🔴 $(get_text "below_average") (${AVERAGE_THRESHOLD}-${BELOW_AVERAGE_THRESHOLD}ms): $below_avg_count $(get_text "count_unit")"
        echo "  🟣 $(get_text "poor") (>${BELOW_AVERAGE_THRESHOLD}ms): $poor_count $(get_text "count_unit")"
        
        # 添加指标说明
        echo
        echo "$(get_text "metrics_explanation")"
        if [ "$LANG_CODE" = "zh_CN" ]; then
            echo "  Status    HTTP状态码"
            echo "  DNS       DNS查询时间"
            echo "  Connect   TCP连接时间"
            echo "  TLS       TLS握手时间"
            echo "  TTFB      首字节响应时间"
            echo "  ORIGIN    强制回源TTFB"
        else
            echo "  Status    HTTP Status Code"
            echo "  DNS       DNS Lookup Time"
            echo "  Connect   TCP Connect Time"
            echo "  TLS       TLS Handshake Time"
            echo "  TTFB      Time to First Byte"
            echo "  ORIGIN    Forced Origin TTFB"
        fi
    fi
    
    # 失败的测试 (仅在非markdown模式下显示)
    if [ "$MARKDOWN_OUTPUT" = false ] && [ ${#failed[@]} -gt 0 ]; then
        echo
        echo "❌ 失败的测试 (${#failed[@]} 个):"
        for result_file in "${failed[@]}"; do
            if [ -f "$result_file" ] && [ -s "$result_file" ]; then
                unset hostname errors url
                if . "$result_file" 2>/dev/null; then
                    echo "  ✗ ${hostname:-未知主机} (错误次数: ${errors:-未知})"
                else
                    echo "  ✗ 未知主机 (结果文件损坏)"
                fi
            fi
        done
    fi
}

# 生成JSON输出
generate_json_output() {
    if [ "$JSON_OUTPUT" = false ]; then
        return
    fi
    
    local json_content='{'
    json_content+='"test_info":{'
    json_content+='"timestamp":"'$(date -Iseconds)'",'
    json_content+='"test_settings":{'
    json_content+='"num_tests":'$NUM_TESTS','
    json_content+='"timeout":'$TIMEOUT','
    json_content+='"delay_between_tests":'$DELAY','
    json_content+='"concurrent_workers":'$WORKERS
    json_content+='},'
    json_content+='"total_urls":'${#TEST_URLS[@]}','
    
    # 计算成功测试数量
    local successful_count=0
    for i in "${!TEST_URLS[@]}"; do
        local result_file="$TEMP_DIR/result_$i"
        if [ -f "$result_file" ]; then
            local avg_ttfb
            avg_ttfb=$(grep "^avg_ttfb=" "$result_file" 2>/dev/null | cut -d'=' -f2 || echo "")
            if [ -n "$avg_ttfb" ]; then
                successful_count=$((successful_count + 1))
            fi
        fi
    done
    
    json_content+='"successful_tests":'$successful_count
    json_content+='},'
    json_content+='"results":['
    
    local first=true
    for i in "${!TEST_URLS[@]}"; do
        local result_file="$TEMP_DIR/result_$i"
        if [ -f "$result_file" ]; then
            if [ "$first" = false ]; then
                json_content+=','
            fi
            first=false
            
            . "$result_file"
            
            json_content+='{'
            json_content+='"url":"'$url'",'
            json_content+='"hostname":"'$hostname'",'
            json_content+='"http_version":"'${http_version:-N/A}'",'
            json_content+='"status_code":"'$status_code'",'
            json_content+='"avg_dns":'${avg_dns:-0}','
            json_content+='"avg_connect":'${avg_connect:-0}','
            json_content+='"avg_tls":'${avg_tls:-0}','
            json_content+='"tests":'$tests','
            json_content+='"errors":'$errors','
            
            if [ -n "$avg_ttfb" ]; then
                # 将comma-separated字符串转换为JSON数组格式
                local json_array=""
                if [ -n "$all_ttfb_times" ] && [ "$all_ttfb_times" != "N/A" ]; then
                    json_array=$(echo "$all_ttfb_times" | sed 's/,/,/g')
                fi
                
                json_content+='"avg_ttfb":'$avg_ttfb','
                json_content+='"min_ttfb":'$min_ttfb','
                json_content+='"max_ttfb":'$max_ttfb','
                json_content+='"median_ttfb":'$median_ttfb','
                json_content+='"stdev_ttfb":'$stdev_ttfb','
                json_content+='"all_ttfb_times":['$json_array'],'
                
                # 添加回源TTFB时间数组
                local origin_json_array=""
                if [ -n "$all_origin_ttfb_times" ] && [ "$all_origin_ttfb_times" != "N/A" ]; then
                    origin_json_array=$(echo "$all_origin_ttfb_times" | sed 's/,/,/g')
                fi
                json_content+='"all_origin_ttfb_times":['$origin_json_array'],'
            else
                json_content+='"avg_ttfb":null,'
                json_content+='"all_ttfb_times":null,'
                json_content+='"all_origin_ttfb_times":null,'
            fi
            
            json_content+='"timestamp":"'$timestamp'"'
            json_content+='}'
        fi
    done
    
    json_content+=']'
    json_content+='}'
    
    echo "$json_content" > "$JSON_FILE"
    echo "结果已保存到: $JSON_FILE"
}

# 清理临时文件
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# 信号处理
trap cleanup EXIT INT TERM

# 参数解析
parse_arguments() {
    while [ $# -gt 0 ]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            -a|--all)
                SHOW_ALL=true
                ;;
            -j|--json)
                JSON_OUTPUT=true
                ;;
            -m|--markdown)
                MARKDOWN_OUTPUT=true
                ;;
            -o|--output)
                if [ -n "$2" ]; then
                    JSON_FILE="$2"
                    shift
                else
                    echo "错误: --output 需要指定文件名" >&2
                    exit 1
                fi
                ;;
            -n|--num-tests)
                if [ -n "$2" ] && [ "$2" -gt 0 ]; then
                    NUM_TESTS="$2"
                    shift
                else
                    echo "错误: --num-tests 需要正整数" >&2
                    exit 1
                fi
                ;;
            -t|--timeout)
                if [ -n "$2" ] && [ "$2" -gt 0 ]; then
                    TIMEOUT="$2"
                    shift
                else
                    echo "错误: --timeout 需要正数" >&2
                    exit 1
                fi
                ;;
            -d|--delay)
                if [ -n "$2" ]; then
                    DELAY="$2"
                    shift
                else
                    echo "错误: --delay 需要指定数值" >&2
                    exit 1
                fi
                ;;
            -w|--workers)
                if [ -n "$2" ] && [ "$2" -gt 0 ]; then
                    WORKERS="$2"
                    shift
                else
                    echo "错误: --workers 需要正整数" >&2
                    exit 1
                fi
                ;;
            --no-progress)
                SHOW_PROGRESS=false
                ;;
            -*)
                echo "错误: 未知选项 $1" >&2
                echo "使用 --help 查看帮助"
                exit 1
                ;;
            *)
                # URL参数
                TEST_URLS+=("$1")
                ;;
        esac
        shift
    done
    
    # 如果没有指定URL，使用默认列表
    if [ ${#TEST_URLS[@]} -eq 0 ]; then
        TEST_URLS=("${DEFAULT_URLS[@]}")
    fi
}

# 主函数
main() {
    # 语言选择 (仅在交互模式下)
    if [ -t 0 ] && [ $# -eq 0 ]; then
        choose_language
    elif [ -t 0 ]; then
        # 如果有参数但仍然是交互模式，至少设置默认语言
        LANG_CODE="zh_CN"
    fi
    
    echo "================================================================================"
    echo "$(get_text "title")"
    echo "================================================================================"
    
    # 系统检测
    detect_system
    
    # 检查依赖
    check_dependencies
    
    # 解析参数
    parse_arguments "$@"
    
    # 交互式询问是否显示完整测试详情（仅在标准输入是终端且未使用-a参数时）
    if [ -t 0 ] && [ "$SHOW_ALL" = false ]; then
        if [ "$LANG_CODE" = "zh_CN" ]; then
            echo -n "是否显示完整测试详情？[Y/n]: "
        else
            echo -n "Show detailed test results? [Y/n]: "
        fi
        
        read -r reply
        if [[ "$reply" =~ ^[Nn]$ ]]; then
            SHOW_ALL=false
        else
            SHOW_ALL=true
        fi
        echo
    fi
    
    # 交互式询问是否输出markdown格式（仅在标准输入是终端且未使用-m参数时）
    if [ -t 0 ] && [ "$MARKDOWN_OUTPUT" = false ]; then
        if [ "$LANG_CODE" = "zh_CN" ]; then
            echo -n "是否输出markdown格式？[y/N]: "
        else
            echo -n "Output markdown format? [y/N]: "
        fi
        
        read -r reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            MARKDOWN_OUTPUT=true
        else
            MARKDOWN_OUTPUT=false
        fi
        echo
    fi
    
    # 显示测试配置
    echo "$(get_text "test_config")"
    echo "  $(get_text "url_count"): ${#TEST_URLS[@]}"
    echo "  $(get_text "tests_per_url"): $NUM_TESTS"
    echo "  $(get_text "timeout"): ${TIMEOUT}$(get_text "seconds")"
    echo "  $(get_text "concurrency"): $WORKERS"
    echo "  $(get_text "interval"): ${DELAY}$(get_text "seconds")"
    echo "  $(get_text "system"): $OS"
    
    # 记录开始时间
    local start_time
    start_time=$(date +%s)
    
    # 执行测试
    run_concurrent_tests
    
    # 计算总时间
    local end_time total_time
    end_time=$(date +%s)
    total_time=$((end_time - start_time))
    
    # 显示结果
    display_results
    
    # 生成JSON输出
    generate_json_output
    
    # 在非markdown模式下显示测试时间和帮助信息
    if [ "$MARKDOWN_OUTPUT" = false ]; then
        echo
        echo "$(get_text "total_time"): ${total_time}$(get_text "seconds")"
        echo "================================================================================"
        echo "$(get_text "help_note")"
    fi
}

# 执行主函数
main "$@"