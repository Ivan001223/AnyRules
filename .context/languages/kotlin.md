# Kotlin 语言规则文档

## 语言特性

### 核心优势
- **Java互操作性**: 100%与Java互操作，可以调用Java代码
- **空安全**: 编译时空指针检查，避免NullPointerException
- **简洁语法**: 相比Java代码量减少约40%
- **函数式编程**: 支持高阶函数、lambda表达式
- **协程支持**: 内置协程支持，简化异步编程

### Kotlin语言特性
```kotlin
// 变量声明和类型推断
val name: String = "张三"  // 不可变变量
var age = 25              // 可变变量，类型推断

// 空安全
var nullableName: String? = null
val length = nullableName?.length ?: 0  // 安全调用和Elvis操作符

// 数据类
data class User(
    val id: String,
    val name: String,
    val email: String,
    val age: Int? = null
) {
    fun isAdult(): Boolean = age?.let { it >= 18 } ?: false
}

// 扩展函数
fun String.isValidEmail(): Boolean {
    return this.contains("@") && this.contains(".")
}

// 高阶函数和Lambda
fun processUsers(users: List<User>, filter: (User) -> Boolean): List<User> {
    return users.filter(filter)
}

val adults = processUsers(users) { it.isAdult() }

// 作用域函数
val user = User("1", "张三", "zhangsan@example.com").apply {
    // 在这里可以访问user的属性和方法
    println("Created user: $name")
}

// when表达式
fun getUserType(user: User): String = when {
    user.age == null -> "Unknown"
    user.age < 18 -> "Minor"
    user.age < 65 -> "Adult"
    else -> "Senior"
}

// 密封类
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val exception: Throwable) : Result<Nothing>()
    object Loading : Result<Nothing>()
}

// 协程
suspend fun fetchUser(id: String): Result<User> {
    return try {
        val user = apiService.getUser(id)  // 挂起函数
        Result.Success(user)
    } catch (e: Exception) {
        Result.Error(e)
    }
}

// 委托属性
class UserPreferences {
    var username: String by lazy {
        // 延迟初始化
        loadUsernameFromStorage()
    }
    
    var theme: String by observable("light") { _, old, new ->
        println("Theme changed from $old to $new")
    }
}
```

## Android开发最佳实践

### MVVM架构
```kotlin
// ViewModel
class UserViewModel(
    private val userRepository: UserRepository
) : ViewModel() {
    
    private val _uiState = MutableLiveData<UiState<List<User>>>()
    val uiState: LiveData<UiState<List<User>>> = _uiState
    
    private val _users = MutableLiveData<List<User>>()
    val users: LiveData<List<User>> = _users
    
    fun loadUsers() {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            
            try {
                val userList = userRepository.getUsers()
                _users.value = userList
                _uiState.value = UiState.Success(userList)
            } catch (e: Exception) {
                _uiState.value = UiState.Error(e.message ?: "Unknown error")
            }
        }
    }
    
    fun refreshUsers() {
        viewModelScope.launch {
            try {
                val userList = userRepository.refreshUsers()
                _users.value = userList
            } catch (e: Exception) {
                // 处理错误
            }
        }
    }
}

// Repository模式
class UserRepository @Inject constructor(
    private val apiService: UserApiService,
    private val userDao: UserDao
) {
    suspend fun getUsers(): List<User> {
        return try {
            // 先从本地数据库获取
            val localUsers = userDao.getAllUsers()
            if (localUsers.isNotEmpty() && !isDataStale()) {
                localUsers
            } else {
                // 从网络获取最新数据
                val networkUsers = apiService.getUsers()
                userDao.insertUsers(networkUsers)
                networkUsers
            }
        } catch (e: Exception) {
            // 网络失败时返回本地数据
            userDao.getAllUsers()
        }
    }
    
    suspend fun refreshUsers(): List<User> {
        val networkUsers = apiService.getUsers()
        userDao.clearAndInsertUsers(networkUsers)
        return networkUsers
    }
    
    private fun isDataStale(): Boolean {
        // 检查数据是否过期的逻辑
        return false
    }
}
```

### Jetpack Compose UI
```kotlin
@Composable
fun UserListScreen(
    viewModel: UserViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.observeAsState()
    val users by viewModel.users.observeAsState(emptyList())
    
    LaunchedEffect(Unit) {
        viewModel.loadUsers()
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        when (uiState) {
            is UiState.Loading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
            
            is UiState.Error -> {
                ErrorMessage(
                    message = uiState.message,
                    onRetry = { viewModel.loadUsers() }
                )
            }
            
            is UiState.Success -> {
                LazyColumn {
                    items(users) { user ->
                        UserItem(
                            user = user,
                            onClick = { /* 处理点击 */ }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun UserItem(
    user: User,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .clickable { onClick() },
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            AsyncImage(
                model = user.avatarUrl,
                contentDescription = "User avatar",
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape),
                placeholder = painterResource(R.drawable.ic_person),
                error = painterResource(R.drawable.ic_person)
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column {
                Text(
                    text = user.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = user.email,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun ErrorMessage(
    message: String,
    onRetry: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Button(onClick = onRetry) {
            Text("重试")
        }
    }
}
```

