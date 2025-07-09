# Vue.js 工具规则文档

## 工具概述
Vue.js是一个渐进式JavaScript框架，用于构建用户界面和单页应用程序。

### 适用场景
- 单页应用程序(SPA)开发
- 渐进式Web应用(PWA)
- 组件化UI开发
- 中小型到大型前端项目
- 移动端混合应用开发

### 核心特性
- **响应式数据绑定**: 自动追踪依赖和更新视图
- **组件化架构**: 可复用的组件系统
- **虚拟DOM**: 高效的DOM更新机制
- **指令系统**: 声明式的模板语法
- **生态丰富**: Vue Router、Vuex/Pinia、Vue CLI等

## 最佳实践

### Vue 3 Composition API
```vue
<template>
  <div class="user-profile">
    <div class="user-info">
      <img :src="user.avatar" :alt="user.name" class="avatar" />
      <h2>{{ user.name }}</h2>
      <p>{{ user.email }}</p>
    </div>
    
    <div class="user-stats">
      <div class="stat-item">
        <span class="label">文章数</span>
        <span class="value">{{ userStats.posts }}</span>
      </div>
      <div class="stat-item">
        <span class="label">关注者</span>
        <span class="value">{{ userStats.followers }}</span>
      </div>
    </div>
    
    <div class="actions">
      <button 
        @click="followUser" 
        :disabled="isLoading"
        :class="{ 'following': isFollowing }"
      >
        {{ isFollowing ? '已关注' : '关注' }}
      </button>
      <button @click="sendMessage">发消息</button>
    </div>
    
    <!-- 用户文章列表 -->
    <div class="posts-section">
      <h3>最新文章</h3>
      <div v-if="postsLoading" class="loading">加载中...</div>
      <div v-else-if="posts.length === 0" class="empty">暂无文章</div>
      <div v-else class="posts-list">
        <article 
          v-for="post in posts" 
          :key="post.id"
          class="post-item"
          @click="viewPost(post.id)"
        >
          <h4>{{ post.title }}</h4>
          <p>{{ post.excerpt }}</p>
          <div class="post-meta">
            <span>{{ formatDate(post.createdAt) }}</span>
            <span>{{ post.readCount }} 阅读</span>
          </div>
        </article>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useNotification } from '@/composables/useNotification'
import { formatDate } from '@/utils/date'
import type { User, Post, UserStats } from '@/types'

// Props定义
interface Props {
  userId: string
}

const props = defineProps<Props>()

// Emits定义
interface Emits {
  (e: 'follow', userId: string): void
  (e: 'message', userId: string): void
}

const emit = defineEmits<Emits>()

// 组合式函数
const router = useRouter()
const userStore = useUserStore()
const { showSuccess, showError } = useNotification()

// 响应式数据
const user = ref<User | null>(null)
const userStats = reactive<UserStats>({
  posts: 0,
  followers: 0,
  following: 0
})
const posts = ref<Post[]>([])
const isLoading = ref(false)
const postsLoading = ref(false)
const isFollowing = ref(false)

// 计算属性
const canFollow = computed(() => {
  return user.value && user.value.id !== userStore.currentUser?.id
})

// 方法
const loadUserData = async () => {
  try {
    isLoading.value = true
    
    // 并行加载用户信息和统计数据
    const [userData, statsData, followStatus] = await Promise.all([
      userStore.fetchUser(props.userId),
      userStore.fetchUserStats(props.userId),
      userStore.checkFollowStatus(props.userId)
    ])
    
    user.value = userData
    Object.assign(userStats, statsData)
    isFollowing.value = followStatus
  } catch (error) {
    showError('加载用户信息失败')
    console.error('Failed to load user data:', error)
  } finally {
    isLoading.value = false
  }
}

const loadUserPosts = async () => {
  try {
    postsLoading.value = true
    posts.value = await userStore.fetchUserPosts(props.userId, { limit: 10 })
  } catch (error) {
    showError('加载文章列表失败')
    console.error('Failed to load posts:', error)
  } finally {
    postsLoading.value = false
  }
}

const followUser = async () => {
  if (!canFollow.value || isLoading.value) return
  
  try {
    isLoading.value = true
    
    if (isFollowing.value) {
      await userStore.unfollowUser(props.userId)
      userStats.followers--
      isFollowing.value = false
      showSuccess('已取消关注')
    } else {
      await userStore.followUser(props.userId)
      userStats.followers++
      isFollowing.value = true
      showSuccess('关注成功')
    }
    
    emit('follow', props.userId)
  } catch (error) {
    showError('操作失败，请重试')
    console.error('Follow operation failed:', error)
  } finally {
    isLoading.value = false
  }
}

const sendMessage = () => {
  emit('message', props.userId)
  router.push(`/messages/new?to=${props.userId}`)
}

const viewPost = (postId: string) => {
  router.push(`/posts/${postId}`)
}

// 监听器
watch(() => props.userId, (newUserId) => {
  if (newUserId) {
    loadUserData()
    loadUserPosts()
  }
}, { immediate: true })

// 生命周期
onMounted(() => {
  // 组件挂载后的初始化逻辑
})
</script>

<style scoped lang="scss">
.user-profile {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
  
  .user-info {
    display: flex;
    align-items: center;
    gap: 20px;
    margin-bottom: 30px;
    padding: 20px;
    background: white;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    
    .avatar {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      object-fit: cover;
    }
    
    h2 {
      margin: 0;
      color: #333;
      font-size: 24px;
    }
    
    p {
      margin: 5px 0 0;
      color: #666;
    }
  }
  
  .user-stats {
    display: flex;
    gap: 20px;
    margin-bottom: 20px;
    
    .stat-item {
      flex: 1;
      text-align: center;
      padding: 15px;
      background: white;
      border-radius: 8px;
      box-shadow: 0 1px 4px rgba(0, 0, 0, 0.1);
      
      .label {
        display: block;
        color: #666;
        font-size: 14px;
        margin-bottom: 5px;
      }
      
      .value {
        display: block;
        color: #333;
        font-size: 20px;
        font-weight: bold;
      }
    }
  }
  
  .actions {
    display: flex;
    gap: 10px;
    margin-bottom: 30px;
    
    button {
      padding: 10px 20px;
      border: none;
      border-radius: 6px;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s;
      
      &:first-child {
        background: #007bff;
        color: white;
        
        &.following {
          background: #28a745;
        }
        
        &:hover:not(:disabled) {
          background: #0056b3;
          
          &.following {
            background: #218838;
          }
        }
        
        &:disabled {
          background: #ccc;
          cursor: not-allowed;
        }
      }
      
      &:last-child {
        background: #f8f9fa;
        color: #333;
        border: 1px solid #dee2e6;
        
        &:hover {
          background: #e9ecef;
        }
      }
    }
  }
  
  .posts-section {
    h3 {
      margin-bottom: 20px;
      color: #333;
    }
    
    .loading, .empty {
      text-align: center;
      padding: 40px;
      color: #666;
    }
    
    .posts-list {
      display: grid;
      gap: 15px;
      
      .post-item {
        padding: 20px;
        background: white;
        border-radius: 8px;
        box-shadow: 0 1px 4px rgba(0, 0, 0, 0.1);
        cursor: pointer;
        transition: transform 0.2s, box-shadow 0.2s;
        
        &:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }
        
        h4 {
          margin: 0 0 10px;
          color: #333;
          font-size: 18px;
        }
        
        p {
          margin: 0 0 15px;
          color: #666;
          line-height: 1.5;
        }
        
        .post-meta {
          display: flex;
          justify-content: space-between;
          font-size: 12px;
          color: #999;
        }
      }
    }
  }
}

// 响应式设计
@media (max-width: 768px) {
  .user-profile {
    padding: 15px;
    
    .user-info {
      flex-direction: column;
      text-align: center;
    }
    
    .user-stats {
      flex-direction: column;
    }
    
    .actions {
      flex-direction: column;
      
      button {
        width: 100%;
      }
    }
  }
}
</style>
```

