# 设计模式规则文档

## 模式概述

### 设计模式分类
- **创建型模式**: 对象创建机制，增加创建对象的灵活性和复用性
- **结构型模式**: 对象组合方式，形成更大的结构
- **行为型模式**: 对象间的通信和职责分配

### 设计原则
- **单一职责原则**: 一个类只有一个引起变化的原因
- **开闭原则**: 对扩展开放，对修改关闭
- **里氏替换原则**: 子类可以替换父类
- **接口隔离原则**: 客户端不应依赖不需要的接口
- **依赖倒置原则**: 依赖抽象而不是具体实现

## 创建型模式

### 单例模式 (Singleton)
```typescript
// 线程安全的单例实现
class DatabaseConnection {
  private static instance: DatabaseConnection | null = null;
  private static readonly lock = {};
  private connection: any;

  private constructor() {
    // 私有构造函数，防止外部实例化
    this.connection = this.createConnection();
  }

  public static getInstance(): DatabaseConnection {
    if (!DatabaseConnection.instance) {
      // 双重检查锁定
      if (!DatabaseConnection.instance) {
        DatabaseConnection.instance = new DatabaseConnection();
      }
    }
    return DatabaseConnection.instance;
  }

  private createConnection() {
    // 创建数据库连接的逻辑
    return {
      host: 'localhost',
      port: 5432,
      database: 'myapp'
    };
  }

  public query(sql: string): Promise<any> {
    // 执行查询
    return Promise.resolve([]);
  }

  public close(): void {
    // 关闭连接
    this.connection = null;
  }
}

// 使用示例
const db1 = DatabaseConnection.getInstance();
const db2 = DatabaseConnection.getInstance();
console.log(db1 === db2); // true，同一个实例

// 现代JavaScript/TypeScript的单例实现
class ConfigManager {
  private config: Record<string, any> = {};

  constructor() {
    this.loadConfig();
  }

  private loadConfig() {
    // 加载配置逻辑
    this.config = {
      apiUrl: process.env.API_URL || 'http://localhost:3000',
      timeout: parseInt(process.env.TIMEOUT || '5000'),
      retries: parseInt(process.env.RETRIES || '3')
    };
  }

  public get(key: string): any {
    return this.config[key];
  }

  public set(key: string, value: any): void {
    this.config[key] = value;
  }
}

// 导出单例实例
export const configManager = new ConfigManager();
```

