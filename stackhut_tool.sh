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
iface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1)

if [[ -n "$iface" ]]; then
  rx_bytes=$(cat /sys/class/net/$iface/statistics/rx_bytes)
  tx_bytes=$(cat /sys/class/net/$iface/statistics/tx_bytes)
  rx_gb=$(echo "scale=2; $rx_bytes/1024/1024/1024" | bc)
  tx_gb=$(echo "scale=2; $tx_bytes/1024/1024/1024" | bc)
  echo "总接收: ${rx_gb} GB"
  echo "总发送: ${tx_gb} GB"
else
  echo "总接收: 获取失败"
  echo "总发送: 获取失败"
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

run_fscarmen_warp() {
  wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
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
  echo " 4) 组件管理▶"
  echo " 5) BBR管理▶"
  echo " 6) Docker管理▶"
  echo " 7) WARP 解锁 (Fscarmen脚本)"
  echo " 8) 系统工具▶"
  echo "9) 节点搭建▶"
  echo "10) 测试脚本▶"
  echo "00) 脚本更新"
  echo "88) 退出脚本"
  echo "----------------------------------"
  read -rp "请输入你的选择: " choice

bbr_menu() {
  while true; do
    clear
    echo -e "${GREEN}========= BBR 拥塞控制管理 =========${RESET}"
    echo " 1) 查看当前 BBR 状态"
    echo " 2) 启用 BBR（原版）"
    echo " 3) 启用 BBR Plus"
    echo " 4) 启用 BBR2"
    echo " 5) 启用 Cubic"
    echo " 6) 启用 Reno"
    echo " 7) 启用 Cake"
    echo " 8) 查看可用算法列表"
    echo " 9) 重启网络栈（可选）"
    echo " 0) 返回主菜单"
    echo "------------------------------------"
    read -rp "请输入选项: " bbr_choice

    case $bbr_choice in
      1)
        echo -e "${YELLOW}当前拥塞控制算法:${RESET} $(sysctl net.ipv4.tcp_congestion_control)"
        echo -e "${YELLOW}当前默认队列算法: ${RESET} $(sysctl net.core.default_qdisc)"
        echo -e "${YELLOW}当前内核版本:      ${RESET} $(uname -r)"
        ;;
      2)
        echo -e "${BLUE}正在启用 BBR（原版）...${RESET}"
        modprobe tcp_bbr 2>/dev/null
        echo "tcp_bbr" | tee /etc/modules-load.d/bbr.conf
        sysctl -w net.core.default_qdisc=fq
        sysctl -w net.ipv4.tcp_congestion_control=bbr
        echo -e "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo -e "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
        echo -e "${GREEN}✅ BBR 启用完成${RESET}"
        ;;
      3)
        echo -e "${BLUE}正在启用 BBR Plus（需要 bbrplus 内核）...${RESET}"
        sysctl -w net.ipv4.tcp_congestion_control=bbrplus
        echo "net.ipv4.tcp_congestion_control=bbrplus" >> /etc/sysctl.conf
        sysctl -p
        echo -e "${GREEN}✅ BBR Plus 启用完成${RESET}"
        ;;
      4)
        echo -e "${BLUE}正在启用 BBR2...${RESET}"
        sysctl -w net.core.default_qdisc=fq
        sysctl -w net.ipv4.tcp_congestion_control=bbr2
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr2" >> /etc/sysctl.conf
        sysctl -p
        echo -e "${GREEN}✅ BBR2 启用完成${RESET}"
        ;;
      5)
        echo -e "${BLUE}切换为 Cubic 算法（默认）...${RESET}"
        sysctl -w net.ipv4.tcp_congestion_control=cubic
        echo "net.ipv4.tcp_congestion_control=cubic" >> /etc/sysctl.conf
        sysctl -p
        ;;
      6)
        echo -e "${BLUE}切换为 Reno 算法...${RESET}"
        sysctl -w net.ipv4.tcp_congestion_control=reno
        echo "net.ipv4.tcp_congestion_control=reno" >> /etc/sysctl.conf
        sysctl -p
        ;;
      7)
        echo -e "${BLUE}启用 Cake 队列算法（高级路由用）...${RESET}"
        modprobe sch_cake 2>/dev/null
        sysctl -w net.core.default_qdisc=cake
        echo "net.core.default_qdisc=cake" >> /etc/sysctl.conf
        sysctl -p
        ;;
      8)
        echo -e "${YELLOW}系统支持的算法列表:${RESET}"
        sysctl net.ipv4.tcp_available_congestion_control
        ;;
      9)
        echo -e "${BLUE}重启网络栈中...${RESET}"
        systemctl restart networking 2>/dev/null || echo "⚠️ 重启失败，请手动重启或重启系统"
        ;;
      0)
        break
        ;;
      *)
        echo -e "${RED}无效选项，请重新输入${RESET}"
        ;;
    esac
    read -rp "按回车继续..."
  done
}
  docker_menu() {
  while true; do
    clear
    echo -e "${GREEN}====== Docker 管理 ======${RESET}"
    echo "1) 安装 Docker"
    echo "2) 卸载 Docker"
    echo "3) 查看 Docker 状态"
    echo "4) 启动 Docker"
    echo "5) 停止 Docker"
    echo "6) 重启 Docker"
    echo "7) 清理无用容器和镜像"
    echo "0) 返回主菜单"
    echo "---------------------------"
    read -rp "请选择操作: " docker_choice

    case $docker_choice in
      1)
        echo -e "${BLUE}正在安装 Docker...${RESET}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker
        systemctl start docker
        ;;
      2)
        echo -e "${YELLOW}卸载 Docker...${RESET}"
        systemctl stop docker
        apt remove -y docker docker-engine docker.io containerd runc
        ;;
      3)
        echo -e "${BLUE}Docker 状态:${RESET}"
        systemctl status docker
        ;;
      4)
        echo -e "${BLUE}启动 Docker...${RESET}"
        systemctl start docker
        ;;
      5)
        echo -e "${YELLOW}停止 Docker...${RESET}"
        systemctl stop docker
        ;;
      6)
        echo -e "${BLUE}重启 Docker...${RESET}"
        systemctl restart docker
        ;;
      7)
        echo -e "${YELLOW}清理无用容器/镜像...${RESET}"
        docker system prune -af
        ;;
      0)
        break
        ;;
      *)
        echo -e "${RED}❌ 无效选项，请重新输入${RESET}"
        ;;
    esac
    read -rp "按回车继续..."
  done
}