### 组合式函数 (Composables)
```typescript
// composables/useNotification.ts
import { ref } from 'vue'

interface Notification {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  title: string
  message?: string
  duration?: number
}

const notifications = ref<Notification[]>([])

export function useNotification() {
  const showNotification = (notification: Omit<Notification, 'id'>) => {
    const id = Date.now().toString()
    const newNotification: Notification = {
      id,
      duration: 3000,
      ...notification
    }
    
    notifications.value.push(newNotification)
    
    // 自动移除通知
    setTimeout(() => {
      removeNotification(id)
    }, newNotification.duration)
    
    return id
  }
  
  const removeNotification = (id: string) => {
    const index = notifications.value.findIndex(n => n.id === id)
    if (index > -1) {
      notifications.value.splice(index, 1)
    }
  }
  
  const showSuccess = (title: string, message?: string) => {
    return showNotification({ type: 'success', title, message })
  }
  
  const showError = (title: string, message?: string) => {
    return showNotification({ type: 'error', title, message })
  }
  
  const showWarning = (title: string, message?: string) => {
    return showNotification({ type: 'warning', title, message })
  }
  
  const showInfo = (title: string, message?: string) => {
    return showNotification({ type: 'info', title, message })
  }
  
  return {
    notifications: readonly(notifications),
    showNotification,
    removeNotification,
    showSuccess,
    showError,
    showWarning,
    showInfo
  }
}

// composables/useApi.ts
import { ref, unref } from 'vue'
import type { MaybeRef } from 'vue'

interface ApiOptions {
  immediate?: boolean
  onSuccess?: (data: any) => void
  onError?: (error: Error) => void
}

export function useApi<T>(
  url: MaybeRef<string>,
  options: ApiOptions = {}
) {
  const data = ref<T | null>(null)
  const loading = ref(false)
  const error = ref<Error | null>(null)
  
  const execute = async () => {
    try {
      loading.value = true
      error.value = null
      
      const response = await fetch(unref(url))
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }
      
      const result = await response.json()
      data.value = result
      
      options.onSuccess?.(result)
      return result
    } catch (err) {
      const apiError = err instanceof Error ? err : new Error('Unknown error')
      error.value = apiError
      options.onError?.(apiError)
      throw apiError
    } finally {
      loading.value = false
    }
  }
  
  // 立即执行
  if (options.immediate !== false) {
    execute()
  }
  
  return {
    data: readonly(data),
    loading: readonly(loading),
    error: readonly(error),
    execute
  }
}

// composables/useLocalStorage.ts
import { ref, watch, Ref } from 'vue'

export function useLocalStorage<T>(
  key: string,
  defaultValue: T,
  serializer = JSON
): [Ref<T>, (value: T) => void, () => void] {
  
  const storedValue = localStorage.getItem(key)
  const initialValue = storedValue !== null 
    ? serializer.parse(storedValue) 
    : defaultValue
  
  const state = ref<T>(initialValue)
  
  const setValue = (value: T) => {
    state.value = value
  }
  
  const removeValue = () => {
    localStorage.removeItem(key)
    state.value = defaultValue
  }
  
  // 监听状态变化并同步到localStorage
  watch(
    state,
    (newValue) => {
      if (newValue === undefined || newValue === null) {
        localStorage.removeItem(key)
      } else {
        localStorage.setItem(key, serializer.stringify(newValue))
      }
    },
    { deep: true }
  )
  
  return [state, setValue, removeValue]
}
```

