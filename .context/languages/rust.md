# Rust 语言规则文档

## 语言特性

### 核心优势
- **内存安全**: 编译时保证内存安全，无需垃圾回收
- **零成本抽象**: 高级抽象不会带来运行时开销
- **并发安全**: 类型系统防止数据竞争
- **性能优异**: 接近C/C++的性能表现
- **现代语法**: 表达力强的类型系统和模式匹配

### 所有权系统
```rust
// 所有权转移
fn take_ownership(s: String) {
    println!("{}", s);
} // s 在这里被销毁

fn main() {
    let s = String::from("hello");
    take_ownership(s); // s 的所有权被转移
    // println!("{}", s); // 编译错误：s 已被移动
}

// 借用和引用
fn calculate_length(s: &String) -> usize {
    s.len()
} // s 是引用，不会获取所有权

fn main() {
    let s1 = String::from("hello");
    let len = calculate_length(&s1); // 借用 s1
    println!("'{}' 的长度是 {}", s1, len); // s1 仍然有效
}

// 可变借用
fn change(s: &mut String) {
    s.push_str(", world");
}

fn main() {
    let mut s = String::from("hello");
    change(&mut s);
    println!("{}", s); // "hello, world"
}

// 生命周期
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

// 结构体中的生命周期
struct ImportantExcerpt<'a> {
    part: &'a str,
}

impl<'a> ImportantExcerpt<'a> {
    fn level(&self) -> i32 {
        3
    }
    
    fn announce_and_return_part(&self, announcement: &str) -> &str {
        println!("注意: {}", announcement);
        self.part
    }
}
```

### 错误处理
```rust
use std::fs::File;
use std::io::{self, Read};

// Result 类型
fn read_username_from_file() -> Result<String, io::Error> {
    let mut username_file = File::open("hello.txt")?;
    let mut username = String::new();
    username_file.read_to_string(&mut username)?;
    Ok(username)
}

// 自定义错误类型
#[derive(Debug)]
enum MyError {
    IoError(io::Error),
    ParseError(std::num::ParseIntError),
    CustomError(String),
}

impl From<io::Error> for MyError {
    fn from(error: io::Error) -> Self {
        MyError::IoError(error)
    }
}

impl From<std::num::ParseIntError> for MyError {
    fn from(error: std::num::ParseIntError) -> Self {
        MyError::ParseError(error)
    }
}

// 使用 ? 操作符
fn process_data() -> Result<i32, MyError> {
    let content = std::fs::read_to_string("data.txt")?;
    let number: i32 = content.trim().parse()?;
    
    if number < 0 {
        return Err(MyError::CustomError("数字不能为负".to_string()));
    }
    
    Ok(number * 2)
}

// Option 类型处理
fn find_user_by_id(users: &[User], id: u32) -> Option<&User> {
    users.iter().find(|user| user.id == id)
}

fn get_user_name(users: &[User], id: u32) -> String {
    match find_user_by_id(users, id) {
        Some(user) => user.name.clone(),
        None => "未知用户".to_string(),
    }
}
```

## 编码规范

### 命名约定
```rust
// 变量和函数: snake_case
let user_name = "张三";
let user_age = 25;

fn get_user_info() -> UserInfo {
    // 函数实现
}

fn calculate_total_price(items: &[Item]) -> f64 {
    // 计算逻辑
}

// 类型: PascalCase
struct UserProfile {
    name: String,
    email: String,
    age: u32,
}

enum OrderStatus {
    Pending,
    Confirmed,
    Shipped,
    Delivered,
}

// 常量: UPPER_SNAKE_CASE
const API_BASE_URL: &str = "https://api.example.com";
const MAX_RETRY_ATTEMPTS: u32 = 3;
const DEFAULT_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(30);

// 模块: snake_case
mod user_service;
mod order_management;
mod payment_processor;

// 特征 (Trait): PascalCase
trait Drawable {
    fn draw(&self);
}

trait Serializable {
    fn serialize(&self) -> String;
    fn deserialize(data: &str) -> Result<Self, String>
    where
        Self: Sized;
}
```

