# Dart 语言规则文档

## 语言特性

### 核心优势
- **现代语法**: 简洁优雅的现代语言语法
- **强类型系统**: 静态类型检查，支持类型推断
- **异步编程**: 内置Future和Stream支持
- **跨平台**: 支持移动、Web、桌面和服务器开发
- **高性能**: AOT和JIT编译，性能优异

### Dart语言特性
```dart
// 变量声明和类型推断
String name = '张三';
var age = 25;  // 类型推断为int
int? nullableAge;  // 可空类型
late String lateInitialized;  // 延迟初始化

// 字符串插值
String message = 'Hello, $name! You are $age years old.';
String detailed = 'User info: ${user.name} (${user.email})';

// 集合类型
List<String> users = ['张三', '李四', '王五'];
Map<String, dynamic> userInfo = {
  'name': '张三',
  'email': 'zhangsan@example.com',
  'age': 25,
};
Set<String> uniqueEmails = {'user1@example.com', 'user2@example.com'};

// 函数定义
String greetUser(String name, {int age = 0, bool isVip = false}) {
  return 'Hello, $name! Age: $age, VIP: $isVip';
}

// 箭头函数
List<int> doubleNumbers(List<int> numbers) => 
    numbers.map((n) => n * 2).toList();

// 类定义
class User {
  final String id;
  String name;
  String email;
  DateTime? birthDate;
  
  // 构造函数
  User(this.id, this.name, this.email, {this.birthDate});
  
  // 命名构造函数
  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        email = json['email'],
        birthDate = json['birth_date'] != null 
            ? DateTime.parse(json['birth_date']) 
            : null;
  
  // Getter
  bool get isAdult => birthDate != null && 
      DateTime.now().difference(birthDate!).inDays > 365 * 18;
  
  // 方法
  bool isValidEmail() {
    return email.contains('@') && email.contains('.');
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'birth_date': birthDate?.toIso8601String(),
  };
  
  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}

// 抽象类和接口
abstract class Animal {
  String get name;
  void makeSound();
  
  // 具体方法
  void sleep() {
    print('$name is sleeping');
  }
}

// 混入 (Mixin)
mixin Flyable {
  void fly() {
    print('Flying...');
  }
}

class Bird extends Animal with Flyable {
  @override
  final String name;
  
  Bird(this.name);
  
  @override
  void makeSound() {
    print('$name is chirping');
  }
}

// 枚举
enum UserStatus {
  active,
  inactive,
  suspended;
  
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return '活跃';
      case UserStatus.inactive:
        return '非活跃';
      case UserStatus.suspended:
        return '已暂停';
    }
  }
}

// 异步编程
Future<User> fetchUser(String id) async {
  try {
    final response = await http.get(Uri.parse('https://api.example.com/users/$id'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return User.fromJson(json);
    } else {
      throw Exception('Failed to load user');
    }
  } catch (e) {
    print('Error fetching user: $e');
    rethrow;
  }
}

// Stream处理
Stream<User> getUserStream() async* {
  for (int i = 1; i <= 10; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield User('$i', 'User $i', 'user$i@example.com');
  }
}

// 泛型
class Repository<T> {
  final List<T> _items = [];
  
  void add(T item) => _items.add(item);
  
  List<T> getAll() => List.unmodifiable(_items);
  
  T? findById(String id, String Function(T) getId) {
    try {
      return _items.firstWhere((item) => getId(item) == id);
    } catch (e) {
      return null;
    }
  }
  
  void removeWhere(bool Function(T) test) {
    _items.removeWhere(test);
  }
}

// 扩展方法
extension StringExtensions on String {
  bool get isValidEmail => contains('@') && contains('.');
  
  String get capitalize => 
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}...';
}

extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
  
  List<T> get unique => toSet().toList();
}
```

## Flutter开发最佳实践

### Widget构建
```dart
// StatelessWidget
class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;
  
  const UserCard({
    Key? key,
    required this.user,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(user.name[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (user.isAdult) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '成年人',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// StatefulWidget
class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);
  
  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final users = await UserService.getUsers();
      setState(() {
        _users.clear();
        _users.addAll(users);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  List<User> get _filteredUsers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _users;
    
    return _users.where((user) =>
        user.name.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query)
    ).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索用户...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddUser(),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('错误: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    final filteredUsers = _filteredUsers;
    
    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text('没有找到用户'),
      );
    }
    
    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return UserCard(
          user: user,
          onTap: () => _navigateToUserDetail(user),
        );
      },
    );
  }
  
  void _navigateToUserDetail(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    );
  }
  
  void _navigateToAddUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddUserScreen(),
      ),
    );
    
    if (result == true) {
      _loadUsers();
    }
  }
}
```

