#!/bin/bash

# ========== 基础配置 ==========
TOOL_NAME="STACKHUT VPS 工具箱"
VERSION="v0.1"
SHORTCUT="stackhut"

# ========== 颜色 ==========
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[0;31m"
RESET="\033[0m"

# ========== 工具函数 ==========
header() {
  clear
  echo -e "${GREEN}==============================="
  echo -e "  ${TOOL_NAME} ${VERSION}"
  echo -e "  https://github.com/monica1314131/STACKHUT-VPS_TOOLBOX"
  echo -e "===============================${RESET}"
}

pause() {
  read -rp "按回车返回菜单..."
}

# ========== 模块函数 ==========
show_info() {
  echo "系统信息详情"
  echo "------------------------"

  # 主机名
  echo "主机名: $(hostname)"

  # 运营商（通过IP查询在线接口）
  ISP=$(curl -s https://ipinfo.io/org | sed 's/^[0-9]* //')
  echo "运营商: ${ISP:-获取失败}"

  echo "------------------------"

  # 系统版本和内核
  SYS_VER=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
  KERNEL_VER=$(uname -r)
  echo "系统版本: $SYS_VER"
  echo "Linux版本: $KERNEL_VER"

  echo "------------------------"

  # CPU架构型号及核心数
  CPU_ARCH=$(uname -m)
  CPU_MODEL=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^ *//')
  CPU_CORES=$(nproc)
  echo "CPU架构: $CPU_ARCH"
  echo "CPU型号: $CPU_MODEL"
  echo "CPU核心数: $CPU_CORES"

  echo "------------------------"

  # CPU占用（1分钟平均负载 * 100 / 核心数，简易估算）
  CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | sed 's/ //g')
  CPU_PERCENT=$(awk -v load=$CPU_LOAD -v cores=$CPU_CORES 'BEGIN {printf "%.2f", (load/cores)*100}')
  echo "CPU占用: ${CPU_PERCENT}%"

  # 内存占用
  MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
  MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
  MEM_PERCENT=$(awk -v used=$MEM_USED -v total=$MEM_TOTAL 'BEGIN {printf "%.2f", (used/total)*100}')
  echo "物理内存: ${MEM_USED}MB/${MEM_TOTAL}MB (${MEM_PERCENT}%)"

  # 虚拟内存（Swap）
  SWAP_TOTAL=$(free -m | awk '/Swap:/ {print $2}')
  SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
  echo "虚拟内存: ${SWAP_USED}MB/${SWAP_TOTAL}MB (0%)"

  # 硬盘占用（根分区）
  DISK_TOTAL=$(df -BG / | awk 'NR==2 {print $2}')
  DISK_USED=$(df -BG / | awk 'NR==2 {print $3}')
  DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')
  echo "硬盘占用: ${DISK_USED}/${DISK_TOTAL} (${DISK_PERCENT})"

  echo "------------------------"

  # 网络流量统计（需要安装vnstat，示例为当天和累计流量）
  if command -v vnstat &>/dev/null; then
    RX_TODAY=$(vnstat --oneline | cut -d';' -f11)
    TX_TODAY=$(vnstat --oneline | cut -d';' -f12)
    RX_TOTAL=$(vnstat --oneline | cut -d';' -f3)
    TX_TOTAL=$(vnstat --oneline | cut -d';' -f4)
    echo "总接收: $RX_TOTAL"
    echo "总发送: $TX_TOTAL"
  else
    echo "总接收: 未安装vnstat，无法获取"
    echo "总发送: 未安装vnstat，无法获取"
  fi

  echo "------------------------"

  # 网络拥堵算法 (查看BBR或其它TCP拥堵控制)
  if sysctl net.ipv4.tcp_congestion_control &>/dev/null; then
    TCP_CC=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
  else
    TCP_CC="未知"
  fi
  echo "网络拥堵算法: $TCP_CC"

  echo "------------------------"

  # 公网IP
  IPV4=$(curl -s4 https://ipinfo.io/ip)
  IPV6=$(curl -s6 https://ipinfo.io/ip)
  echo "公网IPv4地址: $IPV4"
  echo "公网IPv6地址: ${IPV6:-无}"

  echo "------------------------"

  # 地理位置
  LOC=$(curl -s https://ipinfo.io/city),$(curl -s https://ipinfo.io/country)
  echo "地理位置: ${LOC:-未知}"

  # 系统时间
  echo "系统时间: $(date '+%Y-%m-%d %I:%M %p')"

  echo "------------------------"

  # 系统运行时长
  UPTIME_DAYS=$(uptime -p | sed 's/up //')
  echo "系统运行时长: $UPTIME_DAYS"
}


system_update() {
  echo -e "${BLUE}正在执行系统更新...${RESET}"
  if command -v apt &>/dev/null; then
    apt update && apt upgrade -y
  elif command -v yum &>/dev/null; then
    yum update -y
  elif command -v dnf &>/dev/null; then
    dnf upgrade -y
  else
    echo -e "${RED}不支持的系统包管理器${RESET}"
  fi
}

clean_system() {
  echo -e "${BLUE}正在清理系统缓存...${RESET}"
  apt autoremove -y &>/dev/null
  apt clean &>/dev/null
  echo "✅ 清理完成"
}

components_menu() {
  while true; do
    clear
    echo -e "${GREEN}====== 组件管理（常用工具一键安装） ======${RESET}"
    echo "1) 安装 curl 下载工具"
    echo "2) 安装 wget 下载工具"
    echo "3) 安装 sudo 超级管理"
    echo "4) 安装 socat 通信连接"
    echo "5) 安装 htop 系统监控"
    echo "6) 安装 iftop 网络流量监控"
    echo "7) 安装 unzip ZIP压缩解压工具"
    echo "8) 安装 tar GZ压缩解压工具"
    echo "0) 返回主菜单"
    echo "------------------------------------------"
    read -rp "请选择要安装的工具: " tool_choice

    case $tool_choice in
      1) install_package curl ;;
      2) install_package wget ;;
      3) install_package sudo ;;
      4) install_package socat ;;
      5) install_package htop ;;
      6) install_package iftop ;;
      7) install_package unzip ;;
      8) install_package tar ;;
      0) break ;;
      *) echo -e "${RED}❌ 无效选项，请重新输入${RESET}";;
    esac
    read -rp "按回车继续..."
  done
}


