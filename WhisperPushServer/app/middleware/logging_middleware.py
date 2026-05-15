import logging
import time
from typing import Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    请求日志中间件
    
    为所有 HTTP 请求自动记录入口和出口日志，包含以下信息：
    - 请求方法 (GET/POST/PUT/DELETE/PATCH)
    - 请求路径
    - 查询参数
    - 请求体大小（仅记录长度，不记录内容）
    - 客户端 IP 地址
    - 响应状态码
    - 请求处理耗时（毫秒）
    """

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        处理请求并记录日志
        
        Args:
            request: FastAPI 请求对象
            call_next: 下一个中间件或路由处理函数
        
        Returns:
            Response: HTTP 响应对象
        """
        start_time = time.time()
        client_ip = self._get_client_ip(request)
        method = request.method
        path = request.url.path
        query_params = dict(request.query_params)
        
        # 记录请求入口日志
        logger.info(
            "Request received | Method: %s | Path: %s | Query: %s | Client IP: %s",
            method,
            path,
            query_params,
            client_ip
        )
        
        try:
            # 执行请求处理
            response = await call_next(request)
            
            # 计算耗时
            process_time = (time.time() - start_time) * 1000
            
            # 记录请求出口日志
            logger.info(
                "Request completed | Method: %s | Path: %s | Status: %d | Duration: %.2fms | Client IP: %s",
                method,
                path,
                response.status_code,
                process_time,
                client_ip
            )
            
            return response
        
        except Exception as e:
            # 记录异常日志
            process_time = (time.time() - start_time) * 1000
            logger.error(
                "Request failed | Method: %s | Path: %s | Duration: %.2fms | Client IP: %s | Error: %s",
                method,
                path,
                process_time,
                client_ip,
                str(e)
            )
            raise

    @staticmethod
    def _get_client_ip(request: Request) -> str:
        """
        获取客户端真实 IP 地址

        优先从 X-Forwarded-For 或 X-Real-IP 头获取，
        如果不存在则使用远程地址

        Args:
            request: FastAPI 请求对象

        Returns:
            str: 客户端 IP 地址
        """
        x_forwarded_for = request.headers.get("X-Forwarded-For")
        if x_forwarded_for:
            return x_forwarded_for.split(",")[0].strip()

        x_real_ip = request.headers.get("X-Real-IP")
        if x_real_ip:
            return x_real_ip

        client = request.client
        return client.host if client else "unknown"
