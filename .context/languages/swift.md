# Swift 语言规则文档

## 语言特性

### 核心优势
- **类型安全**: 强类型系统，编译时类型检查
- **内存安全**: 自动内存管理，避免常见内存错误
- **性能优异**: 接近C语言的性能表现
- **现代语法**: 简洁优雅的语法设计
- **互操作性**: 与Objective-C无缝互操作

### Swift语言特性
```swift
// 类型推断和可选类型
var name: String = "张三"
var age: Int? = nil  // 可选类型

// 字符串插值
let message = "Hello, \(name)! You are \(age ?? 0) years old."

// 闭包表达式
let numbers = [1, 2, 3, 4, 5]
let doubled = numbers.map { $0 * 2 }
let filtered = numbers.filter { $0 > 2 }

// 枚举和关联值
enum Result<T, E> {
    case success(T)
    case failure(E)
}

// 协议和扩展
protocol Drawable {
    func draw()
}

extension String: Drawable {
    func draw() {
        print("Drawing: \(self)")
    }
}

// 泛型
func swap<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}

// 属性包装器
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

// 结构体和类
struct User {
    let id: UUID
    var name: String
    var email: String
    
    @UserDefault(key: "isFirstLaunch", defaultValue: true)
    static var isFirstLaunch: Bool
    
    init(name: String, email: String) {
        self.id = UUID()
        self.name = name
        self.email = email
    }
    
    mutating func updateName(_ newName: String) {
        self.name = newName
    }
}
```

## 开发环境和工具

### 开发工具
- **Xcode**: 官方IDE，功能最全面
- **AppCode**: JetBrains的Swift IDE
- **VS Code**: 轻量级编辑器，支持Swift插件
- **Swift Playgrounds**: 学习和原型开发工具

### 包管理器
```swift
// Swift Package Manager (SPM)
// Package.swift
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(name: "MyLibrary", targets: ["MyLibrary"]),
        .executable(name: "MyApp", targets: ["MyApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "MyLibrary",
            dependencies: ["Alamofire"]
        ),
        .executableTarget(
            name: "MyApp",
            dependencies: ["MyLibrary", "Alamofire"]
        ),
        .testTarget(
            name: "MyLibraryTests",
            dependencies: ["MyLibrary"]
        )
    ]
)
```

### 构建和测试
```swift
// 单元测试示例
import XCTest
@testable import MyApp

class UserTests: XCTestCase {
    
    func testUserCreation() {
        // Given
        let name = "张三"
        let email = "zhangsan@example.com"
        
        // When
        let user = User(name: name, email: email)
        
        // Then
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.email, email)
        XCTAssertNotNil(user.id)
    }
    
    func testUserNameUpdate() {
        // Given
        var user = User(name: "张三", email: "zhangsan@example.com")
        let newName = "李四"
        
        // When
        user.updateName(newName)
        
        // Then
        XCTAssertEqual(user.name, newName)
    }
    
    func testAsyncOperation() async throws {
        // Given
        let userService = UserService()
        let userId = "123"
        
        // When
        let user = try await userService.fetchUser(id: userId)
        
        // Then
        XCTAssertEqual(user.id, userId)
    }
}

// 性能测试
class PerformanceTests: XCTestCase {
    
    func testSortingPerformance() {
        let numbers = (1...10000).shuffled()
        
        measure {
            _ = numbers.sorted()
        }
    }
}
```

## iOS开发最佳实践

