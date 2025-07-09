# 架构模式规则文档

## 模式概述

### 常用架构模式
- **分层架构 (Layered Architecture)**: 将系统分为多个层次，每层只与相邻层交互
- **微服务架构 (Microservices)**: 将应用拆分为小型、独立的服务
- **事件驱动架构 (Event-Driven)**: 基于事件的松耦合架构
- **六边形架构 (Hexagonal)**: 端口和适配器模式，业务逻辑与外部依赖分离
- **CQRS (Command Query Responsibility Segregation)**: 命令查询职责分离
- **领域驱动设计 (DDD)**: 以业务领域为核心的设计方法

## 分层架构模式

### 经典三层架构
```typescript
// 表现层 (Presentation Layer)
export class UserController {
  constructor(private userService: UserService) {}

  async createUser(req: Request, res: Response) {
    try {
      const userData = req.body;
      const user = await this.userService.createUser(userData);
      res.status(201).json({ success: true, data: user });
    } catch (error) {
      res.status(400).json({ success: false, error: error.message });
    }
  }

  async getUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const user = await this.userService.getUserById(id);
      res.json({ success: true, data: user });
    } catch (error) {
      res.status(404).json({ success: false, error: error.message });
    }
  }
}

// 业务逻辑层 (Business Logic Layer)
export class UserService {
  constructor(private userRepository: UserRepository) {}

  async createUser(userData: CreateUserDto): Promise<User> {
    // 业务规则验证
    this.validateUserData(userData);
    
    // 检查邮箱唯一性
    const existingUser = await this.userRepository.findByEmail(userData.email);
    if (existingUser) {
      throw new Error('邮箱已存在');
    }

    // 密码加密
    const hashedPassword = await this.hashPassword(userData.password);
    
    // 创建用户
    return await this.userRepository.create({
      ...userData,
      password: hashedPassword,
      createdAt: new Date()
    });
  }

  async getUserById(id: string): Promise<User> {
    const user = await this.userRepository.findById(id);
    if (!user) {
      throw new Error('用户不存在');
    }
    return user;
  }

  private validateUserData(userData: CreateUserDto): void {
    if (!userData.email || !userData.password) {
      throw new Error('邮箱和密码不能为空');
    }
    
    if (userData.password.length < 8) {
      throw new Error('密码长度至少8位');
    }
  }

  private async hashPassword(password: string): Promise<string> {
    const bcrypt = await import('bcrypt');
    return bcrypt.hash(password, 12);
  }
}

// 数据访问层 (Data Access Layer)
export class UserRepository {
  constructor(private db: Database) {}

  async create(userData: CreateUserData): Promise<User> {
    const query = `
      INSERT INTO users (name, email, password, created_at)
      VALUES ($1, $2, $3, $4)
      RETURNING id, name, email, created_at
    `;
    
    const result = await this.db.query(query, [
      userData.name,
      userData.email,
      userData.password,
      userData.createdAt
    ]);
    
    return result.rows[0];
  }

  async findById(id: string): Promise<User | null> {
    const query = 'SELECT id, name, email, created_at FROM users WHERE id = $1';
    const result = await this.db.query(query, [id]);
    return result.rows[0] || null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const query = 'SELECT id, name, email, created_at FROM users WHERE email = $1';
    const result = await this.db.query(query, [email]);
    return result.rows[0] || null;
  }
}
```

## 微服务架构模式