### 代码组织
```rust
// src/lib.rs 或 src/main.rs
use std::collections::HashMap;
use std::error::Error;
use std::fmt;

// 公共导入
pub use crate::models::{User, Order};
pub use crate::services::UserService;

// 模块声明
pub mod models;
pub mod services;
pub mod utils;
pub mod errors;

// 结构体定义
#[derive(Debug, Clone, PartialEq)]
pub struct User {
    pub id: u32,
    pub name: String,
    pub email: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

impl User {
    /// 创建新用户
    pub fn new(id: u32, name: String, email: String) -> Self {
        Self {
            id,
            name,
            email,
            created_at: chrono::Utc::now(),
        }
    }
    
    /// 验证邮箱格式
    pub fn validate_email(&self) -> bool {
        self.email.contains('@') && self.email.contains('.')
    }
    
    /// 获取用户显示名称
    pub fn display_name(&self) -> &str {
        &self.name
    }
}

// 特征实现
impl fmt::Display for User {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "User(id: {}, name: {})", self.id, self.name)
    }
}

// 泛型和特征约束
pub struct Repository<T> {
    items: HashMap<u32, T>,
}

impl<T> Repository<T>
where
    T: Clone + fmt::Debug,
{
    pub fn new() -> Self {
        Self {
            items: HashMap::new(),
        }
    }
    
    pub fn insert(&mut self, id: u32, item: T) {
        self.items.insert(id, item);
    }
    
    pub fn get(&self, id: u32) -> Option<&T> {
        self.items.get(&id)
    }
    
    pub fn remove(&mut self, id: u32) -> Option<T> {
        self.items.remove(&id)
    }
}

// 宏定义
macro_rules! create_user {
    ($name:expr, $email:expr) => {
        User::new(0, $name.to_string(), $email.to_string())
    };
    ($id:expr, $name:expr, $email:expr) => {
        User::new($id, $name.to_string(), $email.to_string())
    };
}
```

## 项目结构

### Cargo.toml 配置
```toml
[package]
name = "myproject"
version = "0.1.0"
edition = "2021"
authors = ["Your Name <your.email@example.com>"]
description = "Rust项目示例"
license = "MIT"
repository = "https://github.com/username/myproject"
keywords = ["web", "api", "rust"]
categories = ["web-programming"]

[dependencies]
# 异步运行时
tokio = { version = "1.0", features = ["full"] }

# Web框架
axum = "0.7"
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "trace"] }

# 序列化
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# 数据库
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "postgres", "chrono", "uuid"] }

# 日期时间
chrono = { version = "0.4", features = ["serde"] }

# UUID
uuid = { version = "1.0", features = ["v4", "serde"] }

# 错误处理
anyhow = "1.0"
thiserror = "1.0"

# 日志
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }

# 配置
config = "0.14"

# 密码哈希
argon2 = "0.5"

# JWT
jsonwebtoken = "9.0"

[dev-dependencies]
# 测试
tokio-test = "0.4"

[profile.release]
# 优化配置
opt-level = 3
lto = true
codegen-units = 1
panic = "abort"

[profile.dev]
# 开发配置
opt-level = 0
debug = true
```

