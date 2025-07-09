# Python 语言规则文档

## 语言特性

### 核心优势
- **简洁易读**: 清晰的语法，接近自然语言
- **动态类型**: 灵活的类型系统，支持类型提示
- **丰富生态**: 庞大的第三方库生态系统
- **跨平台**: 支持多种操作系统和架构
- **多范式**: 支持面向对象、函数式、过程式编程

### Python 3.8+ 现代特性
```python
# 海象运算符 (Python 3.8+)
if (n := len(data)) > 10:
    print(f"数据量较大: {n} 条记录")

# 位置参数限制 (Python 3.8+)
def create_user(name, /, email, *, role="user"):
    """
    name: 只能位置传参
    email: 可位置或关键字传参
    role: 只能关键字传参
    """
    return {"name": name, "email": email, "role": role}

# 类型提示改进 (Python 3.9+)
from typing import Dict, List, Optional, Union
from collections.abc import Sequence

def process_data(
    items: list[dict[str, int]],  # Python 3.9+ 简化语法
    config: dict[str, str | int]  # 联合类型简化
) -> list[str]:
    return [str(item) for item in items]

# 结构化模式匹配 (Python 3.10+)
def handle_response(response):
    match response:
        case {"status": "success", "data": data}:
            return process_success(data)
        case {"status": "error", "message": msg}:
            raise Exception(f"API错误: {msg}")
        case {"status": status} if status in ["pending", "processing"]:
            return "请稍后重试"
        case _:
            raise ValueError("未知响应格式")

# 数据类和属性
from dataclasses import dataclass, field
from typing import ClassVar

@dataclass
class User:
    name: str
    email: str
    age: int = 0
    roles: list[str] = field(default_factory=list)
    _id: str = field(init=False, repr=False)

    # 类变量
    total_users: ClassVar[int] = 0

    def __post_init__(self):
        self._id = f"user_{self.total_users}"
        User.total_users += 1

    @property
    def is_adult(self) -> bool:
        return self.age >= 18

# 异步编程
import asyncio
import aiohttp
from typing import AsyncGenerator

async def fetch_user_data(user_ids: list[str]) -> list[dict]:
    """并发获取用户数据"""
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_single_user(session, uid) for uid in user_ids]
        return await asyncio.gather(*tasks)

async def fetch_single_user(session: aiohttp.ClientSession, user_id: str) -> dict:
    async with session.get(f"/api/users/{user_id}") as response:
        return await response.json()

async def stream_data() -> AsyncGenerator[dict, None]:
    """异步生成器"""
    for i in range(100):
        await asyncio.sleep(0.1)  # 模拟异步操作
        yield {"id": i, "data": f"item_{i}"}
```

## 编码规范

