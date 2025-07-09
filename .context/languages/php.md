# PHP 语言规则文档

## 语言特性

### 核心优势
- **Web开发专长**: 专为Web开发设计，简单易学
- **动态类型**: 灵活的类型系统，快速开发
- **丰富生态**: 庞大的开源生态和框架支持
- **跨平台**: 支持多种操作系统和Web服务器
- **现代特性**: PHP 8+引入了许多现代语言特性

### PHP现代特性
```php
<?php
// 类型声明和返回类型
function calculateTotal(float $price, int $quantity): float 
{
    return $price * $quantity;
}

// 类和属性
class User 
{
    public function __construct(
        public readonly string $id,
        public string $name,
        public string $email,
        private ?DateTime $createdAt = null
    ) {
        $this->createdAt ??= new DateTime();
    }
    
    public function isValidEmail(): bool 
    {
        return filter_var($this->email, FILTER_VALIDATE_EMAIL) !== false;
    }
    
    public function getAge(): ?int 
    {
        return $this->birthDate?->diff(new DateTime())->y;
    }
}

// 枚举 (PHP 8.1+)
enum UserStatus: string 
{
    case ACTIVE = 'active';
    case INACTIVE = 'inactive';
    case SUSPENDED = 'suspended';
    
    public function getLabel(): string 
    {
        return match($this) {
            self::ACTIVE => '活跃',
            self::INACTIVE => '非活跃',
            self::SUSPENDED => '已暂停',
        };
    }
}

// 匹配表达式 (PHP 8+)
function getUserTypeMessage(User $user): string 
{
    return match($user->getAge()) {
        null => '年龄未知',
        0...17 => '未成年人',
        18...64 => '成年人',
        default => '老年人',
    };
}

// 命名参数
$user = new User(
    id: '123',
    name: '张三',
    email: 'zhangsan@example.com'
);

// 数组和集合操作
$users = [
    new User('1', '张三', 'zhang@example.com'),
    new User('2', '李四', 'li@example.com'),
];

$activeUsers = array_filter($users, fn($user) => $user->status === UserStatus::ACTIVE);
$userNames = array_map(fn($user) => $user->name, $users);

// 空值合并和空值合并赋值
$username = $_GET['username'] ?? 'guest';
$config['timeout'] ??= 30;

// 属性和反射
#[Route('/api/users', methods: ['GET', 'POST'])]
class UserController 
{
    #[Inject]
    private UserService $userService;
    
    #[Cache(ttl: 300)]
    public function getUsers(): array 
    {
        return $this->userService->getAllUsers();
    }
}
```

## Web开发最佳实践

### Laravel框架
```php
<?php
// 模型定义
class User extends Model 
{
    protected $fillable = ['name', 'email', 'password'];
    protected $hidden = ['password', 'remember_token'];
    protected $casts = [
        'email_verified_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
    
    // 关联关系
    public function posts(): HasMany 
    {
        return $this->hasMany(Post::class);
    }
    
    public function profile(): HasOne 
    {
        return $this->hasOne(UserProfile::class);
    }
    
    // 访问器
    public function getFullNameAttribute(): string 
    {
        return "{$this->first_name} {$this->last_name}";
    }
    
    // 修改器
    public function setPasswordAttribute(string $value): void 
    {
        $this->attributes['password'] = Hash::make($value);
    }
    
    // 作用域
    public function scopeActive(Builder $query): Builder 
    {
        return $query->where('status', 'active');
    }
}

// 控制器
class UserController extends Controller 
{
    public function __construct(
        private UserService $userService
    ) {}
    
    public function index(Request $request): JsonResponse 
    {
        $users = $this->userService->getPaginatedUsers(
            page: $request->get('page', 1),
            perPage: $request->get('per_page', 15)
        );
        
        return response()->json([
            'data' => UserResource::collection($users->items()),
            'meta' => [
                'current_page' => $users->currentPage(),
                'total' => $users->total(),
                'per_page' => $users->perPage(),
            ]
        ]);
    }
    
    public function store(CreateUserRequest $request): JsonResponse 
    {
        $user = $this->userService->createUser($request->validated());
        
        return response()->json([
            'data' => new UserResource($user),
            'message' => '用户创建成功'
        ], 201);
    }
    
    public function show(User $user): JsonResponse 
    {
        return response()->json([
            'data' => new UserResource($user->load('profile', 'posts'))
        ]);
    }
    
    public function update(UpdateUserRequest $request, User $user): JsonResponse 
    {
        $user = $this->userService->updateUser($user, $request->validated());
        
        return response()->json([
            'data' => new UserResource($user),
            'message' => '用户更新成功'
        ]);
    }
    
    public function destroy(User $user): JsonResponse 
    {
        $this->userService->deleteUser($user);
        
        return response()->json([
            'message' => '用户删除成功'
        ]);
    }
}

// 服务层
class UserService 
{
    public function __construct(
        private UserRepository $userRepository,
        private EventDispatcher $eventDispatcher
    ) {}
    
    public function createUser(array $data): User 
    {
        DB::beginTransaction();
        
        try {
            $user = $this->userRepository->create($data);
            
            // 创建用户配置文件
            $user->profile()->create([
                'display_name' => $data['name'],
                'bio' => '',
            ]);
            
            // 发送欢迎邮件
            Mail::to($user)->queue(new WelcomeEmail($user));
            
            // 触发事件
            $this->eventDispatcher->dispatch(new UserCreated($user));
            
            DB::commit();
            
            return $user;
        } catch (Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }
    
    public function getPaginatedUsers(int $page = 1, int $perPage = 15): LengthAwarePaginator 
    {
        return $this->userRepository
            ->with(['profile'])
            ->active()
            ->orderBy('created_at', 'desc')
            ->paginate($perPage, ['*'], 'page', $page);
    }
}

// 资源转换
class UserResource extends JsonResource 
{
    public function toArray($request): array 
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'full_name' => $this->full_name,
            'status' => $this->status,
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString(),
            
            // 条件包含
            'profile' => $this->whenLoaded('profile', function () {
                return new UserProfileResource($this->profile);
            }),
            
            'posts_count' => $this->whenCounted('posts'),
            
            // 权限相关
            'can_edit' => $this->when(
                $request->user()?->can('update', $this->resource),
                true
            ),
        ];
    }
}

// 表单请求验证
class CreateUserRequest extends FormRequest 
{
    public function authorize(): bool 
    {
        return $this->user()->can('create', User::class);
    }
    
    public function rules(): array 
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'birth_date' => ['nullable', 'date', 'before:today'],
        ];
    }
    
    public function messages(): array 
    {
        return [
            'email.unique' => '该邮箱地址已被使用',
            'password.min' => '密码至少需要8个字符',
            'password.confirmed' => '密码确认不匹配',
        ];
    }
}
```