### 推荐目录结构
```
project/
├── src/
│   ├── main.rs              # 应用入口
│   ├── lib.rs               # 库入口
│   ├── models/              # 数据模型
│   │   ├── mod.rs
│   │   ├── user.rs
│   │   └── order.rs
│   ├── services/            # 业务逻辑
│   │   ├── mod.rs
│   │   ├── user_service.rs
│   │   └── order_service.rs
│   ├── repositories/        # 数据访问
│   │   ├── mod.rs
│   │   └── user_repository.rs
│   ├── handlers/            # HTTP处理器
│   │   ├── mod.rs
│   │   ├── user_handler.rs
│   │   └── order_handler.rs
│   ├── middleware/          # 中间件
│   │   ├── mod.rs
│   │   ├── auth.rs
│   │   └── logging.rs
│   ├── utils/               # 工具函数
│   │   ├── mod.rs
│   │   ├── validation.rs
│   │   └── crypto.rs
│   ├── config/              # 配置
│   │   ├── mod.rs
│   │   └── settings.rs
│   └── errors/              # 错误定义
│       ├── mod.rs
│       └── app_error.rs
├── tests/                   # 集成测试
│   ├── common/
│   └── integration_test.rs
├── benches/                 # 性能测试
├── examples/                # 示例代码
├── docs/                    # 文档
├── migrations/              # 数据库迁移
├── Cargo.toml
├── Cargo.lock
└── README.md
```

## 测试策略

### 单元测试
```rust
// src/models/user.rs
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_creation() {
        let user = User::new(1, "张三".to_string(), "zhangsan@example.com".to_string());
        
        assert_eq!(user.id, 1);
        assert_eq!(user.name, "张三");
        assert_eq!(user.email, "zhangsan@example.com");
    }

    #[test]
    fn test_email_validation() {
        let valid_user = User::new(1, "张三".to_string(), "zhangsan@example.com".to_string());
        let invalid_user = User::new(2, "李四".to_string(), "invalid-email".to_string());
        
        assert!(valid_user.validate_email());
        assert!(!invalid_user.validate_email());
    }

    #[test]
    fn test_display_name() {
        let user = User::new(1, "王五".to_string(), "wangwu@example.com".to_string());
        assert_eq!(user.display_name(), "王五");
    }

    #[test]
    #[should_panic(expected = "邮箱格式不正确")]
    fn test_invalid_email_panic() {
        let user = User::new(1, "测试".to_string(), "invalid".to_string());
        if !user.validate_email() {
            panic!("邮箱格式不正确");
        }
    }
}

// 属性测试 (使用 proptest)
#[cfg(test)]
mod property_tests {
    use super::*;
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn test_user_name_not_empty(name in "[a-zA-Z\u4e00-\u9fa5]{1,50}") {
            let user = User::new(1, name.clone(), "test@example.com".to_string());
            assert_eq!(user.name, name);
            assert!(!user.name.is_empty());
        }

        #[test]
        fn test_user_id_positive(id in 1u32..1000000u32) {
            let user = User::new(id, "测试".to_string(), "test@example.com".to_string());
            assert_eq!(user.id, id);
            assert!(user.id > 0);
        }
    }
}
```

### 异步测试
```rust
// tests/integration_test.rs
use tokio_test;
use myproject::services::UserService;
use myproject::models::User;

#[tokio::test]
async fn test_async_user_creation() {
    let service = UserService::new().await;
    
    let user_data = CreateUserRequest {
        name: "异步测试用户".to_string(),
        email: "async@example.com".to_string(),
    };
    
    let result = service.create_user(user_data).await;
    
    assert!(result.is_ok());
    let user = result.unwrap();
    assert_eq!(user.name, "异步测试用户");
}

#[tokio::test]
async fn test_concurrent_user_creation() {
    let service = UserService::new().await;
    
    let tasks: Vec<_> = (0..10)
        .map(|i| {
            let service = service.clone();
            tokio::spawn(async move {
                let user_data = CreateUserRequest {
                    name: format!("用户{}", i),
                    email: format!("user{}@example.com", i),
                };
                service.create_user(user_data).await
            })
        })
        .collect();
    
    let results = futures::future::join_all(tasks).await;
    
    for result in results {
        assert!(result.is_ok());
        assert!(result.unwrap().is_ok());
    }
}

// 模拟测试
#[cfg(test)]
mod mock_tests {
    use super::*;
    use mockall::predicate::*;
    use mockall::mock;

    mock! {
        UserRepository {}
        
        #[async_trait]
        impl UserRepositoryTrait for UserRepository {
            async fn create(&self, user: CreateUserRequest) -> Result<User, AppError>;
            async fn find_by_id(&self, id: u32) -> Result<Option<User>, AppError>;
            async fn find_by_email(&self, email: &str) -> Result<Option<User>, AppError>;
        }
    }

    #[tokio::test]
    async fn test_user_service_with_mock() {
        let mut mock_repo = MockUserRepository::new();
        
        mock_repo
            .expect_create()
            .with(predicate::always())
            .times(1)
            .returning(|req| {
                Ok(User::new(1, req.name, req.email))
            });
        
        let service = UserService::new_with_repository(Box::new(mock_repo));
        
        let user_data = CreateUserRequest {
            name: "模拟测试".to_string(),
            email: "mock@example.com".to_string(),
        };
        
        let result = service.create_user(user_data).await;
        assert!(result.is_ok());
    }
}
```

