# C++ 语言规则文档

## 语言特性

### 核心优势
- **高性能**: 接近硬件的执行效率
- **零开销抽象**: 高级特性不影响运行时性能
- **内存控制**: 精确的内存管理和资源控制
- **多范式**: 支持面向对象、泛型、函数式编程
- **标准库丰富**: STL提供强大的容器和算法

### 现代C++特性 (C++11/14/17/20)
```cpp
#include <iostream>
#include <vector>
#include <memory>
#include <string>
#include <algorithm>
#include <functional>
#include <thread>
#include <future>
#include <chrono>
#include <optional>
#include <variant>
#include <ranges>

// 智能指针和RAII
class ResourceManager {
private:
    std::unique_ptr<int[]> data_;
    size_t size_;
    
public:
    // 构造函数
    explicit ResourceManager(size_t size) 
        : data_(std::make_unique<int[]>(size)), size_(size) {
        std::cout << "资源分配: " << size << " 个整数\n";
    }
    
    // 移动构造函数
    ResourceManager(ResourceManager&& other) noexcept
        : data_(std::move(other.data_)), size_(other.size_) {
        other.size_ = 0;
    }
    
    // 移动赋值运算符
    ResourceManager& operator=(ResourceManager&& other) noexcept {
        if (this != &other) {
            data_ = std::move(other.data_);
            size_ = other.size_;
            other.size_ = 0;
        }
        return *this;
    }
    
    // 删除拷贝构造和拷贝赋值
    ResourceManager(const ResourceManager&) = delete;
    ResourceManager& operator=(const ResourceManager&) = delete;
    
    // 析构函数
    ~ResourceManager() {
        if (data_) {
            std::cout << "资源释放: " << size_ << " 个整数\n";
        }
    }
    
    // 访问器
    int& operator[](size_t index) {
        if (index >= size_) {
            throw std::out_of_range("索引超出范围");
        }
        return data_[index];
    }
    
    size_t size() const noexcept { return size_; }
};

// Lambda表达式和函数对象
class LambdaExamples {
public:
    void demonstrateLambdas() {
        std::vector<int> numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
        
        // 基本lambda
        auto isEven = [](int n) { return n % 2 == 0; };
        
        // 捕获变量
        int threshold = 5;
        auto isGreaterThanThreshold = [threshold](int n) { 
            return n > threshold; 
        };
        
        // 可变lambda
        auto counter = [count = 0]() mutable { return ++count; };
        
        // 使用算法和lambda
        std::vector<int> evenNumbers;
        std::copy_if(numbers.begin(), numbers.end(), 
                    std::back_inserter(evenNumbers), isEven);
        
        // 范围for循环
        for (const auto& num : evenNumbers) {
            std::cout << num << " ";
        }
        std::cout << "\n";
        
        // C++20 ranges
        #if __cpp_lib_ranges >= 201911L
        auto evenGreaterThan5 = numbers 
            | std::views::filter(isEven)
            | std::views::filter(isGreaterThanThreshold);
        
        for (const auto& num : evenGreaterThan5) {
            std::cout << num << " ";
        }
        #endif
    }
};

// 模板和泛型编程
template<typename T>
class SafeVector {
private:
    std::vector<T> data_;
    
public:
    // 构造函数模板
    template<typename... Args>
    explicit SafeVector(Args&&... args) : data_(std::forward<Args>(args)...) {}
    
    // 类型安全的访问
    T& at(size_t index) {
        if (index >= data_.size()) {
            throw std::out_of_range("索引超出范围");
        }
        return data_[index];
    }
    
    const T& at(size_t index) const {
        if (index >= data_.size()) {
            throw std::out_of_range("索引超出范围");
        }
        return data_[index];
    }
    
    // 迭代器支持
    auto begin() { return data_.begin(); }
    auto end() { return data_.end(); }
    auto begin() const { return data_.begin(); }
    auto end() const { return data_.end(); }
    
    size_t size() const noexcept { return data_.size(); }
    bool empty() const noexcept { return data_.empty(); }
    
    // 添加元素
    template<typename U>
    void push_back(U&& value) {
        data_.push_back(std::forward<U>(value));
    }
    
    template<typename... Args>
    void emplace_back(Args&&... args) {
        data_.emplace_back(std::forward<Args>(args)...);
    }
};

// 概念和约束 (C++20)
#if __cpp_concepts >= 201907L
#include <concepts>

template<typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

template<Numeric T>
T add(T a, T b) {
    return a + b;
}

template<typename T>
concept Printable = requires(T t) {
    std::cout << t;
};

template<Printable T>
void print(const T& value) {
    std::cout << value << std::endl;
}
#endif

// 并发编程
class ConcurrencyExamples {
public:
    // 基本线程使用
    void basicThreadExample() {
        std::vector<std::thread> threads;
        
        for (int i = 0; i < 4; ++i) {
            threads.emplace_back([i]() {
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                std::cout << "线程 " << i << " 完成\n";
            });
        }
        
        // 等待所有线程完成
        for (auto& t : threads) {
            t.join();
        }
    }
    
    // 使用future和promise
    std::future<int> calculateAsync(int n) {
        return std::async(std::launch::async, [n]() {
            std::this_thread::sleep_for(std::chrono::seconds(1));
            return n * n;
        });
    }
    
    // 线程安全的计数器
    class ThreadSafeCounter {
    private:
        mutable std::mutex mutex_;
        int count_ = 0;
        
    public:
        void increment() {
            std::lock_guard<std::mutex> lock(mutex_);
            ++count_;
        }
        
        int get() const {
            std::lock_guard<std::mutex> lock(mutex_);
            return count_;
        }
    };
};

// 用户定义类型
class User {
private:
    std::string name_;
    std::string email_;
    int age_;
    
public:
    // 构造函数
    User(std::string name, std::string email, int age)
        : name_(std::move(name)), email_(std::move(email)), age_(age) {
        if (age_ < 0 || age_ > 150) {
            throw std::invalid_argument("年龄必须在0-150之间");
        }
    }
    
    // 访问器
    const std::string& getName() const noexcept { return name_; }
    const std::string& getEmail() const noexcept { return email_; }
    int getAge() const noexcept { return age_; }
    
    // 修改器
    void setName(const std::string& name) { name_ = name; }
    void setEmail(const std::string& email) { email_ = email; }
    void setAge(int age) {
        if (age < 0 || age > 150) {
            throw std::invalid_argument("年龄必须在0-150之间");
        }
        age_ = age;
    }
    
    // 比较运算符
    bool operator==(const User& other) const {
        return name_ == other.name_ && email_ == other.email_ && age_ == other.age_;
    }
    
    bool operator!=(const User& other) const {
        return !(*this == other);
    }
    
    // 输出运算符
    friend std::ostream& operator<<(std::ostream& os, const User& user) {
        os << "User{name: " << user.name_ 
           << ", email: " << user.email_ 
           << ", age: " << user.age_ << "}";
        return os;
    }
};

// 工厂模式示例
class UserFactory {
public:
    static std::unique_ptr<User> createUser(const std::string& name, 
                                          const std::string& email, 
                                          int age) {
        try {
            return std::make_unique<User>(name, email, age);
        } catch (const std::exception& e) {
            std::cerr << "创建用户失败: " << e.what() << std::endl;
            return nullptr;
        }
    }
    
    static std::vector<std::unique_ptr<User>> createUsers(
        const std::vector<std::tuple<std::string, std::string, int>>& userData) {
        
        std::vector<std::unique_ptr<User>> users;
        users.reserve(userData.size());
        
        for (const auto& [name, email, age] : userData) {
            if (auto user = createUser(name, email, age)) {
                users.push_back(std::move(user));
            }
        }
        
        return users;
    }
};
```

