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
  read -rp "\n按回车返回菜单..."
}

# ========== 模块函数 ==========
show_info() {
  echo -e "${BLUE}系统信息概览：${RESET}"
  echo "-----------------------------"
  echo "主机名       : $(hostname)"
  echo "当前用户     : $(whoami)"
  echo "操作系统     : $(uname -o)"
  echo "系统架构     : $(uname -m)"
  echo "内核版本     : $(uname -r)"
  echo "CPU 型号     : $(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^ *//')"
  echo "CPU 核心数   : $(nproc)"
  echo "内存总量     : $(free -h | awk '/Mem/ {print $2}')"
  echo "硬盘总量     : $(df -h / | awk 'NR==2 {print $2}')"
  echo "系统运行时间 : $(uptime -p)"
  echo "当前时间     : $(date)"
  echo "IPv4 地址    : $(hostname -I | awk '{print $1}')"
  echo "-----------------------------"
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
    4|5|6|7|8|9|10|11) placeholder; pause;;
    00) update_script; exit;;
    88) echo -e "${GREEN}再见！${RESET}"; exit 0;;
    *) echo -e "${RED}无效选项，请重新输入。${RESET}"; pause;;
  esac

done