## 性能优化

### 内存管理
```rust
use std::rc::Rc;
use std::sync::Arc;
use std::cell::RefCell;

// 使用 Rc 进行引用计数 (单线程)
fn share_data_single_thread() {
    let data = Rc::new(vec![1, 2, 3, 4, 5]);
    let data1 = Rc::clone(&data);
    let data2 = Rc::clone(&data);
    
    println!("引用计数: {}", Rc::strong_count(&data)); // 3
}

// 使用 Arc 进行原子引用计数 (多线程)
use std::thread;

fn share_data_multi_thread() {
    let data = Arc::new(vec![1, 2, 3, 4, 5]);
    let mut handles = vec![];
    
    for i in 0..3 {
        let data = Arc::clone(&data);
        let handle = thread::spawn(move || {
            println!("线程 {} 访问数据: {:?}", i, data);
        });
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
}

// 零拷贝字符串处理
use std::borrow::Cow;

fn process_string(input: &str) -> Cow<str> {
    if input.contains("需要替换") {
        Cow::Owned(input.replace("需要替换", "已替换"))
    } else {
        Cow::Borrowed(input)
    }
}

// 内存池模式
struct ObjectPool<T> {
    objects: Vec<T>,
    create_fn: Box<dyn Fn() -> T>,
}

impl<T> ObjectPool<T> {
    fn new<F>(create_fn: F) -> Self
    where
        F: Fn() -> T + 'static,
    {
        Self {
            objects: Vec::new(),
            create_fn: Box::new(create_fn),
        }
    }
    
    fn get(&mut self) -> T {
        self.objects.pop().unwrap_or_else(|| (self.create_fn)())
    }
    
    fn return_object(&mut self, obj: T) {
        self.objects.push(obj);
    }
}
```

### 并发优化
```rust
use tokio::sync::{Mutex, RwLock, Semaphore};
use std::sync::Arc;

// 读写锁优化
struct UserCache {
    users: Arc<RwLock<HashMap<u32, User>>>,
}

impl UserCache {
    async fn get_user(&self, id: u32) -> Option<User> {
        let users = self.users.read().await;
        users.get(&id).cloned()
    }
    
    async fn insert_user(&self, user: User) {
        let mut users = self.users.write().await;
        users.insert(user.id, user);
    }
}

// 信号量限制并发
async fn process_with_concurrency_limit(items: Vec<Item>) -> Vec<Result<ProcessedItem, Error>> {
    let semaphore = Arc::new(Semaphore::new(10)); // 最多10个并发
    let tasks: Vec<_> = items
        .into_iter()
        .map(|item| {
            let semaphore = semaphore.clone();
            tokio::spawn(async move {
                let _permit = semaphore.acquire().await.unwrap();
                process_item(item).await
            })
        })
        .collect();
    
    futures::future::join_all(tasks)
        .await
        .into_iter()
        .map(|result| result.unwrap())
        .collect()
}

// 通道进行异步通信
use tokio::sync::mpsc;

async fn producer_consumer_pattern() {
    let (tx, mut rx) = mpsc::channel::<String>(100);
    
    // 生产者
    let producer = tokio::spawn(async move {
        for i in 0..10 {
            let message = format!("消息 {}", i);
            if tx.send(message).await.is_err() {
                break;
            }
        }
    });
    
    // 消费者
    let consumer = tokio::spawn(async move {
        while let Some(message) = rx.recv().await {
            println!("收到: {}", message);
            // 处理消息
        }
    });
    
    let _ = tokio::join!(producer, consumer);
}
```