### PEP 8 编码风格
```python
# 命名约定
class UserService:  # 类名: PascalCase
    def __init__(self):
        self.user_count = 0  # 实例变量: snake_case
        self._private_var = None  # 私有变量: 下划线前缀
        self.__very_private = None  # 强私有: 双下划线前缀

    def get_user_by_id(self, user_id: str) -> Optional[dict]:  # 方法名: snake_case
        """获取用户信息"""
        return self._fetch_from_database(user_id)

    def _fetch_from_database(self, user_id: str) -> Optional[dict]:
        """私有方法"""
        pass

# 常量
API_BASE_URL = "https://api.example.com"  # 常量: UPPER_SNAKE_CASE
MAX_RETRY_ATTEMPTS = 3
DEFAULT_TIMEOUT = 30

# 函数定义
def calculate_total_price(
    items: list[dict],
    tax_rate: float = 0.1,
    discount: float = 0.0
) -> float:
    """
    计算总价格

    Args:
        items: 商品列表
        tax_rate: 税率，默认10%
        discount: 折扣，默认无折扣

    Returns:
        计算后的总价格

    Raises:
        ValueError: 当税率或折扣为负数时
    """
    if tax_rate < 0 or discount < 0:
        raise ValueError("税率和折扣不能为负数")

    subtotal = sum(item["price"] * item["quantity"] for item in items)
    discounted = subtotal * (1 - discount)
    total = discounted * (1 + tax_rate)

    return round(total, 2)

# 列表推导式和生成器
# 好的例子
active_users = [user for user in users if user.is_active]
user_emails = [user.email for user in users if user.email]

# 复杂逻辑应该使用函数
def process_user_data(users: list[User]) -> list[dict]:
    """处理用户数据，复杂逻辑不适合列表推导式"""
    result = []
    for user in users:
        if user.is_active and user.email:
            processed = {
                "id": user.id,
                "name": user.name.title(),
                "email": user.email.lower(),
                "roles": [role.upper() for role in user.roles]
            }
            result.append(processed)
    return result

# 异常处理
def safe_divide(a: float, b: float) -> float:
    """安全除法"""
    try:
        return a / b
    except ZeroDivisionError:
        raise ValueError("除数不能为零")
    except TypeError as e:
        raise TypeError(f"参数类型错误: {e}")

# 上下文管理器
from contextlib import contextmanager
import logging

@contextmanager
def database_transaction():
    """数据库事务上下文管理器"""
    transaction = begin_transaction()
    try:
        yield transaction
        transaction.commit()
    except Exception:
        transaction.rollback()
        raise
    finally:
        transaction.close()

# 使用示例
with database_transaction() as tx:
    create_user(tx, user_data)
    update_user_stats(tx, user_id)
```

## 项目结构

### 推荐目录结构
```
project/
├── src/
│   ├── myproject/
│   │   ├── __init__.py
│   │   ├── models/          # 数据模型
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   └── order.py
│   │   ├── services/        # 业务逻辑
│   │   │   ├── __init__.py
│   │   │   ├── user_service.py
│   │   │   └── order_service.py
│   │   ├── repositories/    # 数据访问层
│   │   │   ├── __init__.py
│   │   │   ├── base.py
│   │   │   └── user_repository.py
│   │   ├── api/            # API层
│   │   │   ├── __init__.py
│   │   │   ├── routes/
│   │   │   └── middleware/
│   │   ├── utils/          # 工具函数
│   │   │   ├── __init__.py
│   │   │   ├── validators.py
│   │   │   └── helpers.py
│   │   └── config/         # 配置
│   │       ├── __init__.py
│   │       ├── settings.py
│   │       └── database.py
├── tests/                  # 测试文件
│   ├── unit/
│   ├── integration/
│   └── conftest.py
├── docs/                   # 文档
├── scripts/                # 脚本文件
├── requirements/           # 依赖文件
│   ├── base.txt
│   ├── dev.txt
│   └── prod.txt
├── .env.example
├── pyproject.toml
├── setup.py
└── README.md
```

### 模块导入规范
```python
# 标准库导入
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional

# 第三方库导入
import requests
import pandas as pd
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine

# 本地应用导入
from myproject.models.user import User
from myproject.services.user_service import UserService
from myproject.utils.validators import validate_email

# 相对导入 (在包内部使用)
from .models import User
from ..utils import validate_email
```

## 依赖管理

