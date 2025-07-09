# Next.js 工具规则文档

## 工具概述
Next.js是一个基于React的全栈框架，提供服务端渲染、静态生成、API路由等功能。

### 适用场景
- 服务端渲染(SSR)应用
- 静态站点生成(SSG)
- 全栈Web应用开发
- 电商网站和内容管理系统
- SEO友好的React应用

### 核心特性
- **自动代码分割**: 按页面自动分割代码
- **服务端渲染**: 提升首屏加载速度和SEO
- **静态生成**: 构建时预渲染页面
- **API路由**: 内置API端点支持
- **图片优化**: 自动图片优化和懒加载

## 最佳实践

### App Router (Next.js 13+)
```typescript
// app/layout.tsx - 根布局
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata = {
  title: '我的Next.js应用',
  description: '使用Next.js构建的现代Web应用',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh-CN">
      <body className={inter.className}>
        <header>
          <nav>导航栏</nav>
        </header>
        <main>{children}</main>
        <footer>页脚</footer>
      </body>
    </html>
  )
}

// app/page.tsx - 首页
export default function HomePage() {
  return (
    <div>
      <h1>欢迎来到我的网站</h1>
      <p>这是使用Next.js App Router构建的首页</p>
    </div>
  )
}

// app/about/page.tsx - 关于页面
export default function AboutPage() {
  return (
    <div>
      <h1>关于我们</h1>
      <p>公司介绍内容</p>
    </div>
  )
}

// app/blog/[slug]/page.tsx - 动态路由
interface BlogPostProps {
  params: { slug: string }
  searchParams: { [key: string]: string | string[] | undefined }
}

export default function BlogPost({ params }: BlogPostProps) {
  return (
    <div>
      <h1>博客文章: {params.slug}</h1>
      <p>文章内容...</p>
    </div>
  )
}

// 生成静态参数
export async function generateStaticParams() {
  const posts = await fetch('https://api.example.com/posts').then(res => res.json())
  
  return posts.map((post: any) => ({
    slug: post.slug,
  }))
}

// 生成元数据
export async function generateMetadata({ params }: BlogPostProps) {
  const post = await fetch(`https://api.example.com/posts/${params.slug}`)
    .then(res => res.json())
  
  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [post.image],
    },
  }
}
```

### 数据获取模式
```typescript
// 服务端组件 - 默认行为
async function ServerComponent() {
  // 在服务端获取数据
  const data = await fetch('https://api.example.com/data', {
    cache: 'force-cache', // 静态生成
  }).then(res => res.json())

  return (
    <div>
      <h2>服务端数据</h2>
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  )
}

// 客户端组件
'use client'

import { useState, useEffect } from 'react'

function ClientComponent() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/data')
      .then(res => res.json())
      .then(data => {
        setData(data)
        setLoading(false)
      })
  }, [])

  if (loading) return <div>加载中...</div>

  return (
    <div>
      <h2>客户端数据</h2>
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  )
}

// 混合组件 - 服务端获取初始数据，客户端交互
async function HybridComponent() {
  const initialData = await fetch('https://api.example.com/initial')
    .then(res => res.json())

  return <InteractiveClient initialData={initialData} />
}

'use client'
function InteractiveClient({ initialData }: { initialData: any }) {
  const [data, setData] = useState(initialData)
  const [count, setCount] = useState(0)

  const updateData = async () => {
    const newData = await fetch('/api/update').then(res => res.json())
    setData(newData)
  }

  return (
    <div>
      <button onClick={() => setCount(count + 1)}>
        点击次数: {count}
      </button>
      <button onClick={updateData}>更新数据</button>
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  )
}
```

### API路由
```typescript
// app/api/users/route.ts - RESTful API
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

// 数据验证模式
const CreateUserSchema = z.object({
  name: z.string().min(1, '姓名不能为空'),
  email: z.string().email('邮箱格式不正确'),
  age: z.number().min(0, '年龄不能为负数').max(150, '年龄不能超过150'),
})