## 安全实践

### 内存安全
```rust
// 避免悬垂指针
fn safe_reference_handling() {
    let mut data = vec![1, 2, 3];
    
    // 安全：借用检查器确保引用有效
    let first = &data[0];
    println!("第一个元素: {}", first);
    
    // data.push(4); // 编译错误：不能在存在不可变借用时修改
}

// 线程安全
use std::sync::{Arc, Mutex};
use std::thread;

fn thread_safe_counter() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];
    
    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            let mut num = counter.lock().unwrap();
            *num += 1;
        });
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
    
    println!("结果: {}", *counter.lock().unwrap());
}

// 输入验证
use regex::Regex;

fn validate_email(email: &str) -> Result<(), ValidationError> {
    let email_regex = Regex::new(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").unwrap();
    
    if email.is_empty() {
        return Err(ValidationError::EmptyEmail);
    }
    
    if email.len() > 254 {
        return Err(ValidationError::EmailTooLong);
    }
    
    if !email_regex.is_match(email) {
        return Err(ValidationError::InvalidEmailFormat);
    }
    
    Ok(())
}

// 密码安全
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use argon2::password_hash::{rand_core::OsRng, SaltString};

pub fn hash_password(password: &str) -> Result<String, argon2::password_hash::Error> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = argon2.hash_password(password.as_bytes(), &salt)?;
    Ok(password_hash.to_string())
}

pub fn verify_password(password: &str, hash: &str) -> Result<bool, argon2::password_hash::Error> {
    let parsed_hash = PasswordHash::new(hash)?;
    let argon2 = Argon2::default();
    Ok(argon2.verify_password(password.as_bytes(), &parsed_hash).is_ok())
}
```

## 生态系统

### 常用 Crates
```rust
// Web 开发
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};

// 异步运行时
use tokio::{
    fs::File,
    io::{AsyncReadExt, AsyncWriteExt},
    net::TcpListener,
    time::{sleep, Duration},
};

// 序列化
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
struct ApiResponse<T> {
    success: bool,
    data: Option<T>,
    error: Option<String>,
}

// 数据库
use sqlx::{PgPool, Row};

async fn get_user_from_db(pool: &PgPool, id: i32) -> Result<User, sqlx::Error> {
    let row = sqlx::query("SELECT id, name, email FROM users WHERE id = $1")
        .bind(id)
        .fetch_one(pool)
        .await?;
    
    Ok(User {
        id: row.get("id"),
        name: row.get("name"),
        email: row.get("email"),
    })
}

// HTTP 客户端
use reqwest::Client;

async fn fetch_external_data() -> Result<ApiResponse<String>, reqwest::Error> {
    let client = Client::new();
    let response = client
        .get("https://api.example.com/data")
        .header("Authorization", "Bearer token")
        .send()
        .await?;
    
    response.json().await
}

// 配置管理
use config::{Config, ConfigError, Environment, File};

#[derive(Debug, Deserialize)]
struct Settings {
    database_url: String,
    server_port: u16,
    log_level: String,
}

impl Settings {
    pub fn new() -> Result<Self, ConfigError> {
        let s = Config::builder()
            .add_source(File::with_name("config/default"))
            .add_source(Environment::with_prefix("APP"))
            .build()?;
        
        s.try_deserialize()
    }
}
```