### 状态管理 (Provider)
```dart
// 用户状态管理
class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadUsers() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _users = await _userService.getUsers();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> addUser(User user) async {
    try {
      final newUser = await _userService.createUser(user);
      _users.add(newUser);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  Future<void> updateUser(User user) async {
    try {
      final updatedUser = await _userService.updateUser(user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  Future<void> deleteUser(String userId) async {
    try {
      await _userService.deleteUser(userId);
      _users.removeWhere((user) => user.id == userId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
}

// 使用Provider
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Flutter Demo',
            theme: themeProvider.currentTheme,
            home: const UserListScreen(),
          );
        },
      ),
    );
  }
}

// 在Widget中使用Provider
class UserListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (userProvider.errorMessage != null) {
          return Center(
            child: Text('错误: ${userProvider.errorMessage}'),
          );
        }
        
        return ListView.builder(
          itemCount: userProvider.users.length,
          itemBuilder: (context, index) {
            final user = userProvider.users[index];
            return UserCard(user: user);
          },
        );
      },
    );
  }
}
```

### 网络请求和数据处理
```dart
// HTTP服务
class ApiService {
  static const String baseUrl = 'https://api.example.com';
  final http.Client _client = http.Client();
  
  Future<List<User>> getUsers() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<User> createUser(User user) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );
      
      if (response.statusCode == 201) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<void> deleteUser(String userId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  void dispose() {
    _client.close();
  }
}

// 本地存储
class StorageService {
  static const String _usersKey = 'users';
  
  Future<void> saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = users.map((user) => user.toJson()).toList();
    await prefs.setString(_usersKey, jsonEncode(jsonList));
  }
  
  Future<List<User>> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_usersKey);
    
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => User.fromJson(json)).toList();
    }
    
    return [];
  }
  
  Future<void> clearUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
  }
}
```

## 测试

### 单元测试
```dart
// test/user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/user.dart';

void main() {
  group('User', () {
    test('should create user with valid data', () {
      final user = User('1', '张三', 'zhangsan@example.com');
      
      expect(user.id, '1');
      expect(user.name, '张三');
      expect(user.email, 'zhangsan@example.com');
    });
    
    test('should validate email correctly', () {
      final validUser = User('1', '张三', 'zhangsan@example.com');
      final invalidUser = User('2', '李四', 'invalid-email');
      
      expect(validUser.isValidEmail(), true);
      expect(invalidUser.isValidEmail(), false);
    });
    
    test('should determine adult status correctly', () {
      final adult = User('1', '张三', 'zhangsan@example.com',
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 20)));
      final minor = User('2', '李四', 'lisi@example.com',
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 16)));
      
      expect(adult.isAdult, true);
      expect(minor.isAdult, false);
    });
    
    test('should serialize to JSON correctly', () {
      final user = User('1', '张三', 'zhangsan@example.com');
      final json = user.toJson();
      
      expect(json['id'], '1');
      expect(json['name'], '张三');
      expect(json['email'], 'zhangsan@example.com');
    });
    
    test('should deserialize from JSON correctly', () {
      final json = {
        'id': '1',
        'name': '张三',
        'email': 'zhangsan@example.com',
      };
      
      final user = User.fromJson(json);
      
      expect(user.id, '1');
      expect(user.name, '张三');
      expect(user.email, 'zhangsan@example.com');
    });
  });
}

// Widget测试
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/widgets/user_card.dart';
import 'package:myapp/models/user.dart';

void main() {
  group('UserCard', () {
    testWidgets('should display user information', (WidgetTester tester) async {
      final user = User('1', '张三', 'zhangsan@example.com');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: user),
          ),
        ),
      );
      
      expect(find.text('张三'), findsOneWidget);
      expect(find.text('zhangsan@example.com'), findsOneWidget);
    });
    
    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      final user = User('1', '张三', 'zhangsan@example.com');
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(
              user: user,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.byType(InkWell));
      
      expect(tapped, true);
    });
  });
}
```

## 性能优化

### Widget优化
```dart
// 使用const构造函数
class OptimizedWidget extends StatelessWidget {
  const OptimizedWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text('Static text'),  // const widget
        SizedBox(height: 16),  // const widget
      ],
    );
  }
}

// 使用Builder避免不必要的重建
class EfficientList extends StatelessWidget {
  final List<User> users;
  
  const EfficientList({Key? key, required this.users}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return UserCard(
          key: ValueKey(users[index].id),  // 使用key优化
          user: users[index],
        );
      },
    );
  }
}

// 使用AutomaticKeepAliveClientMixin保持状态
class KeepAliveTab extends StatefulWidget {
  @override
  _KeepAliveTabState createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);  // 必须调用
    return const Center(child: Text('Keep alive content'));
  }
}
```

## 学习建议

### 基础学习路径
1. **Dart语法基础**: 变量、函数、类、异步编程
2. **Flutter基础**: Widget、布局、导航、状态管理
3. **UI开发**: Material Design、自定义Widget
4. **数据处理**: JSON序列化、网络请求、本地存储

### 进阶学习重点
1. **状态管理**: Provider、Bloc、Riverpod
2. **架构模式**: MVVM、Clean Architecture
3. **性能优化**: Widget优化、内存管理
4. **测试**: 单元测试、Widget测试、集成测试

### 实践项目建议
1. **待办事项应用**: 学习基础UI和状态管理
2. **天气应用**: 学习网络请求和数据展示
3. **聊天应用**: 学习实时通信和复杂UI
4. **电商应用**: 学习复杂业务逻辑和支付集成