### 工厂模式 (Factory)
```typescript
// 抽象产品
interface Logger {
  log(message: string): void;
  error(message: string): void;
  warn(message: string): void;
}

// 具体产品
class ConsoleLogger implements Logger {
  log(message: string): void {
    console.log(`[LOG] ${new Date().toISOString()}: ${message}`);
  }

  error(message: string): void {
    console.error(`[ERROR] ${new Date().toISOString()}: ${message}`);
  }

  warn(message: string): void {
    console.warn(`[WARN] ${new Date().toISOString()}: ${message}`);
  }
}

class FileLogger implements Logger {
  private filename: string;

  constructor(filename: string) {
    this.filename = filename;
  }

  log(message: string): void {
    this.writeToFile(`[LOG] ${new Date().toISOString()}: ${message}`);
  }

  error(message: string): void {
    this.writeToFile(`[ERROR] ${new Date().toISOString()}: ${message}`);
  }

  warn(message: string): void {
    this.writeToFile(`[WARN] ${new Date().toISOString()}: ${message}`);
  }

  private writeToFile(message: string): void {
    // 写入文件的逻辑
    console.log(`Writing to ${this.filename}: ${message}`);
  }
}

class RemoteLogger implements Logger {
  private endpoint: string;

  constructor(endpoint: string) {
    this.endpoint = endpoint;
  }

  log(message: string): void {
    this.sendToRemote('LOG', message);
  }

  error(message: string): void {
    this.sendToRemote('ERROR', message);
  }

  warn(message: string): void {
    this.sendToRemote('WARN', message);
  }

  private sendToRemote(level: string, message: string): void {
    // 发送到远程服务的逻辑
    console.log(`Sending to ${this.endpoint}: [${level}] ${message}`);
  }
}

// 工厂类
class LoggerFactory {
  public static createLogger(type: string, ...args: any[]): Logger {
    switch (type.toLowerCase()) {
      case 'console':
        return new ConsoleLogger();
      case 'file':
        return new FileLogger(args[0] || 'app.log');
      case 'remote':
        return new RemoteLogger(args[0] || 'http://localhost:8080/logs');
      default:
        throw new Error(`Unknown logger type: ${type}`);
    }
  }
}

// 抽象工厂模式
abstract class LoggerAbstractFactory {
  abstract createLogger(): Logger;
  abstract createFormatter(): LogFormatter;
}

interface LogFormatter {
  format(level: string, message: string): string;
}

class JSONFormatter implements LogFormatter {
  format(level: string, message: string): string {
    return JSON.stringify({
      timestamp: new Date().toISOString(),
      level,
      message
    });
  }
}

class PlainTextFormatter implements LogFormatter {
  format(level: string, message: string): string {
    return `${new Date().toISOString()} [${level}] ${message}`;
  }
}

class ProductionLoggerFactory extends LoggerAbstractFactory {
  createLogger(): Logger {
    return new RemoteLogger('https://logs.production.com/api');
  }

  createFormatter(): LogFormatter {
    return new JSONFormatter();
  }
}

class DevelopmentLoggerFactory extends LoggerAbstractFactory {
  createLogger(): Logger {
    return new ConsoleLogger();
  }

  createFormatter(): LogFormatter {
    return new PlainTextFormatter();
  }
}

// 使用示例
const logger = LoggerFactory.createLogger('console');
logger.log('Application started');

const factory = process.env.NODE_ENV === 'production' 
  ? new ProductionLoggerFactory() 
  : new DevelopmentLoggerFactory();

const prodLogger = factory.createLogger();
const formatter = factory.createFormatter();
```

### 建造者模式 (Builder)
```typescript
// 复杂对象
class HttpRequest {
  public url: string = '';
  public method: string = 'GET';
  public headers: Record<string, string> = {};
  public body?: any;
  public timeout: number = 5000;
  public retries: number = 0;
  public auth?: { username: string; password: string };

  public async execute(): Promise<any> {
    // 执行HTTP请求的逻辑
    console.log(`Executing ${this.method} request to ${this.url}`);
    console.log('Headers:', this.headers);
    console.log('Body:', this.body);
    return { status: 200, data: 'Success' };
  }
}

// 建造者
class HttpRequestBuilder {
  private request: HttpRequest;

  constructor() {
    this.request = new HttpRequest();
  }

  public url(url: string): HttpRequestBuilder {
    this.request.url = url;
    return this;
  }

  public method(method: string): HttpRequestBuilder {
    this.request.method = method.toUpperCase();
    return this;
  }

  public header(key: string, value: string): HttpRequestBuilder {
    this.request.headers[key] = value;
    return this;
  }

  public headers(headers: Record<string, string>): HttpRequestBuilder {
    this.request.headers = { ...this.request.headers, ...headers };
    return this;
  }

  public body(body: any): HttpRequestBuilder {
    this.request.body = body;
    return this;
  }

  public timeout(timeout: number): HttpRequestBuilder {
    this.request.timeout = timeout;
    return this;
  }

  public retries(retries: number): HttpRequestBuilder {
    this.request.retries = retries;
    return this;
  }

  public auth(username: string, password: string): HttpRequestBuilder {
    this.request.auth = { username, password };
    return this;
  }

  public json(data: any): HttpRequestBuilder {
    this.request.body = JSON.stringify(data);
    this.request.headers['Content-Type'] = 'application/json';
    return this;
  }

  public build(): HttpRequest {
    // 验证必要字段
    if (!this.request.url) {
      throw new Error('URL is required');
    }
    return this.request;
  }
}

// 使用示例
const request = new HttpRequestBuilder()
  .url('https://api.example.com/users')
  .method('POST')
  .header('Authorization', 'Bearer token123')
  .json({ name: 'John Doe', email: 'john@example.com' })
  .timeout(10000)
  .retries(3)
  .build();

request.execute();

// 流式建造者模式
class QueryBuilder {
  private query: string = '';
  private conditions: string[] = [];
  private orderBy: string[] = [];
  private limitValue?: number;

  public select(fields: string[]): QueryBuilder {
    this.query = `SELECT ${fields.join(', ')}`;
    return this;
  }

  public from(table: string): QueryBuilder {
    this.query += ` FROM ${table}`;
    return this;
  }

  public where(condition: string): QueryBuilder {
    this.conditions.push(condition);
    return this;
  }

  public and(condition: string): QueryBuilder {
    if (this.conditions.length === 0) {
      throw new Error('Cannot use AND without a WHERE clause');
    }
    this.conditions.push(`AND ${condition}`);
    return this;
  }

  public or(condition: string): QueryBuilder {
    if (this.conditions.length === 0) {
      throw new Error('Cannot use OR without a WHERE clause');
    }
    this.conditions.push(`OR ${condition}`);
    return this;
  }

  public order(field: string, direction: 'ASC' | 'DESC' = 'ASC'): QueryBuilder {
    this.orderBy.push(`${field} ${direction}`);
    return this;
  }

  public limit(count: number): QueryBuilder {
    this.limitValue = count;
    return this;
  }

  public build(): string {
    let sql = this.query;

    if (this.conditions.length > 0) {
      sql += ` WHERE ${this.conditions.join(' ')}`;
    }

    if (this.orderBy.length > 0) {
      sql += ` ORDER BY ${this.orderBy.join(', ')}`;
    }

    if (this.limitValue) {
      sql += ` LIMIT ${this.limitValue}`;
    }

    return sql;
  }
}

// 使用示例
const sql = new QueryBuilder()
  .select(['id', 'name', 'email'])
  .from('users')
  .where('age > 18')
  .and('status = "active"')
  .order('created_at', 'DESC')
  .limit(10)
  .build();

console.log(sql);
// 输出: SELECT id, name, email FROM users WHERE age > 18 AND status = "active" ORDER BY created_at DESC LIMIT 10
```