### Pinia状态管理
```typescript
// stores/user.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User, UserStats, Post } from '@/types'
import { userApi } from '@/api/user'

export const useUserStore = defineStore('user', () => {
  // 状态
  const currentUser = ref<User | null>(null)
  const users = ref<Map<string, User>>(new Map())
  const isAuthenticated = ref(false)
  const loading = ref(false)
  
  // 计算属性
  const userProfile = computed(() => currentUser.value)
  const isAdmin = computed(() => currentUser.value?.role === 'admin')
  
  // 操作
  const login = async (credentials: LoginCredentials) => {
    try {
      loading.value = true
      const response = await userApi.login(credentials)
      
      currentUser.value = response.user
      isAuthenticated.value = true
      
      // 存储token
      localStorage.setItem('auth_token', response.token)
      
      return response
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    } finally {
      loading.value = false
    }
  }
  
  const logout = async () => {
    try {
      await userApi.logout()
    } catch (error) {
      console.error('Logout failed:', error)
    } finally {
      currentUser.value = null
      isAuthenticated.value = false
      localStorage.removeItem('auth_token')
    }
  }
  
  const fetchUser = async (userId: string): Promise<User> => {
    // 先检查缓存
    if (users.value.has(userId)) {
      return users.value.get(userId)!
    }
    
    try {
      const user = await userApi.getUser(userId)
      users.value.set(userId, user)
      return user
    } catch (error) {
      console.error('Failed to fetch user:', error)
      throw error
    }
  }
  
  const updateProfile = async (updates: Partial<User>) => {
    if (!currentUser.value) {
      throw new Error('No current user')
    }
    
    try {
      loading.value = true
      const updatedUser = await userApi.updateProfile(updates)
      
      currentUser.value = updatedUser
      users.value.set(updatedUser.id, updatedUser)
      
      return updatedUser
    } catch (error) {
      console.error('Failed to update profile:', error)
      throw error
    } finally {
      loading.value = false
    }
  }
  
  const followUser = async (userId: string) => {
    try {
      await userApi.followUser(userId)
      
      // 更新本地状态
      if (currentUser.value) {
        currentUser.value.following = currentUser.value.following || []
        currentUser.value.following.push(userId)
      }
    } catch (error) {
      console.error('Failed to follow user:', error)
      throw error
    }
  }
  
  const unfollowUser = async (userId: string) => {
    try {
      await userApi.unfollowUser(userId)
      
      // 更新本地状态
      if (currentUser.value?.following) {
        const index = currentUser.value.following.indexOf(userId)
        if (index > -1) {
          currentUser.value.following.splice(index, 1)
        }
      }
    } catch (error) {
      console.error('Failed to unfollow user:', error)
      throw error
    }
  }
  
  const fetchUserStats = async (userId: string): Promise<UserStats> => {
    try {
      return await userApi.getUserStats(userId)
    } catch (error) {
      console.error('Failed to fetch user stats:', error)
      throw error
    }
  }
  
  const fetchUserPosts = async (
    userId: string, 
    options: { limit?: number; offset?: number } = {}
  ): Promise<Post[]> => {
    try {
      return await userApi.getUserPosts(userId, options)
    } catch (error) {
      console.error('Failed to fetch user posts:', error)
      throw error
    }
  }
  
  const checkFollowStatus = async (userId: string): Promise<boolean> => {
    if (!currentUser.value) return false
    
    try {
      return await userApi.checkFollowStatus(userId)
    } catch (error) {
      console.error('Failed to check follow status:', error)
      return false
    }
  }
  
  // 初始化
  const initialize = async () => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      try {
        const user = await userApi.getCurrentUser()
        currentUser.value = user
        isAuthenticated.value = true
      } catch (error) {
        console.error('Failed to initialize user:', error)
        localStorage.removeItem('auth_token')
      }
    }
  }
  
  return {
    // 状态
    currentUser: readonly(currentUser),
    users: readonly(users),
    isAuthenticated: readonly(isAuthenticated),
    loading: readonly(loading),
    
    // 计算属性
    userProfile,
    isAdmin,
    
    // 操作
    login,
    logout,
    fetchUser,
    updateProfile,
    followUser,
    unfollowUser,
    fetchUserStats,
    fetchUserPosts,
    checkFollowStatus,
    initialize
  }
})
```