### pyproject.toml 配置
```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "myproject"
version = "1.0.0"
description = "Python项目示例"
authors = [
    {name = "Your Name", email = "your.email@example.com"}
]
readme = "README.md"
license = {text = "MIT"}
requires-python = ">=3.8"
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.8",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
]

dependencies = [
    "fastapi>=0.100.0",
    "uvicorn[standard]>=0.23.0",
    "sqlalchemy>=2.0.0",
    "pydantic>=2.0.0",
    "python-multipart>=0.0.6",
    "python-jose[cryptography]>=3.3.0",
    "passlib[bcrypt]>=1.7.4",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-asyncio>=0.21.0",
    "pytest-cov>=4.0.0",
    "black>=23.0.0",
    "isort>=5.12.0",
    "flake8>=6.0.0",
    "mypy>=1.0.0",
    "pre-commit>=3.0.0",
]

test = [
    "pytest>=7.0.0",
    "pytest-asyncio>=0.21.0",
    "pytest-cov>=4.0.0",
    "httpx>=0.24.0",
]

[project.scripts]
myproject = "myproject.cli:main"

[tool.setuptools.packages.find]
where = ["src"]

[tool.black]
line-length = 88
target-version = ['py38']
include = '\.pyi?$'
extend-exclude = '''
/(
  # directories
  \.eggs
  | \.git
  | \.hg
  | \.mypy_cache
  | \.tox
  | \.venv
  | build
  | dist
)/
'''

[tool.isort]
profile = "black"
multi_line_output = 3
line_length = 88
known_first_party = ["myproject"]

[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
disallow_untyped_decorators = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_ignores = true
warn_no_return = true
warn_unreachable = true
strict_equality = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--strict-config",
    "--cov=src/myproject",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-report=xml",
]
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
```

### 虚拟环境管理
```bash
# 使用 venv
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# 使用 poetry
poetry init
poetry add fastapi uvicorn
poetry add --group dev pytest black isort
poetry install
poetry shell

# 使用 pipenv
pipenv install fastapi uvicorn
pipenv install --dev pytest black isort
pipenv shell

# 依赖导出
pip freeze > requirements.txt
poetry export -f requirements.txt --output requirements.txt
```

## 测试策略

### 单元测试
```python
# test_user_service.py
import pytest
from unittest.mock import Mock, patch
from myproject.services.user_service import UserService
from myproject.models.user import User
from myproject.exceptions import UserNotFoundError, ValidationError

class TestUserService:
    @pytest.fixture
    def mock_repository(self):
        return Mock()

    @pytest.fixture
    def user_service(self, mock_repository):
        return UserService(mock_repository)

    def test_create_user_success(self, user_service, mock_repository):
        # Arrange
        user_data = {
            "name": "张三",
            "email": "zhangsan@example.com",
            "age": 25
        }
        expected_user = User(**user_data)
        mock_repository.create.return_value = expected_user

        # Act
        result = user_service.create_user(user_data)

        # Assert
        assert result.name == "张三"
        assert result.email == "zhangsan@example.com"
        mock_repository.create.assert_called_once_with(user_data)

    def test_create_user_invalid_email(self, user_service):
        # Arrange
        user_data = {
            "name": "张三",
            "email": "invalid-email",
            "age": 25
        }

        # Act & Assert
        with pytest.raises(ValidationError, match="邮箱格式不正确"):
            user_service.create_user(user_data)

    def test_get_user_not_found(self, user_service, mock_repository):
        # Arrange
        mock_repository.get_by_id.return_value = None

        # Act & Assert
        with pytest.raises(UserNotFoundError):
            user_service.get_user_by_id("nonexistent-id")

    @pytest.mark.asyncio
    async def test_async_create_user(self, user_service, mock_repository):
        # 异步测试示例
        user_data = {"name": "李四", "email": "lisi@example.com"}
        mock_repository.create_async.return_value = User(**user_data)

        result = await user_service.create_user_async(user_data)

        assert result.name == "李四"

# 参数化测试
@pytest.mark.parametrize("email,expected", [
    ("valid@example.com", True),
    ("invalid-email", False),
    ("", False),
    ("test@", False),
    ("@example.com", False),
])
def test_email_validation(email, expected):
    from myproject.utils.validators import validate_email
    assert validate_email(email) == expected

# 测试夹具
@pytest.fixture(scope="session")
def database():
    """会话级别的数据库连接"""
    db = create_test_database()
    yield db
    db.close()

@pytest.fixture
def sample_users():
    """示例用户数据"""
    return [
        User(name="用户1", email="user1@example.com"),
        User(name="用户2", email="user2@example.com"),
    ]
```