### 数据库操作
```php
<?php
// 查询构建器
$users = DB::table('users')
    ->select('id', 'name', 'email')
    ->where('status', 'active')
    ->where('created_at', '>=', now()->subDays(30))
    ->orderBy('name')
    ->get();

// Eloquent ORM
$users = User::with(['profile', 'posts' => function ($query) {
        $query->published()->latest();
    }])
    ->whereHas('posts', function ($query) {
        $query->where('published_at', '>=', now()->subMonth());
    })
    ->active()
    ->paginate(15);

// 原生SQL查询
$users = DB::select('
    SELECT u.*, p.display_name 
    FROM users u 
    LEFT JOIN user_profiles p ON u.id = p.user_id 
    WHERE u.status = ? AND u.created_at >= ?
', ['active', now()->subDays(30)]);

// 事务处理
DB::transaction(function () use ($userData, $profileData) {
    $user = User::create($userData);
    $user->profile()->create($profileData);
    
    // 如果这里抛出异常，整个事务会回滚
    $this->sendWelcomeEmail($user);
});

// 迁移文件
class CreateUsersTable extends Migration 
{
    public function up(): void 
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->enum('status', ['active', 'inactive', 'suspended'])->default('active');
            $table->date('birth_date')->nullable();
            $table->rememberToken();
            $table->timestamps();
            
            $table->index(['status', 'created_at']);
        });
    }
    
    public function down(): void 
    {
        Schema::dropIfExists('users');
    }
}
```

### 缓存和性能优化
```php
<?php
// Redis缓存
class UserService 
{
    private const CACHE_TTL = 3600; // 1小时
    
    public function getUser(string $id): ?User 
    {
        $cacheKey = "user:{$id}";
        
        return Cache::remember($cacheKey, self::CACHE_TTL, function () use ($id) {
            return User::with('profile')->find($id);
        });
    }
    
    public function updateUser(User $user, array $data): User 
    {
        $user->update($data);
        
        // 清除缓存
        Cache::forget("user:{$user->id}");
        Cache::tags(['users'])->flush();
        
        return $user;
    }
    
    public function getUserStats(): array 
    {
        return Cache::tags(['users', 'stats'])->remember('user_stats', 1800, function () {
            return [
                'total' => User::count(),
                'active' => User::active()->count(),
                'new_today' => User::whereDate('created_at', today())->count(),
            ];
        });
    }
}

// 队列任务
class SendWelcomeEmail implements ShouldQueue 
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
    
    public function __construct(
        private User $user
    ) {}
    
    public function handle(): void 
    {
        Mail::to($this->user)->send(new WelcomeEmail($this->user));
    }
    
    public function failed(Throwable $exception): void 
    {
        Log::error('Failed to send welcome email', [
            'user_id' => $this->user->id,
            'error' => $exception->getMessage(),
        ]);
    }
}

// 事件监听器
class UserEventSubscriber 
{
    public function handleUserCreated(UserCreated $event): void 
    {
        // 发送欢迎邮件
        SendWelcomeEmail::dispatch($event->user);
        
        // 创建默认设置
        $event->user->settings()->create([
            'theme' => 'light',
            'language' => 'zh-CN',
            'notifications' => true,
        ]);
    }
    
    public function handleUserUpdated(UserUpdated $event): void 
    {
        // 清除相关缓存
        Cache::tags(['users'])->flush();
    }
    
    public function subscribe(Dispatcher $events): void 
    {
        $events->listen(UserCreated::class, [self::class, 'handleUserCreated']);
        $events->listen(UserUpdated::class, [self::class, 'handleUserUpdated']);
    }
}
```

