# Go 语言规则文档

## 语言特性

### 核心优势
- **简洁语法**: 简单易学的语法，减少认知负担
- **并发原生**: Goroutines和Channels提供强大的并发支持
- **快速编译**: 极快的编译速度，提高开发效率
- **静态类型**: 编译时类型检查，运行时性能优异
- **垃圾回收**: 自动内存管理，减少内存泄漏

### 并发编程
```go
package main

import (
    "fmt"
    "sync"
    "time"
)

// Goroutines 基础
func worker(id int, jobs <-chan int, results chan<- int) {
    for j := range jobs {
        fmt.Printf("Worker %d 开始处理任务 %d\n", id, j)
        time.Sleep(time.Second) // 模拟工作
        results <- j * 2
    }
}

func main() {
    const numJobs = 5
    jobs := make(chan int, numJobs)
    results := make(chan int, numJobs)

    // 启动3个worker goroutines
    for w := 1; w <= 3; w++ {
        go worker(w, jobs, results)
    }

    // 发送任务
    for j := 1; j <= numJobs; j++ {
        jobs <- j
    }
    close(jobs)

    // 收集结果
    for a := 1; a <= numJobs; a++ {
        <-results
    }
}

// WaitGroup 同步
func processWithWaitGroup() {
    var wg sync.WaitGroup

    for i := 0; i < 5; i++ {
        wg.Add(1)
        go func(id int) {
            defer wg.Done()
            fmt.Printf("Goroutine %d 完成\n", id)
            time.Sleep(time.Second)
        }(i)
    }

    wg.Wait()
    fmt.Println("所有goroutines完成")
}

// Context 上下文管理
import (
    "context"
    "net/http"
)

func fetchWithTimeout(url string) error {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return err
    }

    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    return nil
}

// Select 语句
func selectExample() {
    ch1 := make(chan string)
    ch2 := make(chan string)

    go func() {
        time.Sleep(1 * time.Second)
        ch1 <- "来自ch1的消息"
    }()

    go func() {
        time.Sleep(2 * time.Second)
        ch2 <- "来自ch2的消息"
    }()

    for i := 0; i < 2; i++ {
        select {
        case msg1 := <-ch1:
            fmt.Println("收到:", msg1)
        case msg2 := <-ch2:
            fmt.Println("收到:", msg2)
        case <-time.After(3 * time.Second):
            fmt.Println("超时")
            return
        }
    }
}
```

### 错误处理
```go
import (
    "errors"
    "fmt"
    "log"
)

// 自定义错误类型
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("验证错误 [%s]: %s", e.Field, e.Message)
}

// 错误包装
func processUser(user *User) error {
    if err := validateUser(user); err != nil {
        return fmt.Errorf("用户验证失败: %w", err)
    }

    if err := saveUser(user); err != nil {
        return fmt.Errorf("保存用户失败: %w", err)
    }

    return nil
}

func validateUser(user *User) error {
    if user.Name == "" {
        return &ValidationError{
            Field:   "name",
            Message: "姓名不能为空",
        }
    }

    if user.Email == "" {
        return &ValidationError{
            Field:   "email",
            Message: "邮箱不能为空",
        }
    }

    return nil
}

// 错误检查模式
func handleErrors() {
    user := &User{Name: "张三", Email: ""}

    if err := processUser(user); err != nil {
        var validationErr *ValidationError
        if errors.As(err, &validationErr) {
            log.Printf("验证错误: %s", validationErr.Message)
        } else {
            log.Printf("其他错误: %v", err)
        }
    }
}

// Panic 和 Recover
func safeDivide(a, b float64) (result float64, err error) {
    defer func() {
        if r := recover(); r != nil {
            err = fmt.Errorf("除法运算panic: %v", r)
        }
    }()

    if b == 0 {
        panic("除数不能为零")
    }

    result = a / b
    return
}
```

## 编码规范