// GET /api/users
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    
    // 模拟数据库查询
    const users = await getUsersFromDatabase({ page, limit })
    
    return NextResponse.json({
      users,
      pagination: {
        page,
        limit,
        total: users.length,
      }
    })
  } catch (error) {
    console.error('获取用户列表失败:', error)
    return NextResponse.json(
      { error: '服务器内部错误' },
      { status: 500 }
    )
  }
}

// POST /api/users
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    // 验证请求数据
    const validatedData = CreateUserSchema.parse(body)
    
    // 检查邮箱是否已存在
    const existingUser = await findUserByEmail(validatedData.email)
    if (existingUser) {
      return NextResponse.json(
        { error: '邮箱已存在' },
        { status: 409 }
      )
    }
    
    // 创建用户
    const newUser = await createUser(validatedData)
    
    return NextResponse.json(newUser, { status: 201 })
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: '数据验证失败', details: error.errors },
        { status: 400 }
      )
    }
    
    console.error('创建用户失败:', error)
    return NextResponse.json(
      { error: '服务器内部错误' },
      { status: 500 }
    )
  }
}

// app/api/users/[id]/route.ts - 动态API路由
interface RouteParams {
  params: { id: string }
}

// GET /api/users/[id]
export async function GET(
  request: NextRequest,
  { params }: RouteParams
) {
  try {
    const user = await getUserById(params.id)
    
    if (!user) {
      return NextResponse.json(
        { error: '用户不存在' },
        { status: 404 }
      )
    }
    
    return NextResponse.json(user)
  } catch (error) {
    console.error('获取用户失败:', error)
    return NextResponse.json(
      { error: '服务器内部错误' },
      { status: 500 }
    )
  }
}

// PUT /api/users/[id]
export async function PUT(
  request: NextRequest,
  { params }: RouteParams
) {
  try {
    const body = await request.json()
    const validatedData = CreateUserSchema.partial().parse(body)
    
    const updatedUser = await updateUser(params.id, validatedData)
    
    if (!updatedUser) {
      return NextResponse.json(
        { error: '用户不存在' },
        { status: 404 }
      )
    }
    
    return NextResponse.json(updatedUser)
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: '数据验证失败', details: error.errors },
        { status: 400 }
      )
    }
    
    console.error('更新用户失败:', error)
    return NextResponse.json(
      { error: '服务器内部错误' },
      { status: 500 }
    )
  }
}

// DELETE /api/users/[id]
export async function DELETE(
  request: NextRequest,
  { params }: RouteParams
) {
  try {
    const deleted = await deleteUser(params.id)
    
    if (!deleted) {
      return NextResponse.json(
        { error: '用户不存在' },
        { status: 404 }
      )
    }
    
    return NextResponse.json({ message: '用户删除成功' })
  } catch (error) {
    console.error('删除用户失败:', error)
    return NextResponse.json(
      { error: '服务器内部错误' },
      { status: 500 }
    )
  }
}
```

### 中间件
```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // 认证检查
  const token = request.cookies.get('auth-token')?.value
  
  // 保护的路径
  const protectedPaths = ['/dashboard', '/profile', '/admin']
  const isProtectedPath = protectedPaths.some(path => 
    request.nextUrl.pathname.startsWith(path)
  )
  
  if (isProtectedPath && !token) {
    // 重定向到登录页
    const loginUrl = new URL('/login', request.url)
    loginUrl.searchParams.set('redirect', request.nextUrl.pathname)
    return NextResponse.redirect(loginUrl)
  }
  
  // 管理员路径检查
  if (request.nextUrl.pathname.startsWith('/admin')) {
    const userRole = request.headers.get('x-user-role')
    if (userRole !== 'admin') {
      return NextResponse.redirect(new URL('/unauthorized', request.url))
    }
  }
  
  // 添加安全头
  const response = NextResponse.next()
  response.headers.set('X-Frame-Options', 'DENY')
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('Referrer-Policy', 'origin-when-cross-origin')
  
  return response
}