## 编码规范

### 命名约定
```cpp
// 类名: PascalCase
class UserManager {
private:
    // 私有成员变量: 下划线后缀
    std::string name_;
    int age_;
    
    // 静态常量: UPPER_SNAKE_CASE
    static const int MAX_AGE = 150;
    static constexpr double PI = 3.14159265359;
    
public:
    // 公有方法: camelCase
    void setUserName(const std::string& name);
    std::string getUserName() const;
    
    // 静态方法
    static UserManager createDefaultUser();
};

// 函数名: camelCase
void processUserData(const std::vector<User>& users);
bool validateEmail(const std::string& email);

// 变量名: camelCase
int userCount = 0;
std::string userName = "default";
auto currentTime = std::chrono::steady_clock::now();

// 常量: UPPER_SNAKE_CASE 或 kPascalCase
const int MAX_USERS = 1000;
constexpr int kDefaultBufferSize = 4096;

// 枚举: PascalCase
enum class Status {
    Pending,
    Active,
    Inactive,
    Deleted
};

// 命名空间: 小写，下划线分隔
namespace user_management {
namespace detail {
    // 内部实现
}
}

// 模板参数: PascalCase
template<typename T, typename Allocator = std::allocator<T>>
class Container {
    // 实现
};

// 宏: UPPER_SNAKE_CASE
#define MAX_BUFFER_SIZE 1024
#define ASSERT_NOT_NULL(ptr) assert((ptr) != nullptr)
```

