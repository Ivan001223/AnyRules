# C# 语言规则文档

## 语言特性

### 核心优势
- **强类型系统**: 编译时类型检查，减少运行时错误
- **内存管理**: 自动垃圾回收，简化内存管理
- **跨平台**: .NET Core/.NET 5+支持跨平台开发
- **丰富生态**: 庞大的.NET生态系统和NuGet包管理
- **现代语法**: 持续演进的现代语言特性

### C#语言特性
```csharp
// 变量声明和类型推断
string name = "张三";
var age = 25;  // 类型推断
int? nullableAge = null;  // 可空类型

// 字符串插值
string message = $"Hello, {name}! You are {age} years old.";

// 模式匹配
string GetUserType(User user) => user switch
{
    { Age: < 18 } => "Minor",
    { Age: >= 18 and < 65 } => "Adult",
    { Age: >= 65 } => "Senior",
    _ => "Unknown"
};

// 记录类型 (C# 9+)
public record User(string Id, string Name, string Email)
{
    public bool IsValidEmail => Email.Contains("@");
}

// 属性和自动属性
public class UserProfile
{
    public string Name { get; set; }
    public int Age { get; private set; }
    
    // 计算属性
    public bool IsAdult => Age >= 18;
    
    // 属性初始化器
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
}

// LINQ查询
var adults = users
    .Where(u => u.Age >= 18)
    .OrderBy(u => u.Name)
    .Select(u => new { u.Name, u.Email })
    .ToList();

// 异步编程
public async Task<User> GetUserAsync(string id)
{
    using var httpClient = new HttpClient();
    var response = await httpClient.GetAsync($"https://api.example.com/users/{id}");
    var json = await response.Content.ReadAsStringAsync();
    return JsonSerializer.Deserialize<User>(json);
}

// 扩展方法
public static class StringExtensions
{
    public static bool IsValidEmail(this string email)
    {
        return email.Contains("@") && email.Contains(".");
    }
}

// 泛型
public class Repository<T> where T : class
{
    private readonly List<T> _items = new();
    
    public void Add(T item) => _items.Add(item);
    public IEnumerable<T> GetAll() => _items.AsReadOnly();
    public T? Find(Func<T, bool> predicate) => _items.FirstOrDefault(predicate);
}

// 委托和事件
public class UserService
{
    public event Action<User>? UserCreated;
    
    public void CreateUser(User user)
    {
        // 创建用户逻辑
        UserCreated?.Invoke(user);
    }
}
```

## .NET开发最佳实践

### ASP.NET Core Web API
```csharp
// 控制器
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ILogger<UsersController> _logger;
    
    public UsersController(IUserService userService, ILogger<UsersController> logger)
    {
        _userService = userService;
        _logger = logger;
    }
    
    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserDto>>> GetUsers()
    {
        try
        {
            var users = await _userService.GetAllUsersAsync();
            return Ok(users);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving users");
            return StatusCode(500, "Internal server error");
        }
    }
    
    [HttpGet("{id}")]
    public async Task<ActionResult<UserDto>> GetUser(string id)
    {
        var user = await _userService.GetUserByIdAsync(id);
        if (user == null)
        {
            return NotFound();
        }
        return Ok(user);
    }
    
    [HttpPost]
    public async Task<ActionResult<UserDto>> CreateUser(CreateUserRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }
        
        var user = await _userService.CreateUserAsync(request);
        return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
    }
}

// 服务层
public interface IUserService
{
    Task<IEnumerable<UserDto>> GetAllUsersAsync();
    Task<UserDto?> GetUserByIdAsync(string id);
    Task<UserDto> CreateUserAsync(CreateUserRequest request);
}

public class UserService : IUserService
{
    private readonly IUserRepository _repository;
    private readonly IMapper _mapper;
    
    public UserService(IUserRepository repository, IMapper mapper)
    {
        _repository = repository;
        _mapper = mapper;
    }
    
    public async Task<IEnumerable<UserDto>> GetAllUsersAsync()
    {
        var users = await _repository.GetAllAsync();
        return _mapper.Map<IEnumerable<UserDto>>(users);
    }
    
    public async Task<UserDto?> GetUserByIdAsync(string id)
    {
        var user = await _repository.GetByIdAsync(id);
        return user != null ? _mapper.Map<UserDto>(user) : null;
    }
    
    public async Task<UserDto> CreateUserAsync(CreateUserRequest request)
    {
        var user = _mapper.Map<User>(request);
        user.Id = Guid.NewGuid().ToString();
        user.CreatedAt = DateTime.UtcNow;
        
        await _repository.AddAsync(user);
        return _mapper.Map<UserDto>(user);
    }
}
```