export const config = {
  matcher: [
    /*
     * 匹配所有路径除了:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
}

### 性能优化
```typescript
// 图片优化
import Image from 'next/image'

function OptimizedImageComponent() {
  return (
    <div>
      {/* 响应式图片 */}
      <Image
        src="/hero-image.jpg"
        alt="英雄图片"
        width={800}
        height={600}
        priority // 首屏图片优先加载
        placeholder="blur"
        blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ..."
      />

      {/* 填充容器的图片 */}
      <div style={{ position: 'relative', width: '100%', height: '400px' }}>
        <Image
          src="/background.jpg"
          alt="背景图片"
          fill
          style={{ objectFit: 'cover' }}
          sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
        />
      </div>
    </div>
  )
}

// 字体优化
import { Inter, Roboto_Mono } from 'next/font/google'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
})

const robotoMono = Roboto_Mono({
  subsets: ['latin'],
  display: 'swap',
})

// 动态导入和代码分割
import dynamic from 'next/dynamic'

// 懒加载组件
const DynamicComponent = dynamic(() => import('../components/HeavyComponent'), {
  loading: () => <p>加载中...</p>,
  ssr: false, // 禁用服务端渲染
})

// 条件加载
const AdminPanel = dynamic(() => import('../components/AdminPanel'), {
  ssr: false,
})

function Dashboard({ user }: { user: User }) {
  return (
    <div>
      <h1>仪表板</h1>
      {user.role === 'admin' && <AdminPanel />}
      <DynamicComponent />
    </div>
  )
}

// 预加载关键资源
import { useRouter } from 'next/navigation'

function NavigationComponent() {
  const router = useRouter()

  const handleMouseEnter = () => {
    // 预加载页面
    router.prefetch('/important-page')
  }

  return (
    <nav>
      <a
        href="/important-page"
        onMouseEnter={handleMouseEnter}
      >
        重要页面
      </a>
    </nav>
  )
}
```

### 状态管理
```typescript
// 使用Zustand进行状态管理
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface UserStore {
  user: User | null
  isLoading: boolean
  login: (credentials: LoginCredentials) => Promise<void>
  logout: () => void
  updateProfile: (data: Partial<User>) => Promise<void>
}