### 服务拆分策略
```typescript
// 用户服务
export class UserMicroservice {
  constructor(
    private userService: UserService,
    private eventBus: EventBus
  ) {}

  async createUser(userData: CreateUserDto): Promise<User> {
    const user = await this.userService.createUser(userData);
    
    // 发布用户创建事件
    await this.eventBus.publish('user.created', {
      userId: user.id,
      email: user.email,
      timestamp: new Date()
    });
    
    return user;
  }
}

// 订单服务
export class OrderMicroservice {
  constructor(
    private orderService: OrderService,
    private userServiceClient: UserServiceClient,
    private eventBus: EventBus
  ) {
    // 监听用户事件
    this.eventBus.subscribe('user.created', this.handleUserCreated.bind(this));
  }

  async createOrder(orderData: CreateOrderDto): Promise<Order> {
    // 验证用户存在
    const user = await this.userServiceClient.getUser(orderData.userId);
    if (!user) {
      throw new Error('用户不存在');
    }

    const order = await this.orderService.createOrder(orderData);
    
    // 发布订单创建事件
    await this.eventBus.publish('order.created', {
      orderId: order.id,
      userId: order.userId,
      amount: order.amount,
      timestamp: new Date()
    });
    
    return order;
  }

  private async handleUserCreated(event: UserCreatedEvent): Promise<void> {
    // 为新用户创建默认设置
    await this.orderService.createUserSettings(event.userId);
  }
}

// 服务间通信
export class UserServiceClient {
  constructor(private httpClient: HttpClient) {}

  async getUser(userId: string): Promise<User | null> {
    try {
      const response = await this.httpClient.get(`/users/${userId}`);
      return response.data;
    } catch (error) {
      if (error.status === 404) {
        return null;
      }
      throw error;
    }
  }
}
```

### API网关模式
```typescript
// API网关
export class ApiGateway {
  constructor(
    private userService: UserServiceClient,
    private orderService: OrderServiceClient,
    private authService: AuthService
  ) {}

  async handleRequest(req: Request, res: Response): Promise<void> {
    try {
      // 认证
      const token = req.headers.authorization?.replace('Bearer ', '');
      const user = await this.authService.validateToken(token);
      
      // 路由到相应服务
      const result = await this.routeRequest(req, user);
      res.json(result);
    } catch (error) {
      res.status(error.statusCode || 500).json({
        error: error.message
      });
    }
  }

  private async routeRequest(req: Request, user: User): Promise<any> {
    const { path, method } = req;
    
    if (path.startsWith('/api/users')) {
      return this.userService.handleRequest(req, user);
    }
    
    if (path.startsWith('/api/orders')) {
      return this.orderService.handleRequest(req, user);
    }
    
    throw new Error('路由不存在');
  }
}
```

## 事件驱动架构

### 事件总线实现
```typescript
// 事件总线
export class EventBus {
  private handlers = new Map<string, Function[]>();

  subscribe(eventType: string, handler: Function): void {
    if (!this.handlers.has(eventType)) {
      this.handlers.set(eventType, []);
    }
    this.handlers.get(eventType)!.push(handler);
  }

  async publish(eventType: string, eventData: any): Promise<void> {
    const handlers = this.handlers.get(eventType) || [];
    
    // 并行处理所有处理器
    await Promise.all(
      handlers.map(handler => 
        this.safeExecute(handler, eventData)
      )
    );
  }

  private async safeExecute(handler: Function, eventData: any): Promise<void> {
    try {
      await handler(eventData);
    } catch (error) {
      console.error('事件处理器执行失败:', error);
      // 可以添加重试逻辑或死信队列
    }
  }
}

// 事件存储
export class EventStore {
  constructor(private db: Database) {}

  async saveEvent(event: DomainEvent): Promise<void> {
    const query = `
      INSERT INTO events (id, aggregate_id, event_type, event_data, version, timestamp)
      VALUES ($1, $2, $3, $4, $5, $6)
    `;
    
    await this.db.query(query, [
      event.id,
      event.aggregateId,
      event.type,
      JSON.stringify(event.data),
      event.version,
      event.timestamp
    ]);
  }

  async getEvents(aggregateId: string): Promise<DomainEvent[]> {
    const query = `
      SELECT * FROM events 
      WHERE aggregate_id = $1 
      ORDER BY version ASC
    `;
    
    const result = await this.db.query(query, [aggregateId]);
    return result.rows.map(row => ({
      id: row.id,
      aggregateId: row.aggregate_id,
      type: row.event_type,
      data: JSON.parse(row.event_data),
      version: row.version,
      timestamp: row.timestamp
    }));
  }
}
```

