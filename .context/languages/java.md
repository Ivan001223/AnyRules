# Java 语言规则文档

## 语言特性

### 核心优势
- **跨平台**: "一次编写，到处运行"的平台无关性
- **面向对象**: 完整的面向对象编程支持
- **内存管理**: 自动垃圾回收，减少内存泄漏
- **强类型**: 编译时类型检查，提高代码安全性
- **丰富生态**: 庞大的第三方库和框架生态

### 现代Java特性 (Java 8+)
```java
import java.util.*;
import java.util.stream.*;
import java.util.concurrent.*;
import java.time.*;
import java.util.function.*;

// Lambda表达式和函数式接口
public class ModernJavaFeatures {
    
    // 函数式接口示例
    @FunctionalInterface
    interface UserProcessor {
        User process(User user);
    }
    
    // Stream API使用
    public List<String> processUserNames(List<User> users) {
        return users.stream()
            .filter(user -> user.getAge() >= 18)  // 过滤成年用户
            .map(User::getName)                   // 提取姓名
            .map(String::toUpperCase)             // 转换为大写
            .sorted()                             // 排序
            .collect(Collectors.toList());        // 收集结果
    }
    
    // Optional使用避免空指针
    public Optional<User> findUserByEmail(String email) {
        return userRepository.findByEmail(email);
    }
    
    public String getUserDisplayName(String email) {
        return findUserByEmail(email)
            .map(User::getName)
            .orElse("未知用户");
    }
    
    // 时间API (Java 8+)
    public void demonstrateTimeAPI() {
        LocalDateTime now = LocalDateTime.now();
        LocalDate birthday = LocalDate.of(1990, Month.JANUARY, 1);
        
        // 计算年龄
        long age = ChronoUnit.YEARS.between(birthday, now.toLocalDate());
        
        // 格式化时间
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        String formattedTime = now.format(formatter);
        
        // 时区处理
        ZonedDateTime utcTime = ZonedDateTime.now(ZoneOffset.UTC);
        ZonedDateTime beijingTime = utcTime.withZoneSameInstant(ZoneId.of("Asia/Shanghai"));
    }
    
    // 并行流处理
    public Map<String, Long> countUsersByCity(List<User> users) {
        return users.parallelStream()
            .collect(Collectors.groupingBy(
                User::getCity,
                Collectors.counting()
            ));
    }
    
    // CompletableFuture异步编程
    public CompletableFuture<String> processUserAsync(Long userId) {
        return CompletableFuture
            .supplyAsync(() -> userService.findById(userId))
            .thenCompose(user -> emailService.sendWelcomeEmailAsync(user))
            .thenApply(result -> "处理完成: " + result)
            .exceptionally(throwable -> {
                log.error("处理用户失败", throwable);
                return "处理失败";
            });
    }
}

// 记录类 (Java 14+)
public record UserDTO(
    Long id,
    String name,
    String email,
    LocalDateTime createdAt
) {
    // 紧凑构造器
    public UserDTO {
        Objects.requireNonNull(name, "姓名不能为空");
        Objects.requireNonNull(email, "邮箱不能为空");
        if (name.trim().isEmpty()) {
            throw new IllegalArgumentException("姓名不能为空字符串");
        }
    }
    
    // 自定义方法
    public String getDisplayName() {
        return name.toUpperCase();
    }
}

// 密封类 (Java 17+)
public sealed class Shape
    permits Circle, Rectangle, Triangle {
    
    public abstract double area();
}

public final class Circle extends Shape {
    private final double radius;
    
    public Circle(double radius) {
        this.radius = radius;
    }
    
    @Override
    public double area() {
        return Math.PI * radius * radius;
    }
}

// 模式匹配 (Java 17+)
public class PatternMatching {
    public String describeShape(Shape shape) {
        return switch (shape) {
            case Circle c -> "圆形，半径: " + c.getRadius();
            case Rectangle r -> "矩形，面积: " + r.area();
            case Triangle t -> "三角形，面积: " + t.area();
        };
    }
}
```

## 编码规范