### Entity Framework Core
```csharp
// 实体模型
public class User
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    // 导航属性
    public ICollection<Post> Posts { get; set; } = new List<Post>();
}

public class Post
{
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    
    // 导航属性
    public User User { get; set; } = null!;
}

// DbContext
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }
    
    public DbSet<User> Users { get; set; }
    public DbSet<Post> Posts { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // 用户配置
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Email).IsRequired().HasMaxLength(255);
            entity.HasIndex(e => e.Email).IsUnique();
        });
        
        // 文章配置
        modelBuilder.Entity<Post>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Content).IsRequired();
            
            // 外键关系
            entity.HasOne(e => e.User)
                  .WithMany(e => e.Posts)
                  .HasForeignKey(e => e.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });
    }
}

// Repository模式
public interface IUserRepository
{
    Task<IEnumerable<User>> GetAllAsync();
    Task<User?> GetByIdAsync(string id);
    Task<User> AddAsync(User user);
    Task UpdateAsync(User user);
    Task DeleteAsync(string id);
}

public class UserRepository : IUserRepository
{
    private readonly ApplicationDbContext _context;
    
    public UserRepository(ApplicationDbContext context)
    {
        _context = context;
    }
    
    public async Task<IEnumerable<User>> GetAllAsync()
    {
        return await _context.Users
            .Include(u => u.Posts)
            .ToListAsync();
    }
    
    public async Task<User?> GetByIdAsync(string id)
    {
        return await _context.Users
            .Include(u => u.Posts)
            .FirstOrDefaultAsync(u => u.Id == id);
    }
    
    public async Task<User> AddAsync(User user)
    {
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        return user;
    }
    
    public async Task UpdateAsync(User user)
    {
        user.UpdatedAt = DateTime.UtcNow;
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
    }
    
    public async Task DeleteAsync(string id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user != null)
        {
            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
        }
    }
}
```

### 依赖注入配置
```csharp
// Program.cs (.NET 6+)
var builder = WebApplication.CreateBuilder(args);

// 添加服务
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 数据库配置
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// 依赖注入
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUserService, UserService>();

// AutoMapper配置
builder.Services.AddAutoMapper(typeof(Program));

// 日志配置
builder.Services.AddLogging(logging =>
{
    logging.AddConsole();
    logging.AddDebug();
});

var app = builder.Build();

// 配置HTTP请求管道
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

## 异步编程

### Task和async/await
```csharp
// 异步方法
public async Task<List<User>> ProcessUsersAsync(List<string> userIds)
{
    var tasks = userIds.Select(async id =>
    {
        var user = await GetUserAsync(id);
        await ProcessUserDataAsync(user);
        return user;
    });
    
    var users = await Task.WhenAll(tasks);
    return users.ToList();
}

// 并发控制
public async Task<List<User>> ProcessUsersConcurrentlyAsync(List<string> userIds)
{
    using var semaphore = new SemaphoreSlim(5); // 最多5个并发
    var tasks = userIds.Select(async id =>
    {
        await semaphore.WaitAsync();
        try
        {
            return await GetUserAsync(id);
        }
        finally
        {
            semaphore.Release();
        }
    });
    
    var users = await Task.WhenAll(tasks);
    return users.ToList();
}

// 取消令牌
public async Task<User> GetUserWithTimeoutAsync(string id, CancellationToken cancellationToken = default)
{
    using var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
    using var combinedCts = CancellationTokenSource.CreateLinkedTokenSource(
        cancellationToken, timeoutCts.Token);
    
    try
    {
        return await GetUserAsync(id, combinedCts.Token);
    }
    catch (OperationCanceledException) when (timeoutCts.Token.IsCancellationRequested)
    {
        throw new TimeoutException("Request timed out");
    }
}
```

## 测试

### 单元测试
```csharp
[TestClass]
public class UserServiceTests
{
    private Mock<IUserRepository> _mockRepository;
    private Mock<IMapper> _mockMapper;
    private UserService _userService;
    
    [TestInitialize]
    public void Setup()
    {
        _mockRepository = new Mock<IUserRepository>();
        _mockMapper = new Mock<IMapper>();
        _userService = new UserService(_mockRepository.Object, _mockMapper.Object);
    }
    
