import logging
import smtplib
from email.message import EmailMessage

from app.config import settings

logger = logging.getLogger(__name__)


def send_email(to_address: str, subject: str, body_html: str) -> bool:
    """
    通过 SMTP 发送邮件

    Args:
        to_address: 收件人邮箱地址
        subject: 邮件主题
        body_html: 邮件正文（HTML 格式）

    Returns:
        bool: 发送成功返回 True，失败返回 False
    """
    msg = EmailMessage()
    msg["From"] = settings.smtp_from_address
    msg["To"] = to_address
    msg["Subject"] = subject
    msg.set_content(_strip_html(body_html))
    msg.add_alternative(body_html, subtype="html")

    try:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=30) as server:
            if settings.smtp_use_tls:
                server.starttls()
            if settings.smtp_username and settings.smtp_password:
                server.login(settings.smtp_username, settings.smtp_password)
            server.send_message(msg)
        logger.info("邮件发送成功: to=%s, subject=%s", to_address, subject)
        return True
    except smtplib.SMTPException as e:
        logger.warning("邮件发送失败: to=%s, error=%s", to_address, str(e))
        return False
    except OSError as e:
        logger.warning("SMTP 连接失败: host=%s:%s, error=%s",
                       settings.smtp_host, settings.smtp_port, str(e))
        return False


def send_password_reset_email(to_address: str, reset_token: str) -> bool:
    """
    发送密码重置邮件

    Args:
        to_address: 用户注册邮箱
        reset_token: 密码重置令牌

    Returns:
        bool: 发送成功返回 True
    """
    subject = "WhisperPush - 密码重置"
    body_html = _build_reset_email_body(reset_token)
    return send_email(to_address, subject, body_html)


def _build_reset_email_body(reset_token: str) -> str:
    return f"""\
<html>
<body style="font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5;">
  <div style="max-width: 480px; margin: 0 auto; background: #fff; border-radius: 8px; \
padding: 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
    <h2 style="color: #7c3aed; margin-top: 0;">WhisperPush 密码重置</h2>
    <p style="color: #333; line-height: 1.6;">
      您请求了密码重置操作。请使用以下令牌在应用中完成密码重置：
    </p>
    <div style="background: #f0e7ff; border-radius: 6px; padding: 16px; \
margin: 24px 0; text-align: center;">
      <code style="font-size: 20px; font-weight: bold; color: #6d28d9; \
letter-spacing: 1px; word-break: break-all;">
        {reset_token}
      </code>
    </div>
    <p style="color: #666; font-size: 14px; line-height: 1.6;">
      该令牌有效期为 1 小时，使用后自动失效。<br>
      如果您未发起此操作，请忽略此邮件。
    </p>
    <hr style="border: none; border-top: 1px solid #e5e5e5; margin: 24px 0;">
    <p style="color: #999; font-size: 12px;">
      此邮件由系统自动发送，请勿回复。
    </p>
  </div>
</body>
</html>"""


def _strip_html(html: str) -> str:
    """简单的 HTML 标签移除，生成纯文本备用内容"""
    import re
    text = re.sub(r"<[^>]+>", "", html)
    text = re.sub(r"\s+", " ", text).strip()
    return text