### 命名约定
```java
// 类名: PascalCase
public class UserService {
    
    // 常量: UPPER_SNAKE_CASE
    private static final String DEFAULT_ENCODING = "UTF-8";
    private static final int MAX_RETRY_ATTEMPTS = 3;
    
    // 变量和方法: camelCase
    private UserRepository userRepository;
    private EmailService emailService;
    
    public User createUser(CreateUserRequest request) {
        return processUserCreation(request);
    }
    
    private User processUserCreation(CreateUserRequest request) {
        // 实现逻辑
        return new User();
    }
}

// 接口名: PascalCase，通常以形容词或能力结尾
public interface Serializable {
    void serialize();
}

public interface UserRepository {
    Optional<User> findById(Long id);
    List<User> findByName(String name);
}

// 枚举: PascalCase
public enum OrderStatus {
    PENDING("待处理"),
    CONFIRMED("已确认"),
    SHIPPED("已发货"),
    DELIVERED("已送达"),
    CANCELLED("已取消");
    
    private final String description;
    
    OrderStatus(String description) {
        this.description = description;
    }
    
    public String getDescription() {
        return description;
    }
}

// 包名: 小写，使用域名倒序
// com.company.project.module
package com.example.userservice.domain;
```

### 代码组织
```java
// User.java - 实体类
package com.example.userservice.domain;

import javax.persistence.*;
import javax.validation.constraints.*;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * 用户实体类
 * 
 * @author 开发者姓名
 * @version 1.0
 * @since 2024-01-01
 */
@Entity
@Table(name = "users")
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 50)
    @NotBlank(message = "姓名不能为空")
    @Size(min = 2, max = 50, message = "姓名长度必须在2-50个字符之间")
    private String name;
    
    @Column(nullable = false, unique = true, length = 100)
    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    private String email;
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    // 默认构造器
    protected User() {
        // JPA需要
    }
    
    // 业务构造器
    public User(String name, String email) {
        this.name = Objects.requireNonNull(name, "姓名不能为空");
        this.email = Objects.requireNonNull(email, "邮箱不能为空");
        this.createdAt = LocalDateTime.now();
    }
    
    // Getter和Setter
    public Long getId() {
        return id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = Objects.requireNonNull(name, "姓名不能为空");
        this.updatedAt = LocalDateTime.now();
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = Objects.requireNonNull(email, "邮箱不能为空");
        this.updatedAt = LocalDateTime.now();
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    // 业务方法
    public void updateProfile(String newName, String newEmail) {
        setName(newName);
        setEmail(newEmail);
    }
    
    public boolean isRecentlyCreated() {
        return createdAt.isAfter(LocalDateTime.now().minusDays(7));
    }
    
    // equals和hashCode
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(id, user.id);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
    
    // toString
    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", email='" + email + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }
}

// UserService.java - 服务类
package com.example.userservice.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
@Transactional
public class UserService {
    
    private static final Logger logger = LoggerFactory.getLogger(UserService.class);
    
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final UserValidator userValidator;
    
    // 构造器注入
    public UserService(UserRepository userRepository, 
                      EmailService emailService,
                      UserValidator userValidator) {
        this.userRepository = userRepository;
        this.emailService = emailService;
        this.userValidator = userValidator;
    }
    
    /**
     * 创建新用户
     * 
     * @param request 用户创建请求
     * @return 创建的用户
     * @throws UserAlreadyExistsException 如果邮箱已存在
     * @throws ValidationException 如果数据验证失败
     */
    public User createUser(CreateUserRequest request) {
        logger.info("开始创建用户: {}", request.getEmail());
        
        // 验证请求数据
        userValidator.validateCreateRequest(request);
        
        // 检查邮箱是否已存在
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new UserAlreadyExistsException("邮箱已存在: " + request.getEmail());
        }
        
        // 创建用户
        User user = new User(request.getName(), request.getEmail());
        User savedUser = userRepository.save(user);
        
        // 发送欢迎邮件
        try {
            emailService.sendWelcomeEmail(savedUser);
        } catch (Exception e) {
            logger.warn("发送欢迎邮件失败: {}", savedUser.getEmail(), e);
            // 不影响用户创建流程
        }
        
        logger.info("用户创建成功: {}", savedUser.getId());
        return savedUser;
    }
    
    /**
     * 根据ID查找用户
     * 
     * @param id 用户ID
     * @return 用户信息
     * @throws UserNotFoundException 如果用户不存在
     */
    @Transactional(readOnly = true)
    public User findById(Long id) {
        return userRepository.findById(id)
            .orElseThrow(() -> new UserNotFoundException("用户不存在: " + id));
    }
    
    /**
     * 更新用户信息
     * 
     * @param id 用户ID
     * @param request 更新请求
     * @return 更新后的用户
     */
    public User updateUser(Long id, UpdateUserRequest request) {
        logger.info("开始更新用户: {}", id);
        
        User user = findById(id);
        
        // 验证更新数据
        userValidator.validateUpdateRequest(request);
        
        // 检查邮箱唯一性（如果邮箱有变更）
        if (!user.getEmail().equals(request.getEmail()) && 
            userRepository.existsByEmail(request.getEmail())) {
            throw new UserAlreadyExistsException("邮箱已存在: " + request.getEmail());
        }
        
        // 更新用户信息
        user.updateProfile(request.getName(), request.getEmail());
        User updatedUser = userRepository.save(user);
        
        logger.info("用户更新成功: {}", updatedUser.getId());
        return updatedUser;
    }
}
```