### 代码组织
```cpp
// user.h - 头文件
#pragma once

#include <string>
#include <memory>
#include <vector>
#include <iosfwd>

namespace user_management {

/**
 * @brief 用户类，表示系统中的用户实体
 * 
 * 这个类封装了用户的基本信息，包括姓名、邮箱和年龄。
 * 提供了类型安全的访问方法和验证机制。
 * 
 * @author 开发者姓名
 * @version 1.0
 * @since 2024-01-01
 */
class User {
public:
    /**
     * @brief 构造一个新的用户对象
     * 
     * @param name 用户姓名，不能为空
     * @param email 用户邮箱，必须是有效的邮箱格式
     * @param age 用户年龄，必须在0-150之间
     * @throws std::invalid_argument 如果参数无效
     */
    User(std::string name, std::string email, int age);
    
    // 拷贝构造函数
    User(const User& other) = default;
    
    // 移动构造函数
    User(User&& other) noexcept = default;
    
    // 拷贝赋值运算符
    User& operator=(const User& other) = default;
    
    // 移动赋值运算符
    User& operator=(User&& other) noexcept = default;
    
    // 析构函数
    ~User() = default;
    
    // 访问器方法
    const std::string& getName() const noexcept;
    const std::string& getEmail() const noexcept;
    int getAge() const noexcept;
    
    // 修改器方法
    void setName(const std::string& name);
    void setEmail(const std::string& email);
    void setAge(int age);
    
    // 业务方法
    bool isAdult() const noexcept;
    std::string getDisplayName() const;
    
    // 比较运算符
    bool operator==(const User& other) const;
    bool operator!=(const User& other) const;
    bool operator<(const User& other) const;
    
    // 输出运算符
    friend std::ostream& operator<<(std::ostream& os, const User& user);

private:
    std::string name_;
    std::string email_;
    int age_;
    
    // 私有辅助方法
    void validateAge(int age) const;
    void validateEmail(const std::string& email) const;
};

/**
 * @brief 用户管理器类
 * 
 * 负责用户的创建、查找、更新和删除操作。
 * 提供线程安全的用户管理功能。
 */
class UserManager {
public:
    UserManager() = default;
    ~UserManager() = default;
    
    // 禁止拷贝
    UserManager(const UserManager&) = delete;
    UserManager& operator=(const UserManager&) = delete;
    
    // 允许移动
    UserManager(UserManager&&) = default;
    UserManager& operator=(UserManager&&) = default;
    
    // 用户管理方法
    std::shared_ptr<User> createUser(const std::string& name, 
                                   const std::string& email, 
                                   int age);
    
    std::shared_ptr<User> findUserByEmail(const std::string& email) const;
    
    std::vector<std::shared_ptr<User>> getAllUsers() const;
    
    bool updateUser(const std::string& email, const User& updatedUser);
    
    bool deleteUser(const std::string& email);
    
    size_t getUserCount() const noexcept;

private:
    mutable std::mutex mutex_;
    std::vector<std::shared_ptr<User>> users_;
    
    // 私有辅助方法
    auto findUserIterator(const std::string& email) const;
};

} // namespace user_management

// user.cpp - 实现文件
#include "user.h"
#include <stdexcept>
#include <regex>
#include <iostream>
#include <algorithm>
#include <mutex>

namespace user_management {

User::User(std::string name, std::string email, int age)
    : name_(std::move(name)), email_(std::move(email)), age_(age) {
    
    if (name_.empty()) {
        throw std::invalid_argument("姓名不能为空");
    }
    
    validateEmail(email_);
    validateAge(age_);
}

const std::string& User::getName() const noexcept {
    return name_;
}

const std::string& User::getEmail() const noexcept {
    return email_;
}

int User::getAge() const noexcept {
    return age_;
}

void User::setName(const std::string& name) {
    if (name.empty()) {
        throw std::invalid_argument("姓名不能为空");
    }
    name_ = name;
}

void User::setEmail(const std::string& email) {
    validateEmail(email);
    email_ = email;
}

void User::setAge(int age) {
    validateAge(age);
    age_ = age;
}

bool User::isAdult() const noexcept {
    return age_ >= 18;
}

std::string User::getDisplayName() const {
    return name_ + " (" + email_ + ")";
}

bool User::operator==(const User& other) const {
    return name_ == other.name_ && 
           email_ == other.email_ && 
           age_ == other.age_;
}

bool User::operator!=(const User& other) const {
    return !(*this == other);
}

bool User::operator<(const User& other) const {
    if (name_ != other.name_) {
        return name_ < other.name_;
    }
    if (email_ != other.email_) {
        return email_ < other.email_;
    }
    return age_ < other.age_;
}

std::ostream& operator<<(std::ostream& os, const User& user) {
    os << "User{name: \"" << user.name_ 
       << "\", email: \"" << user.email_ 
       << "\", age: " << user.age_ << "}";
    return os;
}

void User::validateAge(int age) const {
    if (age < 0 || age > 150) {
        throw std::invalid_argument("年龄必须在0-150之间");
    }
}

void User::validateEmail(const std::string& email) const {
    if (email.empty()) {
        throw std::invalid_argument("邮箱不能为空");
    }
    
    // 简单的邮箱格式验证
    const std::regex emailPattern(R"([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})");
    if (!std::regex_match(email, emailPattern)) {
        throw std::invalid_argument("邮箱格式不正确");
    }
}

// UserManager实现
std::shared_ptr<User> UserManager::createUser(const std::string& name, 
                                            const std::string& email, 
                                            int age) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 检查邮箱是否已存在
    if (findUserIterator(email) != users_.end()) {
        throw std::runtime_error("邮箱已存在: " + email);
    }
    
    auto user = std::make_shared<User>(name, email, age);
    users_.push_back(user);
    return user;
}

std::shared_ptr<User> UserManager::findUserByEmail(const std::string& email) const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = findUserIterator(email);
    return (it != users_.end()) ? *it : nullptr;
}

std::vector<std::shared_ptr<User>> UserManager::getAllUsers() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return users_;
}

bool UserManager::updateUser(const std::string& email, const User& updatedUser) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = findUserIterator(email);
    if (it != users_.end()) {
        **it = updatedUser;
        return true;
    }
    return false;
}

bool UserManager::deleteUser(const std::string& email) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = findUserIterator(email);
    if (it != users_.end()) {
        users_.erase(it);
        return true;
    }
    return false;
}

size_t UserManager::getUserCount() const noexcept {
    std::lock_guard<std::mutex> lock(mutex_);
    return users_.size();
}

auto UserManager::findUserIterator(const std::string& email) const {
    return std::find_if(users_.begin(), users_.end(),
        [&email](const std::shared_ptr<User>& user) {
            return user->getEmail() == email;
        });
}

} // namespace user_management
```

