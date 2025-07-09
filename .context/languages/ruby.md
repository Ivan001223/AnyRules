# Ruby 语言规则文档

## 语言特性

### 核心优势
- **优雅语法**: 简洁优雅的语法，接近自然语言
- **面向对象**: 纯面向对象语言，一切皆对象
- **动态特性**: 动态类型、元编程能力强
- **开发效率**: 快速开发，代码简洁易读
- **丰富生态**: 庞大的Gem生态系统

### Ruby语言特性
```ruby
# 变量和常量
name = "张三"
age = 25
PI = 3.14159

# 字符串插值
message = "Hello, #{name}! You are #{age} years old."

# 符号
status = :active
user_type = :admin

# 数组和哈希
users = ["张三", "李四", "王五"]
user_info = {
  name: "张三",
  email: "zhangsan@example.com",
  age: 25
}

# 块和迭代器
users.each { |user| puts user }
numbers = (1..10).map { |n| n * 2 }
adults = users.select { |user| user[:age] >= 18 }

# 类定义
class User
  attr_accessor :name, :email
  attr_reader :id, :created_at
  
  def initialize(name, email)
    @id = SecureRandom.uuid
    @name = name
    @email = email
    @created_at = Time.now
  end
  
  def valid_email?
    @email.include?("@") && @email.include?(".")
  end
  
  def adult?
    @age && @age >= 18
  end
  
  def to_s
    "User: #{@name} (#{@email})"
  end
  
  # 类方法
  def self.find_by_email(email)
    # 查找用户逻辑
  end
  
  private
  
  def validate_email
    raise ArgumentError, "Invalid email" unless valid_email?
  end
end

# 模块和混入
module Timestampable
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def with_timestamps
      attr_accessor :created_at, :updated_at
      
      define_method :touch do
        @updated_at = Time.now
      end
    end
  end
  
  def created_recently?
    @created_at && @created_at > 1.day.ago
  end
end

class Post
  include Timestampable
  with_timestamps
  
  attr_accessor :title, :content, :author
  
  def initialize(title, content, author)
    @title = title
    @content = content
    @author = author
    @created_at = Time.now
  end
end

# 异常处理
def fetch_user(id)
  begin
    # 获取用户逻辑
    user = User.find(id)
    raise UserNotFoundError, "User #{id} not found" unless user
    user
  rescue UserNotFoundError => e
    puts "Error: #{e.message}"
    nil
  rescue StandardError => e
    puts "Unexpected error: #{e.message}"
    nil
  ensure
    # 清理代码
    puts "Cleanup completed"
  end
end

# 元编程
class DynamicModel
  def self.define_attribute(name)
    define_method(name) do
      instance_variable_get("@#{name}")
    end
    
    define_method("#{name}=") do |value|
      instance_variable_set("@#{name}", value)
    end
  end
  
  def method_missing(method_name, *args)
    if method_name.to_s.end_with?('=')
      attr_name = method_name.to_s.chomp('=')
      instance_variable_set("@#{attr_name}", args.first)
    elsif instance_variable_defined?("@#{method_name}")
      instance_variable_get("@#{method_name}")
    else
      super
    end
  end
  
  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.end_with?('=') || 
    instance_variable_defined?("@#{method_name}") || 
    super
  end
end
```

## Rails框架开发