## 配置规范

### Vite配置
```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [
    vue({
      script: {
        defineModel: true,
        propsDestructure: true
      }
    })
  ],
  
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@/components': resolve(__dirname, 'src/components'),
      '@/composables': resolve(__dirname, 'src/composables'),
      '@/stores': resolve(__dirname, 'src/stores'),
      '@/utils': resolve(__dirname, 'src/utils'),
      '@/types': resolve(__dirname, 'src/types')
    }
  },
  
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `
          @import "@/styles/variables.scss";
          @import "@/styles/mixins.scss";
        `
      }
    }
  },
  
  server: {
    port: 3000,
    open: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  },
  
  build: {
    target: 'es2015',
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: true,
    
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router', 'pinia'],
          ui: ['element-plus']
        }
      }
    }
  },
  
  optimizeDeps: {
    include: ['vue', 'vue-router', 'pinia']
  }
})
```

### TypeScript配置
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@/components/*": ["src/components/*"],
      "@/composables/*": ["src/composables/*"],
      "@/stores/*": ["src/stores/*"],
      "@/utils/*": ["src/utils/*"],
      "@/types/*": ["src/types/*"]
    }
  },
  "include": [
    "src/**/*.ts",
    "src/**/*.d.ts",
    "src/**/*.tsx",
    "src/**/*.vue"
  ],
  "references": [
    { "path": "./tsconfig.node.json" }
  ]
}
```

## 常见问题与解决方案

### 性能优化
```vue
<!-- 使用v-memo优化列表渲染 -->
<template>
  <div class="user-list">
    <div
      v-for="user in users"
      :key="user.id"
      v-memo="[user.id, user.name, user.status]"
      class="user-item"
    >
      <UserCard :user="user" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { defineAsyncComponent } from 'vue'