### 集成测试
```python
# test_api_integration.py
import pytest
from fastapi.testclient import TestClient
from myproject.main import app
from myproject.database import get_db
from myproject.models import User

@pytest.fixture
def client():
    """测试客户端"""
    return TestClient(app)

@pytest.fixture
def test_db():
    """测试数据库"""
    # 设置测试数据库
    test_database = create_test_database()

    # 替换依赖
    app.dependency_overrides[get_db] = lambda: test_database

    yield test_database

    # 清理
    test_database.close()
    app.dependency_overrides.clear()

class TestUserAPI:
    def test_create_user_success(self, client, test_db):
        user_data = {
            "name": "测试用户",
            "email": "test@example.com",
            "age": 30
        }

        response = client.post("/api/users", json=user_data)

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "测试用户"
        assert data["email"] == "test@example.com"
        assert "id" in data

    def test_get_user_success(self, client, test_db):
        # 先创建用户
        user = User(name="获取测试", email="get@example.com")
        test_db.add(user)
        test_db.commit()

        response = client.get(f"/api/users/{user.id}")

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "获取测试"

    def test_get_user_not_found(self, client, test_db):
        response = client.get("/api/users/nonexistent-id")

        assert response.status_code == 404
        assert "用户不存在" in response.json()["detail"]

# 性能测试
@pytest.mark.slow
def test_bulk_user_creation_performance(client, test_db):
    import time

    users_data = [
        {"name": f"用户{i}", "email": f"user{i}@example.com"}
        for i in range(1000)
    ]

    start_time = time.time()

    for user_data in users_data:
        response = client.post("/api/users", json=user_data)
        assert response.status_code == 201

    end_time = time.time()
    duration = end_time - start_time

    # 性能断言：1000个用户创建应该在10秒内完成
    assert duration < 10.0, f"批量创建耗时过长: {duration}秒"

## 常见问题与解决方案

### 性能问题
```python
# 问题1: 列表推导式 vs 循环性能
# ❌ 低效的循环
result = []
for i in range(1000000):
    if i % 2 == 0:
        result.append(i * 2)

# ✅ 高效的列表推导式
result = [i * 2 for i in range(1000000) if i % 2 == 0]

# ✅ 更高效的生成器表达式（大数据集）
result = (i * 2 for i in range(1000000) if i % 2 == 0)

# 问题2: 字符串拼接性能
# ❌ 低效的字符串拼接
result = ""
for item in items:
    result += str(item) + ","

# ✅ 高效的join方法
result = ",".join(str(item) for item in items)

# 问题3: 字典查找 vs 多个if语句
# ❌ 多个if语句
def get_status_message(status):
    if status == 1:
        return "成功"
    elif status == 2:
        return "失败"
    elif status == 3:
        return "处理中"
    else:
        return "未知"

# ✅ 字典查找
STATUS_MESSAGES = {
    1: "成功",
    2: "失败",
    3: "处理中"
}

def get_status_message(status):
    return STATUS_MESSAGES.get(status, "未知")

# 问题4: 使用slots优化内存
class RegularClass:
    def __init__(self, x, y):
        self.x = x
        self.y = y

class OptimizedClass:
    __slots__ = ['x', 'y']  # 减少内存使用

    def __init__(self, x, y):
        self.x = x
        self.y = y
```

### 内存管理问题
```python
# 问题1: 循环引用导致内存泄漏
import weakref

class Parent:
    def __init__(self):
        self.children = []

    def add_child(self, child):
        self.children.append(child)
        child.parent = weakref.ref(self)  # 使用弱引用避免循环引用

class Child:
    def __init__(self):
        self.parent = None

# 问题2: 大文件处理
# ❌ 一次性读取大文件
with open('large_file.txt', 'r') as f:
    content = f.read()  # 可能导致内存不足

# ✅ 逐行处理大文件
def process_large_file(filename):
    with open(filename, 'r') as f:
        for line in f:  # 逐行读取，内存友好
            yield process_line(line)

# 问题3: 生成器vs列表
# ❌ 返回大列表
def get_large_dataset():
    return [expensive_operation(i) for i in range(1000000)]