## 项目结构

### CMake配置
```cmake
cmake_minimum_required(VERSION 3.20)
project(UserManagement VERSION 1.0.0 LANGUAGES CXX)

# 设置C++标准
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 编译选项
if(MSVC)
    add_compile_options(/W4 /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

# 调试和发布配置
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -DDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

# 查找依赖
find_package(Threads REQUIRED)

# 可选依赖
find_package(Boost COMPONENTS system filesystem QUIET)
find_package(fmt QUIET)

# 包含目录
include_directories(include)

# 源文件
set(SOURCES
    src/user.cpp
    src/user_manager.cpp
    src/utils.cpp
)

# 头文件
set(HEADERS
    include/user.h
    include/user_manager.h
    include/utils.h
)

# 创建库
add_library(user_management ${SOURCES} ${HEADERS})

# 链接库
target_link_libraries(user_management 
    PRIVATE 
    Threads::Threads
)

if(Boost_FOUND)
    target_link_libraries(user_management PRIVATE Boost::system Boost::filesystem)
    target_compile_definitions(user_management PRIVATE HAVE_BOOST)
endif()

if(fmt_FOUND)
    target_link_libraries(user_management PRIVATE fmt::fmt)
    target_compile_definitions(user_management PRIVATE HAVE_FMT)
endif()

# 可执行文件
add_executable(user_app src/main.cpp)
target_link_libraries(user_app user_management)

# 测试
enable_testing()

# 查找Google Test
find_package(GTest QUIET)
if(GTest_FOUND)
    add_executable(user_tests
        tests/test_user.cpp
        tests/test_user_manager.cpp
    )
    
    target_link_libraries(user_tests
        user_management
        GTest::gtest
        GTest::gtest_main
    )
    
    add_test(NAME UserTests COMMAND user_tests)
endif()

# 安装规则
install(TARGETS user_management user_app
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES ${HEADERS} DESTINATION include/user_management)

# 包配置
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/UserManagementConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/UserManagementConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/UserManagementConfig.cmake"
    INSTALL_DESTINATION lib/cmake/UserManagement
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/UserManagementConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/UserManagementConfigVersion.cmake"
    DESTINATION lib/cmake/UserManagement
)
```

### 推荐目录结构
```
project/
├── CMakeLists.txt
├── README.md
├── LICENSE
├── .gitignore
├── include/                 # 公共头文件
│   ├── user.h
│   ├── user_manager.h
│   └── utils.h
├── src/                     # 源文件
│   ├── user.cpp
│   ├── user_manager.cpp
│   ├── utils.cpp
│   └── main.cpp
├── tests/                   # 测试文件
│   ├── test_user.cpp
│   ├── test_user_manager.cpp
│   └── test_utils.cpp
├── examples/                # 示例代码
│   └── basic_usage.cpp
├── docs/                    # 文档
│   ├── api.md
│   └── design.md
├── cmake/                   # CMake模块
│   └── UserManagementConfig.cmake.in
├── scripts/                 # 构建脚本
│   ├── build.sh
│   └── test.sh
└── third_party/            # 第三方库
    └── googletest/
```