### 命名约定
```go
package main

import "fmt"

// 包级别变量: camelCase (私有) 或 PascalCase (公有)
var serverPort = 8080        // 私有变量
var DefaultTimeout = 30      // 公有变量

// 常量: camelCase 或 PascalCase
const maxRetries = 3         // 私有常量
const APIVersion = "v1"      // 公有常量

// 结构体: PascalCase (公有) 或 camelCase (私有)
type User struct {           // 公有结构体
    ID       int    `json:"id"`
    Name     string `json:"name"`
    Email    string `json:"email"`
    password string // 私有字段
}

type userService struct {    // 私有结构体
    db Database
}

// 接口: PascalCase，通常以 -er 结尾
type UserRepository interface {
    Create(user *User) error
    FindByID(id int) (*User, error)
    Update(user *User) error
    Delete(id int) error
}

type Stringer interface {
    String() string
}

// 方法: camelCase (私有) 或 PascalCase (公有)
func (u *User) GetDisplayName() string {  // 公有方法
    return u.Name
}

func (u *User) validateEmail() bool {     // 私有方法
    return strings.Contains(u.Email, "@")
}

// 函数: camelCase (私有) 或 PascalCase (公有)
func CreateUser(name, email string) *User {  // 公有函数
    return &User{
        Name:  name,
        Email: email,
    }
}

func hashPassword(password string) string {  // 私有函数
    // 密码哈希逻辑
    return "hashed_" + password
}

// 包名: 小写，简短，有意义
// package userservice
// package httputil
// package stringutil
```

### 代码组织
```go
// user.go
package models

import (
    "time"
    "database/sql/driver"
    "encoding/json"
)

// User 表示系统用户
type User struct {
    ID        int       `json:"id" db:"id"`
    Name      string    `json:"name" db:"name" validate:"required,min=2,max=50"`
    Email     string    `json:"email" db:"email" validate:"required,email"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
    UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// NewUser 创建新用户实例
func NewUser(name, email string) *User {
    now := time.Now()
    return &User{
        Name:      name,
        Email:     email,
        CreatedAt: now,
        UpdatedAt: now,
    }
}

// Validate 验证用户数据
func (u *User) Validate() error {
    if u.Name == "" {
        return errors.New("姓名不能为空")
    }

    if len(u.Name) < 2 || len(u.Name) > 50 {
        return errors.New("姓名长度必须在2-50个字符之间")
    }

    if u.Email == "" {
        return errors.New("邮箱不能为空")
    }

    if !isValidEmail(u.Email) {
        return errors.New("邮箱格式不正确")
    }

    return nil
}

// String 实现 Stringer 接口
func (u *User) String() string {
    return fmt.Sprintf("User{ID: %d, Name: %s, Email: %s}", u.ID, u.Name, u.Email)
}

// MarshalJSON 自定义JSON序列化
func (u *User) MarshalJSON() ([]byte, error) {
    type Alias User
    return json.Marshal(&struct {
        *Alias
        CreatedAt string `json:"created_at"`
        UpdatedAt string `json:"updated_at"`
    }{
        Alias:     (*Alias)(u),
        CreatedAt: u.CreatedAt.Format(time.RFC3339),
        UpdatedAt: u.UpdatedAt.Format(time.RFC3339),
    })
}

// 私有辅助函数
func isValidEmail(email string) bool {
    // 简单的邮箱验证
    return strings.Contains(email, "@") && strings.Contains(email, ".")
}

// 接口定义
type UserService interface {
    CreateUser(user *User) error
    GetUserByID(id int) (*User, error)
    GetUserByEmail(email string) (*User, error)
    UpdateUser(user *User) error
    DeleteUser(id int) error
    ListUsers(limit, offset int) ([]*User, error)
}

// 实现结构体
type userService struct {
    repo UserRepository
    log  Logger
}

// NewUserService 创建用户服务实例
func NewUserService(repo UserRepository, log Logger) UserService {
    return &userService{
        repo: repo,
        log:  log,
    }
}