## 结构型模式

### 适配器模式 (Adapter)
```typescript
// 旧的支付接口
class OldPaymentService {
  public makePayment(amount: number, currency: string): boolean {
    console.log(`Processing payment of ${amount} ${currency} via old system`);
    return Math.random() > 0.1; // 90% 成功率
  }
}

// 新的支付接口
interface PaymentProcessor {
  processPayment(paymentData: PaymentData): Promise<PaymentResult>;
}

interface PaymentData {
  amount: number;
  currency: string;
  cardNumber: string;
  expiryDate: string;
  cvv: string;
}

interface PaymentResult {
  success: boolean;
  transactionId?: string;
  errorMessage?: string;
}

// 适配器
class PaymentAdapter implements PaymentProcessor {
  private oldService: OldPaymentService;

  constructor(oldService: OldPaymentService) {
    this.oldService = oldService;
  }

  public async processPayment(paymentData: PaymentData): Promise<PaymentResult> {
    try {
      // 将新接口的数据适配到旧接口
      const success = this.oldService.makePayment(
        paymentData.amount,
        paymentData.currency
      );

      if (success) {
        return {
          success: true,
          transactionId: this.generateTransactionId()
        };
      } else {
        return {
          success: false,
          errorMessage: 'Payment failed'
        };
      }
    } catch (error) {
      return {
        success: false,
        errorMessage: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  private generateTransactionId(): string {
    return `TXN_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

// 使用示例
const oldPaymentService = new OldPaymentService();
const paymentProcessor: PaymentProcessor = new PaymentAdapter(oldPaymentService);

const paymentData: PaymentData = {
  amount: 100.00,
  currency: 'USD',
  cardNumber: '1234-5678-9012-3456',
  expiryDate: '12/25',
  cvv: '123'
};

paymentProcessor.processPayment(paymentData).then(result => {
  console.log('Payment result:', result);
});
```

### 装饰器模式 (Decorator)
```typescript
// 基础组件接口
interface Coffee {
  cost(): number;
  description(): string;
}

// 基础实现
class SimpleCoffee implements Coffee {
  cost(): number {
    return 2.0;
  }