    [TestMethod]
    public async Task GetUserByIdAsync_ExistingUser_ReturnsUserDto()
    {
        // Arrange
        var userId = "123";
        var user = new User { Id = userId, Name = "张三", Email = "zhangsan@example.com" };
        var userDto = new UserDto { Id = userId, Name = "张三", Email = "zhangsan@example.com" };
        
        _mockRepository.Setup(r => r.GetByIdAsync(userId))
                      .ReturnsAsync(user);
        _mockMapper.Setup(m => m.Map<UserDto>(user))
                   .Returns(userDto);
        
        // Act
        var result = await _userService.GetUserByIdAsync(userId);
        
        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(userId, result.Id);
        Assert.AreEqual("张三", result.Name);
        
        _mockRepository.Verify(r => r.GetByIdAsync(userId), Times.Once);
        _mockMapper.Verify(m => m.Map<UserDto>(user), Times.Once);
    }
    
    [TestMethod]
    public async Task GetUserByIdAsync_NonExistingUser_ReturnsNull()
    {
        // Arrange
        var userId = "999";
        _mockRepository.Setup(r => r.GetByIdAsync(userId))
                      .ReturnsAsync((User?)null);
        
        // Act
        var result = await _userService.GetUserByIdAsync(userId);
        
        // Assert
        Assert.IsNull(result);
    }
}

// 集成测试
[TestClass]
public class UsersControllerIntegrationTests
{
    private WebApplicationFactory<Program> _factory;
    private HttpClient _client;
    
    [TestInitialize]
    public void Setup()
    {
        _factory = new WebApplicationFactory<Program>();
        _client = _factory.CreateClient();
    }
    
    [TestMethod]
    public async Task GetUsers_ReturnsSuccessStatusCode()
    {
        // Act
        var response = await _client.GetAsync("/api/users");
        
        // Assert
        response.EnsureSuccessStatusCode();
        
        var content = await response.Content.ReadAsStringAsync();
        var users = JsonSerializer.Deserialize<List<UserDto>>(content);
        
        Assert.IsNotNull(users);
    }
    
    [TestCleanup]
    public void Cleanup()
    {
        _client?.Dispose();
        _factory?.Dispose();
    }
}
```

## 性能优化

### 内存优化
```csharp
// 使用Span<T>和Memory<T>
public void ProcessData(ReadOnlySpan<byte> data)
{
    // 避免内存分配的高性能处理
    for (int i = 0; i < data.Length; i++)
    {
        // 处理数据
    }
}

// 对象池
public class ObjectPool<T> where T : class, new()
{
    private readonly ConcurrentQueue<T> _objects = new();
    private readonly Func<T> _objectGenerator;
    
    public ObjectPool(Func<T> objectGenerator = null)
    {
        _objectGenerator = objectGenerator ?? (() => new T());
    }
    
    public T Get()
    {
        return _objects.TryDequeue(out T item) ? item : _objectGenerator();
    }
    
    public void Return(T item)
    {
        _objects.Enqueue(item);
    }
}

// 字符串构建优化
public string BuildLargeString(IEnumerable<string> parts)
{
    var sb = new StringBuilder();
    foreach (var part in parts)
    {
        sb.Append(part);
    }
    return sb.ToString();
}
```

### 缓存策略
```csharp
// 内存缓存
public class CachedUserService : IUserService
{
    private readonly IUserService _userService;
    private readonly IMemoryCache _cache;
    private readonly TimeSpan _cacheExpiry = TimeSpan.FromMinutes(10);
    
    public CachedUserService(IUserService userService, IMemoryCache cache)
    {
        _userService = userService;
        _cache = cache;
    }
    
    public async Task<UserDto?> GetUserByIdAsync(string id)
    {
        var cacheKey = $"user_{id}";
        
        if (_cache.TryGetValue(cacheKey, out UserDto cachedUser))
        {
            return cachedUser;
        }
        
        var user = await _userService.GetUserByIdAsync(id);
        if (user != null)
        {
            _cache.Set(cacheKey, user, _cacheExpiry);
        }
        
        return user;
    }
}
```

## 学习建议

### 基础学习路径
1. **C#语法基础**: 变量、类型、控制流、面向对象
2. **.NET基础**: 命名空间、程序集、垃圾回收
3. **异步编程**: Task、async/await、并发控制
4. **LINQ**: 查询语法、方法语法、延迟执行

### 进阶学习重点
1. **ASP.NET Core**: Web API、MVC、中间件
2. **Entity Framework**: ORM、数据库操作、迁移
3. **依赖注入**: IoC容器、生命周期管理
4. **测试**: 单元测试、集成测试、模拟对象

### 实践项目建议
1. **Web API项目**: 学习RESTful API开发
2. **MVC Web应用**: 学习Web开发和前后端交互
3. **控制台应用**: 学习基础语法和算法
4. **桌面应用**: 学习WPF或WinUI开发