install_package() {
  local package=$1
  echo -e "${COLOR}正在安装 ${package}...${RESET}"
  if command -v apt &>/dev/null; then
    apt update && apt install -y "$package"
  elif command -v yum &>/dev/null; then
    yum install -y "$package"
  elif command -v dnf &>/dev/null; then
    dnf install -y "$package"
  elif command -v apk &>/dev/null; then
    apk add "$package"
  else
    echo -e "${RED}❌ 无法识别系统包管理器${RESET}"
  fi
}


placeholder() {
  echo -e "${YELLOW}此功能暂未实现，敬请期待...${RESET}"
}

update_script() {
  echo -e "${BLUE}正在更新脚本...${RESET}"
  curl -fsSL https://raw.githubusercontent.com/monica1314131/STACKHUT-VPS_TOOLBOX/main/stackhut_tool.sh -o $0 && chmod +x $0 && exec $0
}

# ========== 主菜单循环 ==========
while true; do
  header
  echo -e "${GREEN}可用操作：${RESET}"
  echo " 1) 本机信息"
  echo " 2) 系统更新"
  echo " 3) 系统清理"
  echo " 4) 组件管理"
  echo " 5) BBR管理"
  echo " 6) Docker管理"
  echo " 7) WARP解锁（ChatGPT/Netflix）"
  echo " 8) 面板工具"
  echo " 9) 系统工具"
  echo "10) 节点搭建合集"
  echo "11) 测试脚本合集"
  echo "00) 脚本更新"
  echo "88) 退出脚本"
  echo "----------------------------------"
  read -rp "请输入你的选择: " choice

  case $choice in
    1) show_info; pause;;
    2) system_update; pause;;
    3) clean_system; pause;;
    4) components_menu;;
    5|6|7|8|9|10|11) placeholder; pause;;
    00) update_script; exit;;
    88) echo -e "${GREEN}再见！${RESET}"; exit 0;;
    *) echo -e "${RED}无效选项，请重新输入。${RESET}"; pause;;
  esac

done