# ✅ 使用生成器
def get_large_dataset():
    for i in range(1000000):
        yield expensive_operation(i)
```

### 并发问题
```python
import asyncio
import threading
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
import multiprocessing

# 问题1: GIL限制下的CPU密集型任务
# ❌ 多线程处理CPU密集型任务（受GIL限制）
def cpu_intensive_task(n):
    return sum(i * i for i in range(n))

# 使用线程池（不适合CPU密集型）
with ThreadPoolExecutor() as executor:
    futures = [executor.submit(cpu_intensive_task, 1000000) for _ in range(4)]
    results = [f.result() for f in futures]

# ✅ 使用进程池处理CPU密集型任务
with ProcessPoolExecutor() as executor:
    futures = [executor.submit(cpu_intensive_task, 1000000) for _ in range(4)]
    results = [f.result() for f in futures]

# 问题2: 异步编程最佳实践
# ❌ 阻塞异步函数
async def bad_async_function():
    import time
    time.sleep(1)  # 阻塞整个事件循环
    return "完成"

# ✅ 正确的异步函数
async def good_async_function():
    await asyncio.sleep(1)  # 非阻塞等待
    return "完成"

# 异步上下文管理器
class AsyncDatabaseConnection:
    async def __aenter__(self):
        self.connection = await create_connection()
        return self.connection

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.connection.close()

# 使用示例
async def database_operation():
    async with AsyncDatabaseConnection() as conn:
        result = await conn.execute("SELECT * FROM users")
        return result

# 问题3: 线程安全
import threading

class ThreadSafeCounter:
    def __init__(self):
        self._value = 0
        self._lock = threading.Lock()

    def increment(self):
        with self._lock:
            self._value += 1

    def get_value(self):
        with self._lock:
            return self._value

# 使用队列进行线程间通信
import queue

def producer(q):
    for i in range(10):
        q.put(f"item_{i}")
    q.put(None)  # 结束标志

def consumer(q):
    while True:
        item = q.get()
        if item is None:
            break
        print(f"处理: {item}")
        q.task_done()

# 使用示例
q = queue.Queue()
producer_thread = threading.Thread(target=producer, args=(q,))
consumer_thread = threading.Thread(target=consumer, args=(q,))

producer_thread.start()
consumer_thread.start()

producer_thread.join()
consumer_thread.join()
```

### 错误处理和调试
```python
import logging
import traceback
from functools import wraps

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

# 装饰器：异常处理和重试
def retry(max_attempts=3, delay=1):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    logger.warning(f"第{attempt + 1}次尝试失败: {e}")
                    if attempt == max_attempts - 1:
                        logger.error(f"所有尝试都失败了: {e}")
                        raise
                    time.sleep(delay)
            return None
        return wrapper
    return decorator

# 使用示例
@retry(max_attempts=3, delay=2)
def unreliable_api_call():
    # 模拟不稳定的API调用
    import random
    if random.random() < 0.7:
        raise ConnectionError("网络连接失败")
    return "API调用成功"

# 上下文管理器：异常处理
class ErrorHandler:
    def __init__(self, error_message="操作失败"):
        self.error_message = error_message

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            logger.error(f"{self.error_message}: {exc_val}")
            logger.error(traceback.format_exc())
            # 返回True表示异常已处理，不会向上传播
            return True

# 使用示例
with ErrorHandler("数据库操作失败"):
    # 可能出错的数据库操作
    result = database.execute("SELECT * FROM users")

# 自定义异常类
class ValidationError(Exception):
    """数据验证错误"""
    def __init__(self, message, field=None):
        super().__init__(message)
        self.field = field

class BusinessLogicError(Exception):
    """业务逻辑错误"""
    pass

# 使用自定义异常
def validate_user_data(data):
    if not data.get('email'):
        raise ValidationError("邮箱不能为空", field='email')

    if '@' not in data['email']:
        raise ValidationError("邮箱格式不正确", field='email')

    if data.get('age', 0) < 0:
        raise ValidationError("年龄不能为负数", field='age')