export const useUserStore = create<UserStore>()(
  persist(
    (set, get) => ({
      user: null,
      isLoading: false,

      login: async (credentials) => {
        set({ isLoading: true })
        try {
          const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(credentials),
          })

          if (!response.ok) throw new Error('登录失败')

          const user = await response.json()
          set({ user, isLoading: false })
        } catch (error) {
          set({ isLoading: false })
          throw error
        }
      },

      logout: () => {
        set({ user: null })
        // 清除认证cookie
        document.cookie = 'auth-token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;'
      },

      updateProfile: async (data) => {
        const { user } = get()
        if (!user) return

        set({ isLoading: true })
        try {
          const response = await fetch(`/api/users/${user.id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data),
          })

          if (!response.ok) throw new Error('更新失败')

          const updatedUser = await response.json()
          set({ user: updatedUser, isLoading: false })
        } catch (error) {
          set({ isLoading: false })
          throw error
        }
      },
    }),
    {
      name: 'user-storage',
      partialize: (state) => ({ user: state.user }), // 只持久化用户信息
    }
  )
)

// 在组件中使用
function UserProfile() {
  const { user, isLoading, updateProfile } = useUserStore()
  const [formData, setFormData] = useState({ name: '', email: '' })

  useEffect(() => {
    if (user) {
      setFormData({ name: user.name, email: user.email })
    }
  }, [user])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await updateProfile(formData)
      alert('更新成功')
    } catch (error) {
      alert('更新失败')
    }
  }

  if (!user) return <div>请先登录</div>

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={formData.name}
        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
        placeholder="姓名"
      />
      <input
        value={formData.email}
        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
        placeholder="邮箱"
      />
      <button type="submit" disabled={isLoading}>
        {isLoading ? '更新中...' : '更新'}
      </button>
    </form>
  )
}
```

### 数据库集成
```typescript
// lib/db.ts - 数据库连接
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma

// lib/auth.ts - 认证工具
import { SignJWT, jwtVerify } from 'jose'
import { cookies } from 'next/headers'

const secretKey = process.env.JWT_SECRET
const key = new TextEncoder().encode(secretKey)

export async function encrypt(payload: any) {
  return await new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('24h')
    .sign(key)
}

export async function decrypt(input: string): Promise<any> {
  const { payload } = await jwtVerify(input, key, {
    algorithms: ['HS256'],
  })
  return payload
}

export async function getSession() {
  const session = cookies().get('session')?.value
  if (!session) return null
  return await decrypt(session)
}

// app/api/auth/login/route.ts
import { NextRequest, NextResponse } from 'next/server'
import bcrypt from 'bcryptjs'
import { prisma } from '@/lib/db'
import { encrypt } from '@/lib/auth'

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json()

    // 查找用户
    const user = await prisma.user.findUnique({
      where: { email },
    })

    if (!user || !await bcrypt.compare(password, user.password)) {
      return NextResponse.json(
        { error: '邮箱或密码错误' },
        { status: 401 }
      )
    }

    // 创建会话
    const session = await encrypt({ userId: user.id, email: user.email })

    // 设置cookie
    const response = NextResponse.json({
      user: { id: user.id, name: user.name, email: user.email }
    })

    response.cookies.set('session', session, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24, // 24小时
    })

    return response
  } catch (error) {
    console.error('登录失败:', error)
    return NextResponse.json(
      { error: '服务器内部错误' },
      { status: 500 }
    )
  }
}
```

## 常见问题与解决方案

### 水合错误(Hydration Errors)
```typescript
// 问题: 服务端和客户端渲染不一致
// ❌ 错误示例
function ProblematicComponent() {
  return <div>{new Date().toLocaleString()}</div> // 服务端和客户端时间不同
}

// ✅ 正确示例
'use client'
import { useState, useEffect } from 'react'

function TimeComponent() {
  const [time, setTime] = useState<string>('')

  useEffect(() => {
    setTime(new Date().toLocaleString())
  }, [])

  return <div>{time || '加载中...'}</div>
}

// 或者使用动态导入禁用SSR
const TimeComponent = dynamic(() => import('./TimeComponent'), {
  ssr: false,
})
```

### 性能问题
```typescript
// 问题: 不必要的重渲染
// ❌ 错误示例
function ParentComponent() {
  const [count, setCount] = useState(0)

  return (
    <div>
      <button onClick={() => setCount(count + 1)}>Count: {count}</button>
      <ExpensiveChild data={{ value: 'static' }} /> {/* 每次都创建新对象 */}
    </div>
  )
}

// ✅ 正确示例
function ParentComponent() {
  const [count, setCount] = useState(0)
  const staticData = useMemo(() => ({ value: 'static' }), [])

  return (
    <div>
      <button onClick={() => setCount(count + 1)}>Count: {count}</button>
      <ExpensiveChild data={staticData} />
    </div>
  )
}

const ExpensiveChild = memo(function ExpensiveChild({ data }: { data: any }) {
  // 昂贵的计算
  return <div>{data.value}</div>
})
```

## Next.js开发最佳实践检查清单

### 项目结构
```markdown
- [ ] 使用App Router进行路由管理
- [ ] 合理组织组件和页面结构
- [ ] 配置TypeScript和ESLint
- [ ] 设置环境变量管理
- [ ] 配置数据库和ORM
```

### 性能优化
```markdown
- [ ] 使用Next.js Image组件优化图片
- [ ] 实现代码分割和懒加载
- [ ] 配置字体优化
- [ ] 使用适当的渲染策略(SSR/SSG/CSR)
- [ ] 实现缓存策略
```

### SEO和可访问性
```markdown
- [ ] 配置元数据和Open Graph
- [ ] 实现结构化数据
- [ ] 确保语义化HTML
- [ ] 支持键盘导航
- [ ] 提供替代文本和ARIA标签
```

### 安全性
```markdown
- [ ] 实现认证和授权
- [ ] 配置CSRF保护
- [ ] 使用HTTPS和安全头
- [ ] 验证和清理用户输入
- [ ] 保护敏感API端点
```

### 部署和监控
```markdown
- [ ] 配置生产环境构建
- [ ] 设置错误监控
- [ ] 实现性能监控
- [ ] 配置日志记录
- [ ] 设置健康检查端点
```
```