### SwiftUI开发
```swift
import SwiftUI
import Combine

// MVVM架构示例
class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userService: UserServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
    
    func loadUsers() {
        isLoading = true
        errorMessage = nil
        
        userService.fetchUsers()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] users in
                    self?.users = users
                }
            )
            .store(in: &cancellables)
    }
}

// SwiftUI视图
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var searchText = ""
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.users
        } else {
            return viewModel.users.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.loadUsers()
                    }
                } else {
                    List(filteredUsers) { user in
                        NavigationLink(destination: UserDetailView(user: user)) {
                            UserRowView(user: user)
                        }
                    }
                    .searchable(text: $searchText)
                    .refreshable {
                        viewModel.loadUsers()
                    }
                }
            }
            .navigationTitle("Users")
            .onAppear {
                viewModel.loadUsers()
            }
        }
    }
}

struct UserRowView: View {
    let user: User
    
    var body: some View {
        HStack {
            AsyncImage(url: user.avatarURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
```

### 网络编程
```swift
import Foundation
import Combine

// 网络服务协议
protocol UserServiceProtocol {
    func fetchUsers() -> AnyPublisher<[User], Error>
    func fetchUser(id: String) -> AnyPublisher<User, Error>
    func createUser(_ user: User) -> AnyPublisher<User, Error>
}

// 网络服务实现
class UserService: UserServiceProtocol {
    private let session = URLSession.shared
    private let baseURL = URL(string: "https://api.example.com")!
    
    func fetchUsers() -> AnyPublisher<[User], Error> {
        let url = baseURL.appendingPathComponent("users")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [User].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func fetchUser(id: String) -> AnyPublisher<User, Error> {
        let url = baseURL.appendingPathComponent("users/\(id)")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: User.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func createUser(_ user: User) -> AnyPublisher<User, Error> {
        let url = baseURL.appendingPathComponent("users")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(user)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: User.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

// 异步/等待版本
extension UserService {
    func fetchUsers() async throws -> [User] {
        let url = baseURL.appendingPathComponent("users")
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([User].self, from: data)
    }
    
    func fetchUser(id: String) async throws -> User {
        let url = baseURL.appendingPathComponent("users/\(id)")
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(User.self, from: data)
    }
}
```

## 代码规范和最佳实践

### 命名规范
```swift
// 类型命名：使用大驼峰命名法
class UserManager { }
struct UserProfile { }
enum NetworkError { }
protocol DataSource { }

// 变量和函数命名：使用小驼峰命名法
var userName: String
func fetchUserData() { }
let maxRetryCount = 3

// 常量命名：使用小驼峰命名法
let apiBaseURL = "https://api.example.com"
static let defaultTimeout: TimeInterval = 30

// 枚举case命名：使用小驼峰命名法
enum UserStatus {
    case active
    case inactive
    case suspended
}
```

### 错误处理
```swift
// 自定义错误类型
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingFailed
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingFailed:
            return "Failed to decode response"
        case .serverError(let code):
            return "Server error with code: \(code)"
        }
    }
}

// 错误处理最佳实践
func processUserData() {
    do {
        let users = try fetchUsers()
        let processedUsers = try processUsers(users)
        saveUsers(processedUsers)
    } catch NetworkError.invalidURL {
        showError("Invalid URL configuration")
    } catch NetworkError.noData {
        showError("No data available")
    } catch {
        showError("An unexpected error occurred: \(error.localizedDescription)")
    }
}

// Result类型使用
func fetchUserSafely(id: String) -> Result<User, NetworkError> {
    guard let url = URL(string: "https://api.example.com/users/\(id)") else {
        return .failure(.invalidURL)
    }
    
    // 网络请求逻辑
    // ...
    
    return .success(user)
}
```

### 内存管理
```swift
// 避免循环引用
class ViewController: UIViewController {
    var completion: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 使用weak self避免循环引用
        NetworkManager.shared.fetchData { [weak self] result in
            DispatchQueue.main.async {
                self?.handleResult(result)
            }
        }
    }
    
    private func handleResult(_ result: Result<Data, Error>) {
        // 处理结果
    }
}

// 使用unowned的场景
class Parent {
    var child: Child?
    
    init() {
        child = Child(parent: self)
    }
}

class Child {
    unowned let parent: Parent  // parent的生命周期总是比child长
    
    init(parent: Parent) {
        self.parent = parent
    }
}
```

## 性能优化