### 网络编程
```kotlin
// Retrofit接口定义
interface UserApiService {
    @GET("users")
    suspend fun getUsers(): List<User>
    
    @GET("users/{id}")
    suspend fun getUser(@Path("id") id: String): User
    
    @POST("users")
    suspend fun createUser(@Body user: User): User
    
    @PUT("users/{id}")
    suspend fun updateUser(@Path("id") id: String, @Body user: User): User
    
    @DELETE("users/{id}")
    suspend fun deleteUser(@Path("id") id: String): Response<Unit>
}

// 网络模块配置
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = if (BuildConfig.DEBUG) {
                    HttpLoggingInterceptor.Level.BODY
                } else {
                    HttpLoggingInterceptor.Level.NONE
                }
            })
            .addInterceptor { chain ->
                val request = chain.request().newBuilder()
                    .addHeader("Authorization", "Bearer ${getAuthToken()}")
                    .build()
                chain.proceed(request)
            }
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()
    }
    
    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl("https://api.example.com/")
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }
    
    @Provides
    @Singleton
    fun provideUserApiService(retrofit: Retrofit): UserApiService {
        return retrofit.create(UserApiService::class.java)
    }
}

// 网络请求处理
class NetworkManager @Inject constructor(
    private val apiService: UserApiService
) {
    suspend fun <T> safeApiCall(
        apiCall: suspend () -> T
    ): Result<T> {
        return try {
            Result.Success(apiCall())
        } catch (e: HttpException) {
            Result.Error("HTTP ${e.code()}: ${e.message()}")
        } catch (e: IOException) {
            Result.Error("网络连接错误")
        } catch (e: Exception) {
            Result.Error("未知错误: ${e.message}")
        }
    }
}
```

### 数据库操作 (Room)
```kotlin
// Entity定义
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val name: String,
    val email: String,
    val avatarUrl: String?,
    val createdAt: Long = System.currentTimeMillis()
)

// DAO定义
@Dao
interface UserDao {
    @Query("SELECT * FROM users ORDER BY name ASC")
    suspend fun getAllUsers(): List<UserEntity>
    
    @Query("SELECT * FROM users WHERE id = :id")
    suspend fun getUserById(id: String): UserEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUsers(users: List<UserEntity>)
    
    @Update
    suspend fun updateUser(user: UserEntity)
    
    @Delete
    suspend fun deleteUser(user: UserEntity)
    
    @Query("DELETE FROM users")
    suspend fun clearAllUsers()
    
    @Transaction
    suspend fun clearAndInsertUsers(users: List<UserEntity>) {
        clearAllUsers()
        insertUsers(users)
    }
}

// Database定义
@Database(
    entities = [UserEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
}

// 数据库模块
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    
    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "app_database"
        )
        .fallbackToDestructiveMigration()
        .build()
    }
    
    @Provides
    fun provideUserDao(database: AppDatabase): UserDao {
        return database.userDao()
    }
}
```

## 协程和异步编程

### 协程基础
```kotlin
// 协程作用域
class UserService {
    private val serviceScope = CoroutineScope(
        SupervisorJob() + Dispatchers.IO
    )
    
    fun loadUserData() {
        serviceScope.launch {
            try {
                val user = fetchUserFromNetwork()
                val profile = fetchUserProfile(user.id)
                
                withContext(Dispatchers.Main) {
                    updateUI(user, profile)
                }
            } catch (e: Exception) {
                handleError(e)
            }
        }
    }
    
    suspend fun fetchUserFromNetwork(): User {
        return withContext(Dispatchers.IO) {
            // 网络请求
            apiService.getUser()
        }
    }
    
    fun cleanup() {
        serviceScope.cancel()
    }
}

// 并发执行
suspend fun loadUserData(userId: String): UserData {
    return coroutineScope {
        val userDeferred = async { userRepository.getUser(userId) }
        val postsDeferred = async { postRepository.getUserPosts(userId) }
        val friendsDeferred = async { friendRepository.getUserFriends(userId) }
        
        UserData(
            user = userDeferred.await(),
            posts = postsDeferred.await(),
            friends = friendsDeferred.await()
        )
    }
}

// Flow使用
class UserRepository {
    fun observeUsers(): Flow<List<User>> = flow {
        while (true) {
            val users = apiService.getUsers()
            emit(users)
            delay(30_000) // 30秒刷新一次
        }
    }.flowOn(Dispatchers.IO)
    
    fun searchUsers(query: String): Flow<List<User>> {
        return flow {
            emit(emptyList()) // 初始状态
            delay(300) // 防抖
            val results = apiService.searchUsers(query)
            emit(results)
        }
    }
}
```