### MVC架构
```ruby
# 模型 (app/models/user.rb)
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_one :profile, dependent: :destroy
  
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  
  before_save :normalize_email
  after_create :send_welcome_email
  
  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(created_at: :desc) }
  
  enum status: { active: 0, inactive: 1, suspended: 2 }
  
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def adult?
    birth_date && birth_date < 18.years.ago
  end
  
  def recent_posts(limit = 5)
    posts.published.order(created_at: :desc).limit(limit)
  end
  
  private
  
  def normalize_email
    self.email = email.downcase.strip
  end
  
  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
  
  def password_required?
    new_record? || password.present?
  end
end

# 控制器 (app/controllers/users_controller.rb)
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user!, only: [:edit, :update, :destroy]
  
  def index
    @users = User.includes(:profile)
                 .active
                 .page(params[:page])
                 .per(20)
    
    @users = @users.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    
    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end
  
  def show
    @posts = @user.recent_posts
    
    respond_to do |format|
      format.html
      format.json { render json: UserSerializer.new(@user) }
    end
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(user_params)
    
    if @user.save
      redirect_to @user, notice: '用户创建成功'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @user.update(user_params)
      redirect_to @user, notice: '用户更新成功'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @user.destroy
    redirect_to users_url, notice: '用户删除成功'
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to users_path, alert: '用户不存在'
  end
  
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :birth_date)
  end
  
  def authorize_user!
    redirect_to root_path, alert: '权限不足' unless can?(:manage, @user)
  end
end

# 视图 (app/views/users/index.html.erb)
<div class="users-index">
  <div class="header">
    <h1>用户列表</h1>
    <%= link_to "新建用户", new_user_path, class: "btn btn-primary" %>
  </div>
  
  <div class="search">
    <%= form_with url: users_path, method: :get, local: true do |form| %>
      <%= form.text_field :search, placeholder: "搜索用户...", value: params[:search] %>
      <%= form.submit "搜索", class: "btn btn-secondary" %>
    <% end %>
  </div>
  
  <div class="users-grid">
    <% @users.each do |user| %>
      <div class="user-card">
        <h3><%= link_to user.name, user_path(user) %></h3>
        <p><%= user.email %></p>
        <p class="status <%= user.status %>"><%= user.status.humanize %></p>
        <div class="actions">
          <%= link_to "查看", user_path(user), class: "btn btn-sm" %>
          <% if can?(:edit, user) %>
            <%= link_to "编辑", edit_user_path(user), class: "btn btn-sm" %>
          <% end %>
          <% if can?(:destroy, user) %>
            <%= link_to "删除", user_path(user), method: :delete, 
                        confirm: "确定删除吗？", class: "btn btn-sm btn-danger" %>
          <% end %>
        </div>
      </div>
    <% end %>
  </div>
  
  <%= paginate @users %>
</div>
```

### 服务对象和关注点
```ruby
# 服务对象 (app/services/user_service.rb)
class UserService
  def initialize(user)
    @user = user
  end
  
  def activate!
    return false if @user.active?
    
    ActiveRecord::Base.transaction do
      @user.update!(status: :active, activated_at: Time.current)
      UserMailer.activation_confirmation(@user).deliver_later
      ActivityLogger.log(@user, :activated)
    end
    
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to activate user #{@user.id}: #{e.message}"
    false
  end
  
  def deactivate!(reason = nil)
    return false unless @user.active?
    
    ActiveRecord::Base.transaction do
      @user.update!(status: :inactive, deactivated_at: Time.current)
      @user.sessions.destroy_all  # 注销所有会话
      UserMailer.deactivation_notice(@user, reason).deliver_later if reason
      ActivityLogger.log(@user, :deactivated, reason: reason)
    end
    
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to deactivate user #{@user.id}: #{e.message}"
    false
  end
  
  def self.bulk_import(csv_data)
    results = { success: 0, errors: [] }
    
    CSV.parse(csv_data, headers: true) do |row|
      user = User.new(
        name: row['name'],
        email: row['email'],
        password: SecureRandom.hex(8)
      )
      
      if user.save
        results[:success] += 1
        UserMailer.account_created(user).deliver_later
      else
        results[:errors] << { row: row.to_h, errors: user.errors.full_messages }
      end
    end
    
    results
  end
end

# 关注点 (app/models/concerns/searchable.rb)
module Searchable
  extend ActiveSupport::Concern
  
  included do
    scope :search, ->(query) { where("#{search_fields.join(' || ')} ILIKE ?", "%#{query}%") }
  end
  
  class_methods do
    def search_fields
      @search_fields ||= []
    end
    
    def searchable_by(*fields)
      @search_fields = fields.map(&:to_s)
    end
  end
end

# 使用关注点
class User < ApplicationRecord
  include Searchable
  
  searchable_by :name, :email
  
  # 其他代码...
end

# 后台任务 (app/jobs/user_cleanup_job.rb)
class UserCleanupJob < ApplicationJob
  queue_as :default
  
  def perform
    # 删除30天前的未激活用户
    User.where(status: :inactive)
        .where('created_at < ?', 30.days.ago)
        .find_each do |user|
      user.destroy
      Rails.logger.info "Cleaned up inactive user: #{user.email}"
    end
    
    # 清理过期的会话
    Session.where('expires_at < ?', Time.current).delete_all
  end
end
```