// CreateUser 创建用户
func (s *userService) CreateUser(user *User) error {
    if err := user.Validate(); err != nil {
        return fmt.Errorf("用户验证失败: %w", err)
    }

    // 检查邮箱是否已存在
    existing, err := s.repo.FindByEmail(user.Email)
    if err != nil {
        return fmt.Errorf("检查邮箱失败: %w", err)
    }

    if existing != nil {
        return errors.New("邮箱已存在")
    }

    if err := s.repo.Create(user); err != nil {
        s.log.Error("创建用户失败", "error", err, "user", user)
        return fmt.Errorf("创建用户失败: %w", err)
    }

    s.log.Info("用户创建成功", "user_id", user.ID, "email", user.Email)
    return nil
}
```

## 项目结构

### go.mod 配置
```go
module myproject

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/go-playground/validator/v10 v10.15.5
    github.com/golang-migrate/migrate/v4 v4.16.2
    github.com/jmoiron/sqlx v1.3.5
    github.com/lib/pq v1.10.9
    github.com/redis/go-redis/v9 v9.2.1
    github.com/spf13/viper v1.17.0
    github.com/stretchr/testify v1.8.4
    go.uber.org/zap v1.26.0
    golang.org/x/crypto v0.14.0
)

require (
    github.com/bytedance/sonic v1.9.1 // indirect
    github.com/chenzhuoyu/base64x v0.0.0-20221115062448-fe3a3abad311 // indirect
    github.com/gabriel-vasile/mimetype v1.4.2 // indirect
    github.com/gin-contrib/sse v0.1.0 // indirect
    github.com/go-playground/locales v0.14.1 // indirect
    github.com/go-playground/universal-translator v0.18.1 // indirect
    github.com/goccy/go-json v0.10.2 // indirect
    github.com/json-iterator/go v1.1.12 // indirect
    github.com/klauspost/cpuid/v2 v2.2.4 // indirect
    github.com/leodido/go-urn v1.2.4 // indirect
    github.com/mattn/go-isatty v0.0.19 // indirect
    github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
    github.com/modern-go/reflect2 v1.0.2 // indirect
    github.com/pelletier/go-toml/v2 v2.0.8 // indirect
    github.com/twitchyliquid64/golang-asm v0.15.1 // indirect
    github.com/ugorji/go/codec v1.2.11 // indirect
    go.uber.org/multierr v1.10.0 // indirect
    golang.org/x/arch v0.3.0 // indirect
    golang.org/x/net v0.10.0 // indirect
    golang.org/x/sys v0.13.0 // indirect
    golang.org/x/text v0.13.0 // indirect
    google.golang.org/protobuf v1.30.0 // indirect
    gopkg.in/yaml.v3 v3.0.1 // indirect
)
```

### 推荐目录结构
```
project/
├── cmd/                     # 应用程序入口
│   ├── server/
│   │   └── main.go
│   ├── worker/
│   │   └── main.go
│   └── migrate/
│       └── main.go
├── internal/                # 私有应用代码
│   ├── config/              # 配置
│   │   └── config.go
│   ├── models/              # 数据模型
│   │   ├── user.go
│   │   └── order.go
│   ├── services/            # 业务逻辑
│   │   ├── user_service.go
│   │   └── order_service.go
│   ├── repositories/        # 数据访问层
│   │   ├── interfaces.go
│   │   ├── user_repository.go
│   │   └── postgres/
│   │       └── user_repo.go
│   ├── handlers/            # HTTP处理器
│   │   ├── user_handler.go
│   │   └── middleware/
│   │       ├── auth.go
│   │       └── logging.go
│   ├── utils/               # 工具函数
│   │   ├── validator.go
│   │   └── crypto.go
│   └── errors/              # 错误定义
│       └── errors.go
├── pkg/                     # 可被外部使用的库代码
│   ├── logger/
│   │   └── logger.go
│   └── database/
│       └── postgres.go
├── api/                     # API定义
│   ├── openapi.yaml
│   └── proto/
├── web/                     # Web资源
│   ├── static/
│   └── templates/
├── scripts/                 # 脚本文件
│   ├── build.sh
│   └── deploy.sh
├── deployments/             # 部署配置
│   ├── docker/
│   └── k8s/
├── test/                    # 测试文件
│   ├── integration/
│   └── testdata/
├── docs/                    # 文档
├── .env.example
├── .gitignore
├── Dockerfile
├── Makefile
├── README.md
├── go.mod
└── go.sum
```