system_tools_menu() {
  while true; do
    clear
    echo -e "${GREEN}▶ 系统工具${RESET}"
    echo "------------------------"
    echo " 1. 修改ROOT密码               2. 开启ROOT密码登录"
    echo " 3. 禁用修改ROOT密码           4. 开放所有端口"
    echo " 5. 修改SSH连接端口            6. 优化DNS地址"
    echo " 7. 禁用ROOT账户创建新账户     8. 切换优先IPv4/IPv6"
    echo " 9. 查看端口占用状态           10. 修改虚拟内存大小"
    echo "11. 用户/密码生成器            12. 用户管理"
    echo "13. 防火墙高级管理器           14. iptables一键转发"
    echo "15. 修改主机名                 16. 切换系统更新源"
    echo "17. 定时任务管理               18. IP端口开放扫描"
    echo "19. 服务器资源限制"
    echo "------------------------"
    echo " 0. 返回主菜单"
    echo "------------------------"
    read -rp "请输入选项编号: " tool_option

    case $tool_option in
      1) change_root_password ;;
      2) enable_root_login ;;
      3) disable_root_password_change ;;
      4) open_all_ports ;;
      5) change_ssh_port ;;
      6) optimize_dns ;;
      7) disable_root_create ;;
      8) toggle_ipv4_ipv6 ;;
      9) check_port_usage ;;
      10) modify_swap ;;
      11) user_password_generator ;;
      12) user_manage ;;
      13) firewall_manager ;;
      14) iptables_forward ;;
      15) change_hostname ;;
      16) switch_mirror ;;
      17) crontab_manager ;;
      18) scan_open_ports ;;
      19) system_limits ;;
      0) break ;;
      *) echo -e "${RED}❌ 无效选项，请重新输入${RESET}" ;;
    esac

    read -rp "按回车继续..."
  done
}

# 所有系统工具功能函数定义（占位模板）

change_root_password() {
  echo "修改 ROOT 密码..."
  passwd root
}