  description(): string {
    return 'Simple coffee';
  }
}

// 装饰器基类
abstract class CoffeeDecorator implements Coffee {
  protected coffee: Coffee;

  constructor(coffee: Coffee) {
    this.coffee = coffee;
  }

  cost(): number {
    return this.coffee.cost();
  }

  description(): string {
    return this.coffee.description();
  }
}

// 具体装饰器
class MilkDecorator extends CoffeeDecorator {
  cost(): number {
    return this.coffee.cost() + 0.5;
  }

  description(): string {
    return this.coffee.description() + ', milk';
  }
}

class SugarDecorator extends CoffeeDecorator {
  cost(): number {
    return this.coffee.cost() + 0.2;
  }

  description(): string {
    return this.coffee.description() + ', sugar';
  }
}

class WhipDecorator extends CoffeeDecorator {
  cost(): number {
    return this.coffee.cost() + 0.7;
  }

  description(): string {
    return this.coffee.description() + ', whip';
  }
}

// 使用示例
let coffee: Coffee = new SimpleCoffee();
console.log(`${coffee.description()} costs $${coffee.cost()}`);

coffee = new MilkDecorator(coffee);
console.log(`${coffee.description()} costs $${coffee.cost()}`);

coffee = new SugarDecorator(coffee);
console.log(`${coffee.description()} costs $${coffee.cost()}`);

coffee = new WhipDecorator(coffee);
console.log(`${coffee.description()} costs $${coffee.cost()}`);

// 函数式装饰器模式
type LogLevel = 'info' | 'warn' | 'error';

function withLogging(level: LogLevel = 'info') {
  return function <T extends (...args: any[]) => any>(
    target: any,
    propertyName: string,
    descriptor: TypedPropertyDescriptor<T>
  ) {
    const method = descriptor.value!;

    descriptor.value = function (...args: any[]) {
      console.log(`[${level.toUpperCase()}] Calling ${propertyName} with args:`, args);
      
      const start = Date.now();
      const result = method.apply(this, args);
      const duration = Date.now() - start;
      
      console.log(`[${level.toUpperCase()}] ${propertyName} completed in ${duration}ms`);
      
      return result;
    } as any;

    return descriptor;
  };
}

function withRetry(maxAttempts: number = 3) {
  return function <T extends (...args: any[]) => Promise<any>>(
    target: any,
    propertyName: string,
    descriptor: TypedPropertyDescriptor<T>
  ) {
    const method = descriptor.value!;

    descriptor.value = async function (...args: any[]) {
      let lastError: Error;
      
      for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          return await method.apply(this, args);
        } catch (error) {
          lastError = error as Error;
          console.log(`Attempt ${attempt} failed:`, error);
          
          if (attempt < maxAttempts) {
            await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
          }
        }
      }
      
      throw lastError!;
    } as any;

    return descriptor;
  };
}

// 使用装饰器
class ApiService {
  @withLogging('info')
  @withRetry(3)
  async fetchUserData(userId: string): Promise<any> {
    // 模拟API调用
    if (Math.random() < 0.7) {
      throw new Error('Network error');
    }
    
    return { id: userId, name: 'John Doe' };
  }
}
```

## 行为型模式

### 观察者模式 (Observer)
```typescript
// 观察者接口
interface Observer<T> {
  update(data: T): void;
}

// 主题接口
interface Subject<T> {
  subscribe(observer: Observer<T>): void;
  unsubscribe(observer: Observer<T>): void;
  notify(data: T): void;
}

// 具体主题
class EventEmitter<T> implements Subject<T> {
  private observers: Observer<T>[] = [];

  subscribe(observer: Observer<T>): void {
    this.observers.push(observer);
  }

  unsubscribe(observer: Observer<T>): void {
    const index = this.observers.indexOf(observer);
    if (index > -1) {
      this.observers.splice(index, 1);
    }
  }

  notify(data: T): void {
    this.observers.forEach(observer => observer.update(data));
  }
}

// 具体观察者
class EmailNotifier implements Observer<string> {
  private email: string;

  constructor(email: string) {
    this.email = email;
  }