## 测试

### PHPUnit测试
```php
<?php
class UserServiceTest extends TestCase 
{
    use RefreshDatabase;
    
    private UserService $userService;
    
    protected function setUp(): void 
    {
        parent::setUp();
        $this->userService = app(UserService::class);
    }
    
    public function test_can_create_user(): void 
    {
        $userData = [
            'name' => '张三',
            'email' => 'zhangsan@example.com',
            'password' => 'password123',
        ];
        
        $user = $this->userService->createUser($userData);
        
        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals('张三', $user->name);
        $this->assertEquals('zhangsan@example.com', $user->email);
        $this->assertDatabaseHas('users', [
            'name' => '张三',
            'email' => 'zhangsan@example.com',
        ]);
    }
    
    public function test_cannot_create_user_with_duplicate_email(): void 
    {
        User::factory()->create(['email' => 'test@example.com']);
        
        $this->expectException(ValidationException::class);
        
        $this->userService->createUser([
            'name' => '李四',
            'email' => 'test@example.com',
            'password' => 'password123',
        ]);
    }
    
    public function test_can_get_paginated_users(): void 
    {
        User::factory()->count(25)->create();
        
        $result = $this->userService->getPaginatedUsers(page: 1, perPage: 10);
        
        $this->assertCount(10, $result->items());
        $this->assertEquals(25, $result->total());
        $this->assertEquals(1, $result->currentPage());
    }
}

// 功能测试
class UserControllerTest extends TestCase 
{
    use RefreshDatabase;
    
    public function test_can_get_users_list(): void 
    {
        $user = User::factory()->create();
        User::factory()->count(5)->create();
        
        $response = $this->actingAs($user)
            ->getJson('/api/users');
        
        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'name', 'email', 'created_at']
                ],
                'meta' => ['current_page', 'total', 'per_page']
            ]);
    }
    
    public function test_can_create_user(): void 
    {
        $admin = User::factory()->admin()->create();
        
        $userData = [
            'name' => '新用户',
            'email' => 'newuser@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];
        
        $response = $this->actingAs($admin)
            ->postJson('/api/users', $userData);
        
        $response->assertCreated()
            ->assertJsonFragment([
                'name' => '新用户',
                'email' => 'newuser@example.com',
            ]);
    }
}
```

## 安全最佳实践

### 输入验证和过滤
```php
<?php
// 输入验证
class SecurityHelper 
{
    public static function sanitizeInput(string $input): string 
    {
        return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
    }
    
    public static function validateEmail(string $email): bool 
    {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
    
    public static function validateUrl(string $url): bool 
    {
        return filter_var($url, FILTER_VALIDATE_URL) !== false;
    }
    
    public static function generateSecureToken(int $length = 32): string 
    {
        return bin2hex(random_bytes($length));
    }
}

// CSRF保护
class ApiController extends Controller 
{
    public function __construct() 
    {
        $this->middleware('auth:sanctum');
        $this->middleware('throttle:60,1'); // 限流
    }
}

// SQL注入防护
class UserRepository 
{
    public function findByEmail(string $email): ?User 
    {
        // 使用参数绑定防止SQL注入
        return User::where('email', $email)->first();
    }
    
    public function searchUsers(string $query): Collection 
    {
        // 使用查询构建器的安全方法
        return User::where('name', 'LIKE', '%' . $query . '%')
            ->orWhere('email', 'LIKE', '%' . $query . '%')
            ->get();
    }
}
```

## 学习建议

### 基础学习路径
1. **PHP语法基础**: 变量、数组、函数、面向对象
2. **Web开发基础**: HTTP协议、表单处理、会话管理
3. **数据库操作**: MySQL、PDO、查询优化
4. **框架学习**: Laravel或Symfony框架

### 进阶学习重点
1. **现代PHP**: PHP 8+新特性、类型系统
2. **架构模式**: MVC、Repository、Service层
3. **API开发**: RESTful API、GraphQL
4. **性能优化**: 缓存、队列、数据库优化

### 实践项目建议
1. **博客系统**: 学习CRUD操作和用户认证
2. **电商平台**: 学习复杂业务逻辑和支付集成
3. **API服务**: 学习RESTful API设计和开发
4. **内容管理系统**: 学习权限管理和文件处理