## 六边形架构模式

### 端口和适配器
```typescript
// 领域模型
export class User {
  constructor(
    private id: string,
    private name: string,
    private email: string,
    private password: string
  ) {}

  changeEmail(newEmail: string): void {
    if (!this.isValidEmail(newEmail)) {
      throw new Error('邮箱格式不正确');
    }
    this.email = newEmail;
  }

  private isValidEmail(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }

  getId(): string { return this.id; }
  getName(): string { return this.name; }
  getEmail(): string { return this.email; }
}

// 端口 (接口)
export interface UserRepository {
  save(user: User): Promise<void>;
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
}

export interface EmailService {
  sendWelcomeEmail(email: string, name: string): Promise<void>;
}

// 应用服务 (用例)
export class UserApplicationService {
  constructor(
    private userRepository: UserRepository,
    private emailService: EmailService
  ) {}

  async registerUser(userData: RegisterUserDto): Promise<void> {
    // 检查邮箱是否已存在
    const existingUser = await this.userRepository.findByEmail(userData.email);
    if (existingUser) {
      throw new Error('邮箱已存在');
    }

    // 创建用户
    const user = new User(
      this.generateId(),
      userData.name,
      userData.email,
      userData.password
    );

    // 保存用户
    await this.userRepository.save(user);

    // 发送欢迎邮件
    await this.emailService.sendWelcomeEmail(user.getEmail(), user.getName());
  }

  private generateId(): string {
    return Math.random().toString(36).substr(2, 9);
  }
}

// 适配器实现
export class PostgresUserRepository implements UserRepository {
  constructor(private db: Database) {}

  async save(user: User): Promise<void> {
    const query = `
      INSERT INTO users (id, name, email, password)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        email = EXCLUDED.email,
        password = EXCLUDED.password
    `;
    
    await this.db.query(query, [
      user.getId(),
      user.getName(),
      user.getEmail(),
      user.getPassword()
    ]);
  }

  async findById(id: string): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE id = $1';
    const result = await this.db.query(query, [id]);
    
    if (result.rows.length === 0) {
      return null;
    }
    
    const row = result.rows[0];
    return new User(row.id, row.name, row.email, row.password);
  }

  async findByEmail(email: string): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE email = $1';
    const result = await this.db.query(query, [email]);
    
    if (result.rows.length === 0) {
      return null;
    }
    
    const row = result.rows[0];
    return new User(row.id, row.name, row.email, row.password);
  }
}

export class SMTPEmailService implements EmailService {
  constructor(private smtpClient: SMTPClient) {}

  async sendWelcomeEmail(email: string, name: string): Promise<void> {
    const subject = '欢迎注册';
    const body = `亲爱的 ${name}，欢迎注册我们的服务！`;
    
    await this.smtpClient.sendEmail({
      to: email,
      subject,
      body
    });
  }
}
```

## CQRS模式