enable_root_login() {
  echo "启用 SSH 登录密码..."
  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  systemctl restart sshd
  echo "已启用 ROOT 登录密码"
}

disable_root_password_change() {
  echo "禁用 ROOT 密码修改权限..."
  chattr +i /etc/shadow
  echo "已设置 /etc/shadow 为不可变"
}

open_all_ports() {
  echo "开放所有端口 (iptables)..."
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -F
  echo "已开放所有端口"
}

change_ssh_port() {
  read -rp "请输入新的SSH端口: " new_port
  sed -i "/^#*Port /c\\Port $new_port" /etc/ssh/sshd_config
  systemctl restart sshd
  echo "SSH端口已改为 $new_port"
}

optimize_dns() {
  echo "正在优化 DNS 设置..."
  echo "nameserver 8.8.8.8" > /etc/resolv.conf
  echo "nameserver 1.1.1.1" >> /etc/resolv.conf
  echo "DNS 已优化"
}

disable_root_create() {
  echo "禁用 ROOT 创建账户功能..."
  chattr +i /etc/passwd /etc/shadow
  echo "已设置系统用户配置为不可更改"
}

toggle_ipv4_ipv6() {
  echo "切换 IPv4/IPv6 优先级..."
  echo -e "1) IPv4 优先\n2) IPv6 优先"
  read -rp "选择: " net_choice
  case $net_choice in
    1)
      echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
      echo "已设置为 IPv4 优先"
      ;;
    2)
      sed -i '/^precedence ::ffff:0:0\/96/d' /etc/gai.conf
      echo "已设置为 IPv6 优先"
      ;;
  esac
}

check_port_usage() {
  echo "当前端口占用:"
  ss -tunlp
}

modify_swap() {
  read -rp "输入新的Swap大小（单位MB）: " swap_size
  swapoff -a
  dd if=/dev/zero of=/swapfile bs=1M count=$swap_size
  mkswap /swapfile
  chmod 600 /swapfile
  swapon /swapfile
  echo "Swap设置完成: ${swap_size}MB"
}

user_password_generator() {
  username="user_$(date +%s)"
  password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
  useradd -m "$username"
  echo "$username:$password" | chpasswd
  echo "创建用户: $username"
  echo "密码: $password"
}

user_manage() {
  echo "当前用户列表:"
  cut -d: -f1 /etc/passwd
}

firewall_manager() {
  echo "进入防火墙高级管理器...（占位）"
  # 这里可以调用更复杂的 iptables/nftables 管理界面
}

iptables_forward() {
  echo 1 > /proc/sys/net/ipv4/ip_forward
  echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
  sysctl -p
  echo "已开启转发功能"
}

change_hostname() {
  read -rp "请输入新的主机名: " new_hostname
  hostnamectl set-hostname "$new_hostname"
  echo "主机名已更改为 $new_hostname"
}

switch_mirror() {
  echo "切换为中科大源..."
  if [[ -f /etc/apt/sources.list ]]; then
    sed -i 's@http.*archive.ubuntu.com@https://mirrors.ustc.edu.cn@' /etc/apt/sources.list
    apt update
  fi
  echo "更新源完成"
}

crontab_manager() {
  echo "当前定时任务:"
  crontab -l
  echo "编辑中..."
  crontab -e
}

scan_open_ports() {
  echo "请输入要扫描的IP: "
  read target_ip
  echo "正在扫描..."
  for port in {1..100}; do
    (echo >/dev/tcp/$target_ip/$port) >/dev/null 2>&1 && echo "端口 $port 开放"
  done
  echo "扫描完成"
}

system_limits() {
  echo "当前资源限制:"
  ulimit -a
  echo "建议修改 /etc/security/limits.conf 配置文件手动设置更高级限制。"
}


  case $choice in
    1) show_info; pause;;
    2) system_update; pause;;
    3) clean_system; pause;;
    4) components_menu;;
    5) bbr_menu;;
    6) docker_menu ;;
    7) run_fscarmen_warp ;;
    8) system_tools_menu ;;
    9|10|11) placeholder; pause;;
    00) update_script; exit;;
    88) echo -e "${GREEN}再见！${RESET}"; exit 0;;
    *) echo -e "${RED}无效选项，请重新输入。${RESET}"; pause;;
  esac

done