  update(message: string): void {
    console.log(`Sending email to ${this.email}: ${message}`);
  }
}

class SMSNotifier implements Observer<string> {
  private phoneNumber: string;

  constructor(phoneNumber: string) {
    this.phoneNumber = phoneNumber;
  }

  update(message: string): void {
    console.log(`Sending SMS to ${this.phoneNumber}: ${message}`);
  }
}

class PushNotifier implements Observer<string> {
  private deviceId: string;

  constructor(deviceId: string) {
    this.deviceId = deviceId;
  }

  update(message: string): void {
    console.log(`Sending push notification to ${this.deviceId}: ${message}`);
  }
}

// 使用示例
const notificationService = new EventEmitter<string>();

const emailNotifier = new EmailNotifier('user@example.com');
const smsNotifier = new SMSNotifier('+1234567890');
const pushNotifier = new PushNotifier('device123');

notificationService.subscribe(emailNotifier);
notificationService.subscribe(smsNotifier);
notificationService.subscribe(pushNotifier);

notificationService.notify('Your order has been shipped!');

// 现代JavaScript的观察者模式
class ModernEventEmitter<T = any> {
  private events: Map<string, Set<(data: T) => void>> = new Map();

  on(event: string, callback: (data: T) => void): () => void {
    if (!this.events.has(event)) {
      this.events.set(event, new Set());
    }
    
    this.events.get(event)!.add(callback);
    
    // 返回取消订阅函数
    return () => this.off(event, callback);
  }

  off(event: string, callback: (data: T) => void): void {
    const callbacks = this.events.get(event);
    if (callbacks) {
      callbacks.delete(callback);
      if (callbacks.size === 0) {
        this.events.delete(event);
      }
    }
  }

  emit(event: string, data: T): void {
    const callbacks = this.events.get(event);
    if (callbacks) {
      callbacks.forEach(callback => callback(data));
    }
  }

  once(event: string, callback: (data: T) => void): void {
    const onceCallback = (data: T) => {
      callback(data);
      this.off(event, onceCallback);
    };
    this.on(event, onceCallback);
  }
}

// 使用示例
const emitter = new ModernEventEmitter<{ userId: string; action: string }>();

const unsubscribe = emitter.on('user-action', (data) => {
  console.log(`User ${data.userId} performed action: ${data.action}`);
});

emitter.emit('user-action', { userId: '123', action: 'login' });

// 取消订阅
unsubscribe();
```

### 策略模式 (Strategy)
```typescript
// 策略接口
interface PaymentStrategy {
  pay(amount: number): Promise<boolean>;
  validate(): boolean;
}

// 具体策略
class CreditCardPayment implements PaymentStrategy {
  private cardNumber: string;
  private expiryDate: string;
  private cvv: string;

  constructor(cardNumber: string, expiryDate: string, cvv: string) {
    this.cardNumber = cardNumber;
    this.expiryDate = expiryDate;
    this.cvv = cvv;
  }

  validate(): boolean {
    // 信用卡验证逻辑
    return this.cardNumber.length === 16 && 
           this.cvv.length === 3 && 
           this.expiryDate.includes('/');
  }

  async pay(amount: number): Promise<boolean> {
    if (!this.validate()) {
      throw new Error('Invalid credit card details');
    }
    
    console.log(`Processing credit card payment of $${amount}`);
    // 模拟支付处理
    await new Promise(resolve => setTimeout(resolve, 1000));
    return Math.random() > 0.1; // 90% 成功率
  }
}

class PayPalPayment implements PaymentStrategy {
  private email: string;
  private password: string;

  constructor(email: string, password: string) {
    this.email = email;
    this.password = password;
  }

  validate(): boolean {
    return this.email.includes('@') && this.password.length >= 6;
  }

  async pay(amount: number): Promise<boolean> {
    if (!this.validate()) {
      throw new Error('Invalid PayPal credentials');
    }
    
    console.log(`Processing PayPal payment of $${amount}`);
    await new Promise(resolve => setTimeout(resolve, 800));
    return Math.random() > 0.05; // 95% 成功率
  }
}