### 命令查询分离
```typescript
// 命令模型
export class CreateUserCommand {
  constructor(
    public readonly name: string,
    public readonly email: string,
    public readonly password: string
  ) {}
}

export class UpdateUserEmailCommand {
  constructor(
    public readonly userId: string,
    public readonly newEmail: string
  ) {}
}

// 命令处理器
export class UserCommandHandler {
  constructor(
    private userRepository: UserRepository,
    private eventBus: EventBus
  ) {}

  async handle(command: CreateUserCommand): Promise<void> {
    const user = new User(
      this.generateId(),
      command.name,
      command.email,
      command.password
    );

    await this.userRepository.save(user);

    await this.eventBus.publish('user.created', {
      userId: user.getId(),
      name: user.getName(),
      email: user.getEmail()
    });
  }

  async handle(command: UpdateUserEmailCommand): Promise<void> {
    const user = await this.userRepository.findById(command.userId);
    if (!user) {
      throw new Error('用户不存在');
    }

    user.changeEmail(command.newEmail);
    await this.userRepository.save(user);

    await this.eventBus.publish('user.email.changed', {
      userId: user.getId(),
      oldEmail: user.getEmail(),
      newEmail: command.newEmail
    });
  }
}

// 查询模型
export interface UserQueryModel {
  id: string;
  name: string;
  email: string;
  createdAt: Date;
  lastLoginAt?: Date;
}

export class UserQueryService {
  constructor(private readDb: ReadDatabase) {}

  async getUserById(id: string): Promise<UserQueryModel | null> {
    const query = `
      SELECT id, name, email, created_at, last_login_at
      FROM user_read_model
      WHERE id = $1
    `;
    
    const result = await this.readDb.query(query, [id]);
    return result.rows[0] || null;
  }

  async searchUsers(criteria: UserSearchCriteria): Promise<UserQueryModel[]> {
    let query = `
      SELECT id, name, email, created_at, last_login_at
      FROM user_read_model
      WHERE 1=1
    `;
    const params: any[] = [];

    if (criteria.name) {
      query += ` AND name ILIKE $${params.length + 1}`;
      params.push(`%${criteria.name}%`);
    }

    if (criteria.email) {
      query += ` AND email ILIKE $${params.length + 1}`;
      params.push(`%${criteria.email}%`);
    }

    query += ` ORDER BY created_at DESC LIMIT $${params.length + 1}`;
    params.push(criteria.limit || 50);

    const result = await this.readDb.query(query, params);
    return result.rows;
  }
}

// 读模型更新器
export class UserReadModelUpdater {
  constructor(
    private readDb: ReadDatabase,
    private eventBus: EventBus
  ) {
    this.eventBus.subscribe('user.created', this.handleUserCreated.bind(this));
    this.eventBus.subscribe('user.email.changed', this.handleEmailChanged.bind(this));
  }

  private async handleUserCreated(event: UserCreatedEvent): Promise<void> {
    const query = `
      INSERT INTO user_read_model (id, name, email, created_at)
      VALUES ($1, $2, $3, $4)
    `;
    
    await this.readDb.query(query, [
      event.userId,
      event.name,
      event.email,
      new Date()
    ]);
  }

  private async handleEmailChanged(event: UserEmailChangedEvent): Promise<void> {
    const query = `
      UPDATE user_read_model
      SET email = $2
      WHERE id = $1
    `;
    
    await this.readDb.query(query, [event.userId, event.newEmail]);
  }
}
```

## 架构决策记录

### ADR模板
```markdown
# ADR-001: 选择微服务架构

## 状态
已接受

## 上下文
我们的单体应用已经变得过于复杂，团队规模增长，需要更好的可扩展性和独立部署能力。

## 决策
采用微服务架构，按业务领域拆分服务。

## 后果
### 正面影响
- 团队可以独立开发和部署
- 技术栈选择更灵活
- 更好的故障隔离

### 负面影响
- 系统复杂性增加
- 网络延迟和分布式事务问题
- 运维复杂度提升

## 实施计划
1. 识别服务边界
2. 建立API网关
3. 实施服务发现
4. 建立监控体系
```

## 模式选择指南

### 选择标准
```yaml
团队规模:
  小团队 (< 5人): 分层架构、模块化单体
  中等团队 (5-20人): 微服务、事件驱动
  大团队 (> 20人): 微服务、DDD、CQRS

系统复杂度:
  简单系统: 分层架构
  中等复杂: 六边形架构、事件驱动
  高复杂度: DDD、CQRS、微服务

性能要求:
  一般性能: 分层架构
  高性能: CQRS、事件驱动
  极高性能: 事件溯源、微服务

可扩展性:
  垂直扩展: 单体架构
  水平扩展: 微服务架构
  弹性扩展: 云原生架构
```