// 异步组件懒加载
const UserCard = defineAsyncComponent(() => import('@/components/UserCard.vue'))

// 使用shallowRef优化大型对象
import { shallowRef, triggerRef } from 'vue'

const largeData = shallowRef({
  users: [],
  posts: [],
  comments: []
})

// 更新数据时手动触发更新
const updateUsers = (newUsers) => {
  largeData.value.users = newUsers
  triggerRef(largeData)
}
</script>
```

### 错误边界
```vue
<!-- ErrorBoundary.vue -->
<template>
  <div v-if="hasError" class="error-boundary">
    <h2>出现了错误</h2>
    <p>{{ error?.message }}</p>
    <button @click="retry">重试</button>
  </div>
  <slot v-else />
</template>

<script setup lang="ts">
import { ref, onErrorCaptured } from 'vue'

const hasError = ref(false)
const error = ref<Error | null>(null)

onErrorCaptured((err) => {
  hasError.value = true
  error.value = err
  console.error('Error captured:', err)
  return false
})

const retry = () => {
  hasError.value = false
  error.value = null
}
</script>
```

## 输出模板

### 组件开发清单
```markdown
# Vue组件开发清单

## 设计阶段
- [ ] 组件职责明确
- [ ] Props接口设计
- [ ] Events定义
- [ ] 插槽规划

## 开发阶段
- [ ] TypeScript类型定义
- [ ] 响应式数据设计
- [ ] 计算属性优化
- [ ] 方法实现
- [ ] 生命周期处理

## 样式阶段
- [ ] Scoped样式
- [ ] 响应式设计
- [ ] 主题变量使用
- [ ] 动画效果

## 测试阶段
- [ ] 单元测试
- [ ] 集成测试
- [ ] 可访问性测试
- [ ] 性能测试

## 文档阶段
- [ ] 组件文档
- [ ] 使用示例
- [ ] API文档
- [ ] 变更日志
```