### API开发
```ruby
# API控制器 (app/controllers/api/v1/users_controller.rb)
class Api::V1::UsersController < Api::V1::BaseController
  before_action :authenticate_api_user!
  before_action :set_user, only: [:show, :update, :destroy]
  
  def index
    @users = User.includes(:profile)
                 .page(params[:page])
                 .per(params[:per_page] || 20)
    
    render json: {
      data: UserSerializer.new(@users).serializable_hash[:data],
      meta: pagination_meta(@users)
    }
  end
  
  def show
    render json: UserSerializer.new(@user, include: [:profile, :posts])
  end
  
  def create
    @user = User.new(user_params)
    
    if @user.save
      render json: UserSerializer.new(@user), status: :created
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end
  
  def update
    if @user.update(user_params)
      render json: UserSerializer.new(@user)
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @user.destroy
    head :no_content
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end
  
  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
  
  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end

# 序列化器 (app/serializers/user_serializer.rb)
class UserSerializer
  include JSONAPI::Serializer
  
  attributes :name, :email, :status, :created_at, :updated_at
  
  attribute :full_name do |user|
    user.full_name
  end
  
  attribute :avatar_url do |user|
    user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(user.avatar) : nil
  end
  
  has_one :profile, serializer: UserProfileSerializer
  has_many :posts, serializer: PostSerializer
  
  # 条件包含
  attribute :email do |user, params|
    user.email if params[:current_user]&.can?(:view_email, user)
  end
end
```

## 测试

### RSpec测试
```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(50) }
  end
  
  describe 'associations' do
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_one(:profile).dependent(:destroy) }
  end
  
  describe 'scopes' do
    let!(:active_user) { create(:user, status: :active) }
    let!(:inactive_user) { create(:user, status: :inactive) }
    
    describe '.active' do
      it 'returns only active users' do
        expect(User.active).to include(active_user)
        expect(User.active).not_to include(inactive_user)
      end
    end
  end
  
  describe '#full_name' do
    let(:user) { build(:user, first_name: '张', last_name: '三') }
    
    it 'returns the full name' do
      expect(user.full_name).to eq('张 三')
    end
  end
  
  describe '#adult?' do
    context 'when user is over 18' do
      let(:user) { build(:user, birth_date: 20.years.ago) }
      
      it 'returns true' do
        expect(user.adult?).to be true
      end
    end
    
    context 'when user is under 18' do
      let(:user) { build(:user, birth_date: 16.years.ago) }
      
      it 'returns false' do
        expect(user.adult?).to be false
      end
    end
  end
end

# spec/controllers/users_controller_spec.rb
RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  
  before { sign_in user }
  
  describe 'GET #index' do
    let!(:users) { create_list(:user, 3) }
    
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end
    
    it 'assigns @users' do
      get :index
      expect(assigns(:users)).to match_array(User.all)
    end
    
    context 'with search parameter' do
      let!(:john) { create(:user, name: 'John Doe') }
      let!(:jane) { create(:user, name: 'Jane Smith') }
      
      it 'filters users by name' do
        get :index, params: { search: 'John' }
        expect(assigns(:users)).to include(john)
        expect(assigns(:users)).not_to include(jane)
      end
    end
  end
  
  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          name: '新用户',
          email: 'newuser@example.com',
          password: 'password123'
        }
      end
      
      it 'creates a new user' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end
      
      it 'redirects to the created user' do
        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(User.last)
      end
    end
    
    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          name: '',
          email: 'invalid-email',
          password: '123'
        }
      end
      
      it 'does not create a new user' do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end
      
      it 'renders the new template' do
        post :create, params: { user: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end
  end
end

# spec/services/user_service_spec.rb
RSpec.describe UserService do
  let(:user) { create(:user, status: :inactive) }
  let(:service) { described_class.new(user) }
  
  describe '#activate!' do
    it 'activates the user' do
      expect { service.activate! }.to change { user.reload.status }.to('active')
    end
    
    it 'sets activated_at timestamp' do
      service.activate!
      expect(user.reload.activated_at).to be_present
    end
    
    it 'sends activation confirmation email' do
      expect(UserMailer).to receive(:activation_confirmation).with(user).and_return(double(deliver_later: true))
      service.activate!
    end
    
    context 'when user is already active' do
      let(:user) { create(:user, status: :active) }
      
      it 'returns false' do
        expect(service.activate!).to be false
      end
    end
  end
end
```