### 编译优化
```swift
// 编译器优化设置
// Build Settings中的优化选项：
// - Debug: -Onone (无优化，便于调试)
// - Release: -O (全优化)

// 使用@inlinable提示编译器内联
@inlinable
public func fastCalculation(_ x: Int, _ y: Int) -> Int {
    return x * y + x - y
}

// 使用@usableFromInline暴露内部实现
@usableFromInline
internal func internalHelper() -> Int {
    return 42
}
```

### 运行时优化
```swift
// 使用lazy属性延迟初始化
class DataManager {
    lazy var expensiveResource: ExpensiveResource = {
        return ExpensiveResource()
    }()
    
    // 使用computed property缓存
    private var _cachedValue: String?
    var cachedValue: String {
        if let cached = _cachedValue {
            return cached
        }
        let computed = performExpensiveCalculation()
        _cachedValue = computed
        return computed
    }
}

// 字符串优化
let staticString = "This is a static string"  // 存储在常量区
let interpolatedString = "Hello, \(name)"     // 动态创建

// 集合操作优化
let numbers = Array(1...1000)
let evenNumbers = numbers.lazy.filter { $0 % 2 == 0 }.map { $0 * 2 }
// lazy确保只在需要时才计算
```

## 常用框架和库

### 核心框架
- **Foundation**: 基础数据类型和工具
- **UIKit**: iOS用户界面框架
- **SwiftUI**: 声明式UI框架
- **Combine**: 响应式编程框架
- **Core Data**: 数据持久化框架

### 第三方库推荐
```swift
// 网络请求
import Alamofire

AF.request("https://api.example.com/users")
    .responseDecodable(of: [User].self) { response in
        switch response.result {
        case .success(let users):
            print("Received \(users.count) users")
        case .failure(let error):
            print("Error: \(error)")
        }
    }

// 图片加载
import Kingfisher

imageView.kf.setImage(with: URL(string: imageURL))

// JSON解析
import SwiftyJSON

let json = JSON(data)
let name = json["user"]["name"].stringValue
```

## 学习建议

### 基础学习路径
1. **Swift语法基础**: 变量、函数、控制流、面向对象
2. **iOS开发基础**: UIKit、视图控制器、界面布局
3. **数据处理**: JSON解析、网络请求、数据持久化
4. **高级特性**: 泛型、协议、扩展、错误处理

### 进阶学习重点
1. **SwiftUI**: 现代声明式UI开发
2. **Combine**: 响应式编程和数据流
3. **并发编程**: async/await、Actor模型
4. **性能优化**: 内存管理、编译优化

### 实践项目建议
1. **待办事项应用**: 学习基础UI和数据管理
2. **天气应用**: 学习网络请求和JSON解析
3. **社交应用**: 学习复杂UI和用户交互
4. **工具类应用**: 学习系统集成和高级特性

## 调试和测试

### 调试技巧
```swift
// 使用断点和LLDB
// po variable_name  // 打印对象
// p variable_name   // 打印变量值
// bt               // 查看调用栈

// 使用print和dump
print("Debug info: \(variable)")
dump(complexObject)  // 详细打印对象结构

// 条件编译
#if DEBUG
print("Debug mode enabled")
#endif

// 断言
assert(users.count > 0, "Users array should not be empty")
precondition(index < array.count, "Index out of bounds")
```

### 测试策略
```swift
// 单元测试
func testUserValidation() {
    let user = User(name: "", email: "invalid-email")
    XCTAssertFalse(user.isValid)
}

// UI测试
func testLoginFlow() {
    let app = XCUIApplication()
    app.launch()
    
    app.textFields["username"].tap()
    app.textFields["username"].typeText("testuser")
    
    app.secureTextFields["password"].tap()
    app.secureTextFields["password"].typeText("password")
    
    app.buttons["Login"].tap()
    
    XCTAssertTrue(app.staticTexts["Welcome"].exists)
}
```
