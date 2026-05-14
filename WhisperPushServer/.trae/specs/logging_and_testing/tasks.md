# WhisperPush 后端 - 日志增强与单元测试实现计划

## [x] Task 1: 创建请求日志中间件
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 创建一个 FastAPI 中间件，自动记录每个请求的入口和出口日志
  - 日志包含：请求方法、路径、查询参数、状态码、耗时、客户端IP
- **Acceptance Criteria Addressed**: AC-1
- **Test Requirements**:
  - `programmatic` TR-1.1: 中间件正确记录请求日志
  - `programmatic` TR-1.2: 日志包含所有要求的字段

## [ ] Task 2: 为 auth.py 添加代码注释
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 为 auth.py 中的所有函数添加文档字符串注释
  - 说明函数功能、参数、返回值
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `human-judgment` TR-2.1: 所有公开函数都有完整注释

## [ ] Task 3: 为 messages.py 添加代码注释
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 为 messages.py 中的所有函数添加文档字符串注释
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `human-judgment` TR-3.1: 所有公开函数都有完整注释

## [ ] Task 4: 为 secrets.py 添加代码注释
- **Priority**: P1
- **Depends On**: None
- **Description**: 
  - 为 secrets.py 中的所有函数添加文档字符串注释
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `human-judgment` TR-4.1: 所有公开函数都有完整注释

## [ ] Task 5: 为 devices.py 添加代码注释
- **Priority**: P1
- **Depends On**: None
- **Description**: 
  - 为 devices.py 中的所有函数添加文档字符串注释
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `human-judgment` TR-5.1: 所有公开函数都有完整注释

## [ ] Task 6: 为 two_factor.py 添加代码注释
- **Priority**: P1
- **Depends On**: None
- **Description**: 
  - 为 two_factor.py 中的所有函数添加文档字符串注释
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `human-judgment` TR-6.1: 所有公开函数都有完整注释

## [x] Task 7: 为 security.py 添加代码注释
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 为 security.py 中的所有函数添加文档字符串注释
- **Acceptance Criteria Addressed**: AC-2
- **Test Requirements**:
  - `human-judgment` TR-7.1: 所有公开函数都有完整注释

## [ ] Task 8: 创建 auth 路由单元测试
- **Priority**: P0
- **Depends On**: Task 1, Task 2
- **Description**: 
  - 创建 test_auth.py 测试文件
  - 测试注册、登录、登出、修改密码等功能
- **Acceptance Criteria Addressed**: AC-3
- **Test Requirements**:
  - `programmatic` TR-8.1: 测试用户注册成功和失败场景
  - `programmatic` TR-8.2: 测试用户登录成功和失败场景
  - `programmatic` TR-8.3: 测试修改密码功能

## [ ] Task 9: 创建 messages 路由单元测试
- **Priority**: P0
- **Depends On**: Task 1, Task 3
- **Description**: 
  - 创建 test_messages.py 测试文件
  - 测试消息推送、查询、标记已读/未读、删除功能
- **Acceptance Criteria Addressed**: AC-3
- **Test Requirements**:
  - `programmatic` TR-9.1: 测试消息推送功能
  - `programmatic` TR-9.2: 测试消息列表查询
  - `programmatic` TR-9.3: 测试消息状态更新

## [ ] Task 10: 创建 security 模块单元测试
- **Priority**: P0
- **Depends On**: Task 7
- **Description**: 
  - 创建 test_security.py 测试文件
  - 测试密码哈希、JWT 生成验证等功能
- **Acceptance Criteria Addressed**: AC-3
- **Test Requirements**:
  - `programmatic` TR-10.1: 测试密码哈希和验证
  - `programmatic` TR-10.2: 测试 JWT token 生成和解析

## [ ] Task 11: 创建 two_factor 路由单元测试
- **Priority**: P1
- **Depends On**: Task 1, Task 6
- **Description**: 
  - 创建 test_two_factor.py 测试文件
  - 测试双因素认证启用、验证、禁用功能
- **Acceptance Criteria Addressed**: AC-3
- **Test Requirements**:
  - `programmatic` TR-11.1: 测试双因素认证启用
  - `programmatic` TR-11.2: 测试验证码验证
  - `programmatic` TR-11.3: 测试双因素认证禁用

## [ ] Task 12: 安装测试依赖并运行测试
- **Priority**: P0
- **Depends On**: Task 8-11
- **Description**: 
  - 安装 pytest、pytest-asyncio、pytest-cov 等依赖
  - 运行测试并检查覆盖率
- **Acceptance Criteria Addressed**: AC-3
- **Test Requirements**:
  - `programmatic` TR-12.1: 所有测试通过
  - `programmatic` TR-12.2: 测试覆盖率 >= 80%