## 性能优化

### 数据库优化
```ruby
# 查询优化
class User < ApplicationRecord
  # 使用includes避免N+1查询
  scope :with_posts, -> { includes(:posts) }
  scope :with_profile, -> { includes(:profile) }
  
  # 使用joins进行内连接
  scope :with_published_posts, -> { joins(:posts).where(posts: { published: true }) }
  
  # 使用select只获取需要的字段
  scope :basic_info, -> { select(:id, :name, :email, :status) }
  
  # 批量处理
  def self.bulk_update_status(user_ids, status)
    where(id: user_ids).update_all(status: status, updated_at: Time.current)
  end
  
  # 使用find_each处理大量数据
  def self.send_newsletter
    User.active.find_each(batch_size: 1000) do |user|
      NewsletterMailer.weekly(user).deliver_later
    end
  end
end

# 缓存策略
class User < ApplicationRecord
  # 模型缓存
  def cached_posts
    Rails.cache.fetch("user_#{id}_posts", expires_in: 1.hour) do
      posts.published.order(created_at: :desc).limit(10)
    end
  end
  
  # 计数器缓存
  has_many :posts, counter_cache: true
  
  # 缓存失效
  after_update :clear_cache
  
  private
  
  def clear_cache
    Rails.cache.delete("user_#{id}_posts")
  end
end

# 后台任务
class DataExportJob < ApplicationJob
  queue_as :low_priority
  
  def perform(user_id, format = 'csv')
    user = User.find(user_id)
    
    case format
    when 'csv'
      csv_data = generate_csv_data(user)
      UserMailer.data_export(user, csv_data).deliver_now
    when 'json'
      json_data = generate_json_data(user)
      UserMailer.data_export(user, json_data).deliver_now
    end
  end
  
  private
  
  def generate_csv_data(user)
    CSV.generate do |csv|
      csv << ['Name', 'Email', 'Created At', 'Posts Count']
      csv << [user.name, user.email, user.created_at, user.posts.count]
    end
  end
end
```

## 学习建议

### 基础学习路径
1. **Ruby语法基础**: 变量、方法、类、模块、块
2. **面向对象**: 继承、多态、封装、混入
3. **元编程**: 动态方法定义、method_missing
4. **标准库**: 文件操作、网络编程、正则表达式

### Rails框架学习
1. **MVC架构**: 模型、视图、控制器分离
2. **ActiveRecord**: ORM、关联、验证、回调
3. **路由系统**: RESTful路由、嵌套路由
4. **测试**: RSpec、FactoryBot、集成测试

### 进阶学习重点
1. **API开发**: JSON API、GraphQL、认证授权
2. **性能优化**: 查询优化、缓存策略、后台任务
3. **部署运维**: Docker、Capistrano、监控
4. **架构设计**: 服务对象、设计模式、微服务

### 实践项目建议
1. **博客系统**: 学习基础CRUD和用户认证
2. **电商平台**: 学习复杂业务逻辑和支付集成
3. **社交网络**: 学习实时功能和复杂关联
4. **API服务**: 学习RESTful API设计和开发