## Python开发最佳实践检查清单

### 代码质量
```markdown
- [ ] 遵循PEP 8编码规范
- [ ] 使用类型提示增强代码可读性
- [ ] 编写清晰的文档字符串
- [ ] 避免使用可变默认参数
- [ ] 合理使用列表推导式和生成器
```

### 性能优化
```markdown
- [ ] 使用适当的数据结构（set vs list）
- [ ] 避免不必要的循环和嵌套
- [ ] 使用内置函数和标准库
- [ ] 合理使用缓存和记忆化
- [ ] 优化I/O操作和数据库查询
```

### 内存管理
```markdown
- [ ] 及时释放大对象的引用
- [ ] 使用生成器处理大数据集
- [ ] 避免循环引用
- [ ] 合理使用__slots__优化内存
- [ ] 监控内存使用情况
```

### 并发编程
```markdown
- [ ] 正确选择并发模型（线程/进程/异步）
- [ ] 避免竞态条件和死锁
- [ ] 使用适当的同步原语
- [ ] 合理设计异步函数
- [ ] 处理并发异常和错误
```

### 安全性
```markdown
- [ ] 验证和清理用户输入
- [ ] 使用参数化查询防止SQL注入
- [ ] 安全地处理敏感数据
- [ ] 使用HTTPS和加密传输
- [ ] 定期更新依赖库
```

### 测试覆盖
```markdown
- [ ] 单元测试覆盖率 > 80%
- [ ] 集成测试覆盖关键流程
- [ ] 性能测试验证关键指标
- [ ] 安全测试检查漏洞
- [ ] 自动化测试集成到CI/CD
```

### 项目结构
```markdown
- [ ] 清晰的目录结构和模块划分
- [ ] 合理的依赖管理
- [ ] 完整的配置管理
- [ ] 详细的文档和README
- [ ] 版本控制和发布流程
```

## 调试技巧和工具

### 调试工具
```python
# 1. 使用pdb调试器
import pdb

def problematic_function(data):
    pdb.set_trace()  # 设置断点
    result = process_data(data)
    return result

# 2. 使用logging进行调试
import logging

# 配置调试级别的日志
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def debug_function(data):
    logger.debug(f"输入数据: {data}")
    result = process_data(data)
    logger.debug(f"处理结果: {result}")
    return result

# 3. 使用装饰器进行函数调试
def debug_calls(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        print(f"调用 {func.__name__} 参数: args={args}, kwargs={kwargs}")
        result = func(*args, **kwargs)
        print(f"{func.__name__} 返回: {result}")
        return result
    return wrapper

@debug_calls
def calculate(x, y):
    return x + y

# 4. 性能分析
import cProfile
import pstats

def profile_function():
    # 要分析的代码
    expensive_operation()

# 运行性能分析
cProfile.run('profile_function()', 'profile_stats')
stats = pstats.Stats('profile_stats')
stats.sort_stats('cumulative').print_stats(10)

# 5. 内存分析
import tracemalloc

# 开始跟踪内存分配
tracemalloc.start()

# 执行代码
data = [i for i in range(1000000)]

# 获取内存使用情况
current, peak = tracemalloc.get_traced_memory()
print(f"当前内存使用: {current / 1024 / 1024:.1f} MB")
print(f"峰值内存使用: {peak / 1024 / 1024:.1f} MB")

tracemalloc.stop()
```

### 常用调试命令
```bash
# 运行时调试
python -m pdb script.py

# 性能分析
python -m cProfile -o profile.stats script.py
python -c "import pstats; pstats.Stats('profile.stats').sort_stats('cumulative').print_stats()"

# 内存分析
python -m tracemalloc script.py

# 代码质量检查
flake8 src/
black src/
isort src/
mypy src/

# 测试覆盖率
pytest --cov=src tests/
coverage html
```

这些优化显著提升了Python规则文档的实用性，为开发者提供了更全面的指导和实际可用的代码示例！
```
```