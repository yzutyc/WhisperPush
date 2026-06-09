#!/usr/bin/env bash
#===============================================================================
# WhisperPush Server - Linux systemd 服务安装脚本
#===============================================================================
set -euo pipefail

# ---- 可配置变量 ----
SERVICE_NAME="whisperpush-server"
SERVICE_USER="whisperpush"
SERVICE_GROUP="whisperpush"
INSTALL_DIR="/opt/${SERVICE_NAME}"
UV_PATH="${UV_PATH:-$(command -v uv 2>/dev/null || echo '')}"
HOST="0.0.0.0"
PORT="${PORT:-8000}"
WORKERS="${WORKERS:-4}"

# ---- 颜色输出 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

#===============================================================================
# 0. 权限检查
#===============================================================================
require_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "请使用 root 权限运行此脚本：sudo bash $0"
        exit 1
    fi
}

#===============================================================================
# 1. 检测 uv / Python 环境
#===============================================================================
detect_uv() {
    if [[ -z "$UV_PATH" ]]; then
        # sudo 环境下 SUDO_USER 是原始用户，从原用户 HOME 查找
        local search_paths=(
            "/usr/local/bin/uv"
            "/usr/bin/uv"
            "$HOME/.local/bin/uv"
            "$HOME/.cargo/bin/uv"
        )
        if [[ -n "${SUDO_USER:-}" ]]; then
            local sudo_home
            sudo_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
            search_paths+=(
                "${sudo_home}/.local/bin/uv"
                "${sudo_home}/.cargo/bin/uv"
            )
        fi

        for candidate in "${search_paths[@]}"; do
            if [[ -x "$candidate" ]]; then
                UV_PATH="$candidate"
                break
            fi
        done
    fi

    if [[ -z "$UV_PATH" ]] || [[ ! -x "$UV_PATH" ]]; then
        log_error "未找到 uv 包管理器"
        log_error "可通过以下命令安装: curl -LsSf https://astral.sh/uv/install.sh | sh"
        log_error "或通过 UV_PATH 环境变量指定: sudo UV_PATH=/path/to/uv $0"
        exit 1
    fi
    log_info "uv 路径: ${UV_PATH}"
}