## 测试

### 单元测试
```kotlin
@RunWith(MockitoJUnitRunner::class)
class UserRepositoryTest {
    
    @Mock
    private lateinit var apiService: UserApiService
    
    @Mock
    private lateinit var userDao: UserDao
    
    private lateinit var repository: UserRepository
    
    @Before
    fun setup() {
        repository = UserRepository(apiService, userDao)
    }
    
    @Test
    fun `getUsers should return local data when network fails`() = runTest {
        // Given
        val localUsers = listOf(
            User("1", "张三", "zhangsan@example.com")
        )
        `when`(userDao.getAllUsers()).thenReturn(localUsers)
        `when`(apiService.getUsers()).thenThrow(IOException())
        
        // When
        val result = repository.getUsers()
        
        // Then
        assertEquals(localUsers, result)
        verify(userDao).getAllUsers()
        verify(apiService).getUsers()
    }
    
    @Test
    fun `getUsers should fetch from network when local data is stale`() = runTest {
        // Given
        val networkUsers = listOf(
            User("1", "李四", "lisi@example.com")
        )
        `when`(userDao.getAllUsers()).thenReturn(emptyList())
        `when`(apiService.getUsers()).thenReturn(networkUsers)
        
        // When
        val result = repository.getUsers()
        
        // Then
        assertEquals(networkUsers, result)
        verify(apiService).getUsers()
        verify(userDao).insertUsers(networkUsers)
    }
}
```

### UI测试
```kotlin
@RunWith(AndroidJUnit4::class)
class UserListScreenTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun userListScreen_displaysUsers() {
        // Given
        val users = listOf(
            User("1", "张三", "zhangsan@example.com"),
            User("2", "李四", "lisi@example.com")
        )
        
        // When
        composeTestRule.setContent {
            UserListScreen(users = users)
        }
        
        // Then
        composeTestRule.onNodeWithText("张三").assertIsDisplayed()
        composeTestRule.onNodeWithText("李四").assertIsDisplayed()
        composeTestRule.onNodeWithText("zhangsan@example.com").assertIsDisplayed()
    }
    
    @Test
    fun userListScreen_showsLoadingState() {
        // When
        composeTestRule.setContent {
            UserListScreen(isLoading = true)
        }
        
        // Then
        composeTestRule.onNode(hasProgressBarRangeInfo(ProgressBarRangeInfo.Indeterminate))
            .assertIsDisplayed()
    }
}
```

## 性能优化

### 内存优化
```kotlin
// 使用lazy延迟初始化
class ExpensiveResource {
    private val heavyObject by lazy {
        createHeavyObject()
    }
    
    private fun createHeavyObject(): HeavyObject {
        // 创建重量级对象
        return HeavyObject()
    }
}

// 使用对象池
class ObjectPool<T>(
    private val factory: () -> T,
    private val reset: (T) -> Unit
) {
    private val pool = mutableListOf<T>()
    
    fun acquire(): T {
        return if (pool.isNotEmpty()) {
            pool.removeAt(pool.size - 1)
        } else {
            factory()
        }
    }
    
    fun release(obj: T) {
        reset(obj)
        pool.add(obj)
    }
}
```

### 编译优化
```kotlin
// 使用inline函数减少函数调用开销
inline fun <T> measureTime(block: () -> T): Pair<T, Long> {
    val start = System.currentTimeMillis()
    val result = block()
    val time = System.currentTimeMillis() - start
    return result to time
}

// 使用@JvmStatic减少静态方法调用开销
class Utils {
    companion object {
        @JvmStatic
        fun formatDate(date: Date): String {
            return SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(date)
        }
    }
}
```

## 学习建议

### 基础学习路径
1. **Kotlin语法**: 变量、函数、类、继承、接口
2. **Android基础**: Activity、Fragment、Intent、布局
3. **现代Android开发**: Jetpack组件、MVVM架构
4. **异步编程**: 协程、Flow、异步操作

### 进阶学习重点
1. **Jetpack Compose**: 现代声明式UI开发
2. **架构组件**: ViewModel、LiveData、Room、Navigation
3. **依赖注入**: Hilt/Dagger使用
4. **测试**: 单元测试、UI测试、集成测试

### 实践项目建议
1. **笔记应用**: 学习Room数据库和CRUD操作
2. **新闻应用**: 学习网络请求和列表展示
3. **聊天应用**: 学习实时通信和复杂UI
4. **工具应用**: 学习系统API和高级功能
