import time
from abc import ABC, abstractmethod
from typing import Optional, Dict

import aiohttp
import jwt

from app import models
from app.config import settings


class BasePushAdapter(ABC):
    @abstractmethod
    async def send_push(
        self, device_token: str, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        pass


class FCMAdapter(BasePushAdapter):
    def __init__(self, server_key: str):
        self.server_key = server_key

    async def send_push(
        self, device_token: str, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        if not self.server_key:
            return False

        fcm_url = "https://fcm.googleapis.com/fcm/send"
        payload = {
            "to": device_token,
            "notification": {
                "title": title,
                "body": body,
            },
        }
        if data:
            payload["data"] = data

        headers = {
            "Authorization": f"key={self.server_key}",
            "Content-Type": "application/json",
        }

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(fcm_url, json=payload, headers=headers) as resp:
                    return resp.status == 200
        except:
            return False


class APNsAdapter(BasePushAdapter):
    def __init__(
        self,
        key_id: str,
        team_id: str,
        bundle_id: str,
        private_key: Optional[str] = None,
        private_key_path: Optional[str] = None,
        use_sandbox: bool = False,
    ):
        self.key_id = key_id
        self.team_id = team_id
        self.bundle_id = bundle_id
        self.private_key = private_key
        self.private_key_path = private_key_path
        self.use_sandbox = use_sandbox
        self._jwt = None
        self._jwt_expires = 0

    def _get_private_key(self) -> Optional[str]:
        if self.private_key:
            return self.private_key
        if self.private_key_path:
            try:
                with open(self.private_key_path, "r") as f:
                    return f.read()
            except:
                pass
        return None

    def _generate_jwt(self) -> Optional[str]:
        private_key = self._get_private_key()
        if not all([private_key, self.key_id, self.team_id]):
            return None

        now = int(time.time())
        token = jwt.encode(
            {
                "iss": self.team_id,
                "iat": now,
            },
            private_key,
            algorithm="ES256",
            headers={"kid": self.key_id},
        )
        self._jwt = token
        self._jwt_expires = now + 30 * 60
        return token

    def _get_jwt(self) -> Optional[str]:
        now = int(time.time())
        if self._jwt and now < self._jwt_expires - 60:
            return self._jwt
        return self._generate_jwt()

    async def send_push(
        self, device_token: str, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        if not self.bundle_id:
            return False

        jwt_token = self._get_jwt()
        if not jwt_token:
            return False

        host = "api.sandbox.push.apple.com" if self.use_sandbox else "api.push.apple.com"
        apns_url = f"https://{host}/3/device/{device_token}"

        payload = {
            "aps": {
                "alert": {
                    "title": title,
                    "body": body,
                },
                "sound": "default",
            }
        }
        if data:
            payload.update(data)

        headers = {
            "authorization": f"bearer {jwt_token}",
            "apns-topic": self.bundle_id,
            "content-type": "application/json",
        }

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(apns_url, json=payload, headers=headers) as resp:
                    return resp.status == 200
        except:
            return False


class HuaweiPushAdapter(BasePushAdapter):
    def __init__(self, app_id: str, app_secret: str):
        self.app_id = app_id
        self.app_secret = app_secret
        self._access_token = None
        self._token_expires = 0

    async def _get_access_token(self) -> Optional[str]:
        now = int(time.time())
        if self._access_token and now < self._token_expires - 300:
            return self._access_token

        token_url = "https://oauth-login.cloud.huawei.com/oauth2/v3/token"
        payload = {
            "grant_type": "client_credentials",
            "client_id": self.app_id,
            "client_secret": self.app_secret,
        }

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(token_url, data=payload) as resp:
                    if resp.status == 200:
                        result = await resp.json()
                        self._access_token = result.get("access_token")
                        expires_in = result.get("expires_in", 3600)
                        self._token_expires = now + expires_in
                        return self._access_token
            return None
        except:
            return None

    async def send_push(
        self, device_token: str, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        if not all([self.app_id, self.app_secret]):
            return False

        access_token = await self._get_access_token()
        if not access_token:
            return False

        push_url = f"https://push-api.cloud.huawei.com/v1/{self.app_id}/messages:send"
        
        message = {
            "data": str(data) if data else "{}",
            "android": {
                "notification": {
                    "title": title,
                    "body": body,
                    "click_action": {
                        "type": 3
                    }
                }
            },
            "token": [device_token]
        }
        
        payload = {"message": message}
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(push_url, json=payload, headers=headers) as resp:
                    if resp.status == 200:
                        result = await resp.json()
                        return result.get("code") == "80000000"
            return False
        except:
            return False


class PushService:
    def __init__(self):
        self._adapters: Dict[str, BasePushAdapter] = {}
        self._init_adapters()

    def _init_adapters(self):
        if settings.fcm_server_key:
            fcm_adapter = FCMAdapter(settings.fcm_server_key)
            self.register_adapter("android", fcm_adapter)

        if settings.apns_bundle_id:
            apns_adapter = APNsAdapter(
                key_id=settings.apns_key_id,
                team_id=settings.apns_team_id,
                bundle_id=settings.apns_bundle_id,
                private_key=settings.apns_private_key,
                private_key_path=settings.apns_private_key_path,
                use_sandbox=settings.apns_use_sandbox,
            )
            self.register_adapter("ios", apns_adapter)
        
        if settings.huawei_app_id and settings.huawei_app_secret:
            huawei_adapter = HuaweiPushAdapter(
                app_id=settings.huawei_app_id,
                app_secret=settings.huawei_app_secret
            )
            self.register_adapter("huawei", huawei_adapter)

    def register_adapter(self, device_type: str, adapter: BasePushAdapter):
        self._adapters[device_type.lower()] = adapter

    def get_adapter(self, device_type: str) -> Optional[BasePushAdapter]:
        return self._adapters.get(device_type.lower())

    async def send_android_push(
        self, device_token: str, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        adapter = self.get_adapter("android")
        if adapter:
            return await adapter.send_push(device_token, title, body, data)
        return False

    async def send_ios_push(
        self, device_token: str, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        adapter = self.get_adapter("ios")
        if adapter:
            return await adapter.send_push(device_token, title, body, data)
        return False
    
    async def send_huawei_push(
        self, device_token: str, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        adapter = self.get_adapter("huawei")
        if adapter:
            return await adapter.send_push(device_token, title, body, data)
        return False

    async def send_push_to_device(
        self, device: models.Device, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        if not device.device_token or not device.is_active:
            return False

        adapter = None
        if device.push_vendor:
            adapter = self.get_adapter(device.push_vendor)
        if not adapter and device.device_type:
            device_type = device.device_type.lower()
            adapter = self.get_adapter(device_type)

        if adapter:
            return await adapter.send_push(device.device_token, title, body, data)

        return False

    async def send_push_to_user_devices(
        self, devices: list[models.Device], title: str, body: str, data: Optional[dict] = None
    ):
        results = []
        for device in devices:
            success = await self.send_push_to_device(device, title, body, data)
            results.append((device.id, success))
        return results


push_service = PushService()