#===============================================================================
# 2. 确保 uv 系统级可访问
#===============================================================================
ensure_system_uv() {
    local system_uv="/usr/local/bin/uv"

    if [[ -x "$system_uv" ]]; then
        log_info "uv 已安装在系统路径: ${system_uv}"
        UV_PATH="$system_uv"
        return
    fi

    if [[ "$UV_PATH" == /root/* ]] || [[ "$UV_PATH" == /home/* ]]; then
        log_warn "uv 位于用户 HOME 目录 (${UV_PATH})，服务用户可能无法访问"
        log_info "复制 uv 到 ${system_uv} ..."
        cp "$UV_PATH" "$system_uv"
        chmod 755 "$system_uv"
        UV_PATH="$system_uv"
        log_info "uv 已安装到系统路径"
    fi
}

#===============================================================================
# 3. 创建系统用户
#===============================================================================
create_service_user() {
    if id "$SERVICE_USER" &>/dev/null; then
        log_info "用户 ${SERVICE_USER} 已存在，跳过创建"
    else
        useradd --system --no-create-home --shell /usr/sbin/nologin "$SERVICE_USER"
        log_info "已创建系统用户: ${SERVICE_USER}"
    fi
}

#===============================================================================
# 4. 部署项目文件
#===============================================================================
deploy_project() {
    local src_dir
    src_dir="$(cd "$(dirname "$0")" && pwd)"

    if [[ "$src_dir" == "$INSTALL_DIR" ]]; then
        log_info "当前目录即为安装目录，跳过拷贝"
        return
    fi

    if [[ -d "$INSTALL_DIR" ]]; then
        log_warn "安装目录 ${INSTALL_DIR} 已存在"
        read -r -p "是否覆盖? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "已取消部署"
            exit 0
        fi
        rm -rf "$INSTALL_DIR"
    fi

    log_info "拷贝项目文件到 ${INSTALL_DIR} ..."
    mkdir -p "$INSTALL_DIR"
    # 排除不需要的文件/目录
    rsync -a --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
          --exclude='.venv' --exclude='venv' --exclude='.pytest_cache' \
          --exclude='*.egg-info' "$src_dir/" "$INSTALL_DIR/"

    # .env 文件单独处理（如存在则拷贝，避免覆盖已有配置）
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        log_info ".env 已存在，保留现有配置"
    elif [[ -f "$src_dir/.env" ]]; then
        cp "$src_dir/.env" "$INSTALL_DIR/.env"
        log_info "已拷贝 .env 配置文件"
    fi
}

#===============================================================================
# 5. 安装依赖 & 数据库迁移
#===============================================================================
install_deps() {
    cd "$INSTALL_DIR"
    log_info "安装 Python 依赖..."
    "$UV_PATH" sync --frozen
    log_info "依赖安装完成"

    log_info "执行数据库迁移..."
    if "$UV_PATH" run alembic upgrade head; then
        log_info "数据库迁移完成"
    else
        log_warn "数据库迁移失败，请检查 .env 中的数据库连接配置"
        log_warn "服务可能在数据库就绪前无法正常启动"
    fi
}

#===============================================================================
# 5b. 创建服务启动前检查脚本
#===============================================================================
create_prestart_script() {
    local prestart="${INSTALL_DIR}/prestart.sh"

    cat > "$prestart" << PRESTART_EOF
#!/usr/bin/env bash
set -e

# ---- 数据库连接检查 ----
echo -n "检查数据库连接... "
${INSTALL_DIR}/.venv/bin/python -c "
import sys
from sqlalchemy import create_engine, text
from app.config import settings
try:
    engine = create_engine(settings.database_url)
    with engine.begin() as conn:
        conn.execute(text('SELECT 1'))
    print('OK')
except Exception as e:
    print(f'FAILED: {e}', file=sys.stderr)
    sys.exit(1)
"

# ---- 创建/更新数据库表 ----
echo -n "同步数据库表... "
${INSTALL_DIR}/.venv/bin/python -c "
from app.database import engine, Base
import app.models
Base.metadata.create_all(bind=engine)
print('OK')
"
PRESTART_EOF

    chmod +x "$prestart"
    log_info "已创建启动前检查脚本: ${prestart}"
}
create_systemd_service() {
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"

    # 使用 uvicorn 直接启动（生产模式，无 --reload）
    # 数据库检查由 ExecStartPre 完成
    cat > "$service_file" << SYSTEMD_EOF
[Unit]
Description=WhisperPush Server - 消息推送系统后端服务
Documentation=https://github.com/whisperpush/whisperpush-server
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
WorkingDirectory=${INSTALL_DIR}
Environment="PATH=${INSTALL_DIR}/.venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=-${INSTALL_DIR}/.env

# 启动前脚本：数据库连接检查 + 表同步
ExecStartPre=/bin/bash ${INSTALL_DIR}/prestart.sh

# 主进程: uvicorn 多 worker 模式
ExecStart=${INSTALL_DIR}/.venv/bin/uvicorn app.main:app --host ${HOST} --port ${PORT} --workers ${WORKERS} --log-level info

# 优雅关闭
ExecStop=/bin/kill -TERM \$MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30

# 自动重启
Restart=on-failure
RestartSec=5s

# 安全加固
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=${INSTALL_DIR}
ReadOnlyPaths=${INSTALL_DIR}/.env

# 日志输出到 journald
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

    log_info "已创建 systemd 服务文件: ${service_file}"
}

#===============================================================================
# 6. 设置文件权限
#===============================================================================
set_permissions() {

    echo "设置文件权限..."

    echo "chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${INSTALL_DIR}""
    chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "$INSTALL_DIR"
    
    # 设置目录权限为 755
    echo "chmod 755 "${INSTALL_DIR}"/* 2>/dev/null || true"
    find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
    
    # 设置文件权限为 644
    echo "chmod 644 "${INSTALL_DIR}"/* 2>/dev/null || true"
    find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
    
    # 为 .venv/bin/ 下所有可执行文件添加执行权限
    if [[ -d "${INSTALL_DIR}/.venv/bin" ]]; then
        echo "chmod 755 "${INSTALL_DIR}/.venv/bin"/* 2>/dev/null || true"
        chmod 755 "${INSTALL_DIR}/.venv/bin"/*
    fi
    
    # 确保 prestart.sh 和其他脚本可执行
    echo "chmod 755 "${INSTALL_DIR}/prestart.sh" 2>/dev/null || true"
    chmod 755 "${INSTALL_DIR}/prestart.sh" 2>/dev/null || true
    
    # .env 包含敏感信息，限制为仅 owner 可读
    echo "chmod 600 "${INSTALL_DIR}/.env" 2>/dev/null || true"
    chmod 600 "${INSTALL_DIR}/.env" 2>/dev/null || true

    ll "${INSTALL_DIR}"
    log_info "文件权限设置完成"
}

#===============================================================================
# 7. 启用并启动服务
#===============================================================================
enable_and_start() {
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl restart "$SERVICE_NAME"
    log_info "服务已启用并启动"

    # 等待启动
    sleep 2
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "服务运行中"
    else
        log_warn "服务未正常运行，请检查日志: journalctl -u ${SERVICE_NAME} -f"
    fi
}

#===============================================================================
# 8. 打印状态信息
#===============================================================================
show_status() {
    echo ""
    echo "============================================="
    echo "  WhisperPush Server 服务安装完成"
    echo "============================================="
    echo ""
    echo "  服务名称:  ${SERVICE_NAME}"
    echo "  安装目录:  ${INSTALL_DIR}"
    echo "  监听地址:  ${HOST}:${PORT}"
    echo ""
    echo "  常用命令:"
    echo "    systemctl status   ${SERVICE_NAME}    # 查看状态"
    echo "    systemctl restart  ${SERVICE_NAME}    # 重启服务"
    echo "    systemctl stop     ${SERVICE_NAME}    # 停止服务"
    echo "    journalctl -u      ${SERVICE_NAME} -f # 查看日志"
    echo ""
    echo "  健康检查:"
    echo "    curl http://localhost:${PORT}/health"
    echo ""
}

#===============================================================================
# 卸载函数
#===============================================================================
uninstall() {
    log_warn "即将卸载 ${SERVICE_NAME} 服务..."
    read -r -p "确认卸载? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "已取消卸载"
        exit 0
    fi

    systemctl stop    "$SERVICE_NAME" 2>/dev/null || true
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
    systemctl daemon-reload

    read -r -p "是否删除安装目录 ${INSTALL_DIR}? [y/N] " del_confirm
    if [[ "$del_confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        log_info "已删除安装目录: ${INSTALL_DIR}"
    fi

    read -r -p "是否删除系统用户 ${SERVICE_USER}? [y/N] " user_confirm
    if [[ "$user_confirm" =~ ^[Yy]$ ]]; then
        userdel "$SERVICE_USER" 2>/dev/null || true
        log_info "已删除系统用户: ${SERVICE_USER}"
    fi

    log_info "卸载完成"
}

#===============================================================================
# main
#===============================================================================
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                PORT="$2"; shift 2 ;;
            -w|--workers)
                WORKERS="$2"; shift 2 ;;
            --uv-path)
                UV_PATH="$2"; shift 2 ;;
            -h|--help)
                show_help; exit 0 ;;
            install|uninstall)
                ACTION="$1"; shift ;;
            *)
                echo "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    ACTION="${ACTION:-install}"

    case "$ACTION" in
        install)
            require_root
            detect_uv
            ensure_system_uv
            create_service_user
            deploy_project
            install_deps
            create_prestart_script
            create_systemd_service
            set_permissions
            enable_and_start
            show_status
            ;;
        uninstall)
            require_root
            uninstall
            ;;
    esac
}

show_help() {
    echo "用法: $0 [选项] {install|uninstall}"
    echo ""
    echo "命令:"
    echo "  install     安装并启动 systemd 服务（默认）"
    echo "  uninstall   停止并移除 systemd 服务"
    echo ""
    echo "选项:"
    echo "  -p, --port PORT       监听端口（默认 8000）"
    echo "  -w, --workers N       uvicorn worker 数量（默认 4）"
    echo "  --uv-path PATH        uv 可执行文件路径（默认自动检测）"
    echo "  -h, --help            显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  sudo $0                          # 默认端口 8000 安装"
    echo "  sudo $0 -p 9000                  # 自定义端口 9000 安装"
    echo "  sudo $0 -p 9000 -w 2             # 端口 9000，2 worker"
    echo "  sudo $0 uninstall                # 卸载服务"
}

main "${@}"