class CryptocurrencyPayment implements PaymentStrategy {
  private walletAddress: string;
  private privateKey: string;

  constructor(walletAddress: string, privateKey: string) {
    this.walletAddress = walletAddress;
    this.privateKey = privateKey;
  }

  validate(): boolean {
    return this.walletAddress.length === 42 && this.privateKey.length === 64;
  }

  async pay(amount: number): Promise<boolean> {
    if (!this.validate()) {
      throw new Error('Invalid cryptocurrency wallet details');
    }
    
    console.log(`Processing cryptocurrency payment of $${amount}`);
    await new Promise(resolve => setTimeout(resolve, 2000));
    return Math.random() > 0.15; // 85% 成功率
  }
}

// 上下文类
class PaymentProcessor {
  private strategy: PaymentStrategy;

  constructor(strategy: PaymentStrategy) {
    this.strategy = strategy;
  }

  setStrategy(strategy: PaymentStrategy): void {
    this.strategy = strategy;
  }

  async processPayment(amount: number): Promise<boolean> {
    try {
      return await this.strategy.pay(amount);
    } catch (error) {
      console.error('Payment failed:', error);
      return false;
    }
  }
}

// 使用示例
const processor = new PaymentProcessor(
  new CreditCardPayment('1234567890123456', '12/25', '123')
);

processor.processPayment(100).then(success => {
  console.log('Credit card payment:', success ? 'Success' : 'Failed');
});

// 切换策略
processor.setStrategy(new PayPalPayment('user@example.com', 'password123'));
processor.processPayment(50).then(success => {
  console.log('PayPal payment:', success ? 'Success' : 'Failed');
});

// 函数式策略模式
type SortStrategy<T> = (a: T, b: T) => number;

class Sorter<T> {
  private strategy: SortStrategy<T>;

  constructor(strategy: SortStrategy<T>) {
    this.strategy = strategy;
  }

  setStrategy(strategy: SortStrategy<T>): void {
    this.strategy = strategy;
  }

  sort(items: T[]): T[] {
    return [...items].sort(this.strategy);
  }
}

// 排序策略
const numericAsc: SortStrategy<number> = (a, b) => a - b;
const numericDesc: SortStrategy<number> = (a, b) => b - a;
const alphabetic: SortStrategy<string> = (a, b) => a.localeCompare(b);

// 使用示例
const numberSorter = new Sorter(numericAsc);
console.log(numberSorter.sort([3, 1, 4, 1, 5, 9])); // [1, 1, 3, 4, 5, 9]

numberSorter.setStrategy(numericDesc);
console.log(numberSorter.sort([3, 1, 4, 1, 5, 9])); // [9, 5, 4, 3, 1, 1]

const stringSorter = new Sorter(alphabetic);
console.log(stringSorter.sort(['banana', 'apple', 'cherry'])); // ['apple', 'banana', 'cherry']
```

## 输出模板

### 设计模式选择指南
```markdown
# 设计模式选择指南

## 创建型模式选择
- **单例模式**: 需要全局唯一实例（配置管理、数据库连接池）
- **工厂模式**: 需要根据条件创建不同类型的对象
- **建造者模式**: 需要创建复杂对象，构造过程需要灵活控制
- **原型模式**: 需要复制现有对象，避免重复初始化

## 结构型模式选择
- **适配器模式**: 需要使用不兼容的接口
- **装饰器模式**: 需要动态添加功能，不修改原有代码
- **外观模式**: 需要简化复杂子系统的接口
- **代理模式**: 需要控制对象访问，添加额外功能

## 行为型模式选择
- **观察者模式**: 需要一对多的依赖关系，状态变化通知
- **策略模式**: 需要在运行时选择算法或行为
- **命令模式**: 需要将请求封装为对象，支持撤销操作
- **状态模式**: 对象行为随状态改变而改变

## 实施建议
1. **理解问题本质**: 分析具体需求，不要为了使用模式而使用
2. **考虑维护成本**: 模式增加复杂性，权衡收益和成本
3. **渐进式重构**: 在现有代码基础上逐步引入模式
4. **团队共识**: 确保团队成员理解所使用的模式
```
