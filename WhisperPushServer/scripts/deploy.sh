#!/usr/bin/env bash
# WhisperPush Server Deployment Script
# Executed remotely via ssh from GitHub Actions.
# All required variables are injected as environment variables by the caller.

set -e

echo "=== 1. 安装 uv 包管理器 ==="
if ! command -v uv &> /dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "=== 2. 创建服务用户 ==="
if ! id "${SERVICE_USER}" &>/dev/null; then
  sudo useradd --system --no-create-home --shell /usr/sbin/nologin "${SERVICE_USER}"
fi

echo "=== 3. 创建安装目录 ==="
sudo mkdir -p "${INSTALL_DIR}"
sudo chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${INSTALL_DIR}"

echo "=== 4. 同步代码 ==="
cd "${INSTALL_DIR}"
if [[ -d .git ]]; then
  git stash
  git checkout "${GITHUB_REF_NAME}"
  git pull origin "${GITHUB_REF_NAME}"
else
  git clone "https://github.com/${GITHUB_REPOSITORY}.git" .
  git checkout "${GITHUB_REF_NAME}"
fi

echo "=== 5. 创建虚拟环境并安装依赖 ==="
uv venv
uv sync --frozen

echo "=== 6. 创建/更新 .env 文件 ==="
cat > "${INSTALL_DIR}/.env" << ENVEOF
DATABASE_URL=${DATABASE_URL}
SECRET_KEY=${SECRET_KEY}
JWT_SECRET_KEY=${JWT_SECRET_KEY}
SMTP_SERVER=${SMTP_SERVER}
SMTP_PORT=${SMTP_PORT}
SMTP_USERNAME=${SMTP_USERNAME}
SMTP_PASSWORD=${SMTP_PASSWORD}
EMAIL_FROM=${EMAIL_FROM}
ENVEOF
sudo chmod 600 "${INSTALL_DIR}/.env"
sudo chown "${SERVICE_USER}:${SERVICE_GROUP}" "${INSTALL_DIR}/.env"

echo "=== 7. 数据库迁移 ==="
uv run alembic upgrade head

echo "=== 8. 创建预启动脚本 ==="
cat > "${INSTALL_DIR}/prestart.sh" << PRESTART_EOF
#!/usr/bin/env bash
set -e

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

echo -n "同步数据库表... "
${INSTALL_DIR}/.venv/bin/python -c "
from app.database import engine, Base
import app.models
Base.metadata.create_all(bind=engine)
print('OK')
"
PRESTART_EOF
chmod +x "${INSTALL_DIR}/prestart.sh"

echo "=== 9. 创建 systemd 服务 ==="
cat > "/etc/systemd/system/${APP_NAME}.service" << SYSTEMD_EOF
[Unit]
Description=WhisperPush Server - 消息推送系统后端服务
Documentation=https://github.com/${GITHUB_REPOSITORY}
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
WorkingDirectory=${INSTALL_DIR}
Environment="PATH=${INSTALL_DIR}/.venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=${INSTALL_DIR}/.env

ExecStartPre=/bin/bash ${INSTALL_DIR}/prestart.sh

ExecStart=${INSTALL_DIR}/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8001 --workers 4 --log-level info

ExecStop=/bin/kill -TERM \$MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30

Restart=on-failure
RestartSec=5s

NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=${INSTALL_DIR}

StandardOutput=journal
StandardError=journal
SyslogIdentifier=${APP_NAME}

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

echo "=== 10. 设置权限 ==="
sudo chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${INSTALL_DIR}"
sudo find "${INSTALL_DIR}" -type d -exec chmod 755 {} \;
sudo find "${INSTALL_DIR}" -type f -exec chmod 644 {} \;
sudo chmod 755 "${INSTALL_DIR}/.venv/bin/"*

echo "=== 11. 启动服务 ==="
sudo systemctl daemon-reload
sudo systemctl enable "${APP_NAME}"
sudo systemctl restart "${APP_NAME}"

echo "=== 12. 检查服务状态 ==="
sleep 3
if sudo systemctl is-active --quiet "${APP_NAME}"; then
  echo "✅ 服务启动成功"
  echo "服务状态: 运行中"
  echo "监听端口: 8001"
else
  echo "❌ 服务启动失败，查看日志:"
  sudo journalctl -u "${APP_NAME}" -n 50
  exit 1
fi
