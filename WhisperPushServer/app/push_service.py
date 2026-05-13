import time
from typing import Optional

import aiohttp
import jwt

from app import models
from app.config import settings


class PushService:
    def __init__(self):
        self.fcm_server_key = settings.fcm_server_key
        self.apns_key_id = settings.apns_key_id
        self.apns_team_id = settings.apns_team_id
        self.apns_bundle_id = settings.apns_bundle_id
        self.apns_private_key = settings.apns_private_key
        self.apns_private_key_path = settings.apns_private_key_path
        self.apns_use_sandbox = settings.apns_use_sandbox
        self._apns_jwt = None
        self._apns_jwt_expires = 0

    def _get_apns_private_key(self) -> Optional[str]:
        if self.apns_private_key:
            return self.apns_private_key
        if self.apns_private_key_path:
            try:
                with open(self.apns_private_key_path, "r") as f:
                    return f.read()
            except:
                pass
        return None

    def _generate_apns_jwt(self) -> Optional[str]:
        private_key = self._get_apns_private_key()
        if not all([private_key, self.apns_key_id, self.apns_team_id]):
            return None

        now = int(time.time())
        token = jwt.encode(
            {
                "iss": self.apns_team_id,
                "iat": now,
            },
            private_key,
            algorithm="ES256",
            headers={"kid": self.apns_key_id},
        )
        self._apns_jwt = token
        self._apns_jwt_expires = now + 30 * 60
        return token

    def _get_apns_jwt(self) -> Optional[str]:
        now = int(time.time())
        if self._apns_jwt and now < self._apns_jwt_expires - 60:
            return self._apns_jwt
        return self._generate_apns_jwt()

    async def send_android_push(
        self, device_token: str, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        if not self.fcm_server_key:
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
            "Authorization": f"key={self.fcm_server_key}",
            "Content-Type": "application/json",
        }

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(fcm_url, json=payload, headers=headers) as resp:
                    return resp.status == 200
        except:
            return False

    async def send_ios_push(
        self, device_token: str, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        if not self.apns_bundle_id:
            return False

        jwt_token = self._get_apns_jwt()
        if not jwt_token:
            return False

        host = "api.sandbox.push.apple.com" if self.apns_use_sandbox else "api.push.apple.com"
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
            "apns-topic": self.apns_bundle_id,
            "content-type": "application/json",
        }

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(apns_url, json=payload, headers=headers) as resp:
                    return resp.status == 200
        except:
            return False

    async def send_push_to_device(
        self, device: models.Device, title: str, body: str, data: Optional[dict] = None
    ) -> bool:
        if not device.device_token or not device.is_active:
            return False

        device_type = device.device_type.lower() if device.device_type else ""

        if device_type == "ios":
            return await self.send_ios_push(device.device_token, title, body, data)
        elif device_type == "android":
            return await self.send_android_push(device.device_token, title, body, data)

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