## 项目结构

### Maven配置
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.example</groupId>
    <artifactId>user-service</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <name>User Service</name>
    <description>用户管理服务</description>
    
    <properties>
        <java.version>17</java.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        
        <!-- 依赖版本 -->
        <mapstruct.version>1.5.5.Final</mapstruct.version>
        <testcontainers.version>1.19.3</testcontainers.version>
    </properties>
    
    <dependencies>
        <!-- Spring Boot Starters -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        
        <!-- 数据库 -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>test</scope>
        </dependency>
        
        <!-- 对象映射 -->
        <dependency>
            <groupId>org.mapstruct</groupId>
            <artifactId>mapstruct</artifactId>
            <version>${mapstruct.version}</version>
        </dependency>
        
        <!-- 工具库 -->
        <dependency>
            <groupId>org.apache.commons</groupId>
            <artifactId>commons-lang3</artifactId>
        </dependency>
        
        <!-- 测试依赖 -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>${testcontainers.version}</version>
            <scope>test</scope>
        </dependency>
        
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>postgresql</artifactId>
            <version>${testcontainers.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
            
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.mapstruct</groupId>
                            <artifactId>mapstruct-processor</artifactId>
                            <version>${mapstruct.version}</version>
                        </path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
            
            <plugin>
                <groupId>org.jacoco</groupId>
                <artifactId>jacoco-maven-plugin</artifactId>
                <version>0.8.8</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>prepare-agent</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>report</id>
                        <phase>test</phase>
                        <goals>
                            <goal>report</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

### 推荐目录结构
```
src/
├── main/
│   ├── java/
│   │   └── com/example/userservice/
│   │       ├── UserServiceApplication.java
│   │       ├── config/              # 配置类
│   │       │   ├── DatabaseConfig.java
│   │       │   ├── SecurityConfig.java
│   │       │   └── WebConfig.java
│   │       ├── controller/          # 控制器层
│   │       │   ├── UserController.java
│   │       │   └── advice/
│   │       │       └── GlobalExceptionHandler.java
│   │       ├── service/             # 服务层
│   │       │   ├── UserService.java
│   │       │   ├── EmailService.java
│   │       │   └── impl/
│   │       │       ├── UserServiceImpl.java
│   │       │       └── EmailServiceImpl.java
│   │       ├── repository/          # 数据访问层
│   │       │   └── UserRepository.java
│   │       ├── domain/              # 领域模型
│   │       │   ├── User.java
│   │       │   └── Order.java
│   │       ├── dto/                 # 数据传输对象
│   │       │   ├── request/
│   │       │   │   ├── CreateUserRequest.java
│   │       │   │   └── UpdateUserRequest.java
│   │       │   └── response/
│   │       │       └── UserResponse.java
│   │       ├── mapper/              # 对象映射
│   │       │   └── UserMapper.java
│   │       ├── exception/           # 异常定义
│   │       │   ├── UserNotFoundException.java
│   │       │   └── UserAlreadyExistsException.java
│   │       ├── validation/          # 验证器
│   │       │   └── UserValidator.java
│   │       └── util/                # 工具类
│   │           └── DateUtils.java
│   └── resources/
│       ├── application.yml
│       ├── application-dev.yml
│       ├── application-prod.yml
│       ├── db/migration/            # Flyway迁移脚本
│       │   ├── V1__Create_users_table.sql
│       │   └── V2__Add_user_indexes.sql
│       └── static/
└── test/
    ├── java/
    │   └── com/example/userservice/
    │       ├── UserServiceApplicationTests.java
    │       ├── controller/
    │       │   └── UserControllerTest.java
    │       ├── service/
    │       │   └── UserServiceTest.java
    │       ├── repository/
    │       │   └── UserRepositoryTest.java
    │       └── integration/
    │           └── UserIntegrationTest.java
    └── resources/
        ├── application-test.yml
        └── test-data.sql
```
