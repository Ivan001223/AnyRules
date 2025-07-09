#!/usr/bin/env python3

"""
日志分析脚本
用法: python log-analyzer.py <log-file> [--format nginx|apache|json] [--errors-only] [--top 10]
"""

import re
import json
import argparse
import sys
from collections import Counter, defaultdict
from datetime import datetime
import geoip2.database
import geoip2.errors

class LogAnalyzer:
    def __init__(self, log_file, log_format='nginx', errors_only=False, top_count=10):
        self.log_file = log_file
        self.log_format = log_format
        self.errors_only = errors_only
        self.top_count = top_count
        
        # 日志格式正则表达式
        self.patterns = {
            'nginx': r'(?P<ip>\d+\.\d+\.\d+\.\d+) - - \[(?P<timestamp>[^\]]+)\] "(?P<method>\w+) (?P<url>[^"]*)" (?P<status>\d+) (?P<size>\d+) "(?P<referer>[^"]*)" "(?P<user_agent>[^"]*)"',
            'apache': r'(?P<ip>\d+\.\d+\.\d+\.\d+) - - \[(?P<timestamp>[^\]]+)\] "(?P<method>\w+) (?P<url>[^"]*)" (?P<status>\d+) (?P<size>\d+)',
            'json': None  # JSON格式特殊处理
        }
        
        # 统计数据
        self.stats = {
            'total_requests': 0,
            'status_codes': Counter(),
            'ips': Counter(),
            'urls': Counter(),
            'user_agents': Counter(),
            'methods': Counter(),
            'errors': [],
            'hourly_requests': defaultdict(int),
            'response_sizes': []
        }
    
    def parse_nginx_log(self, line):
        """解析Nginx日志"""
        pattern = self.patterns['nginx']
        match = re.match(pattern, line)
        if match:
            return match.groupdict()
        return None
    
    def parse_apache_log(self, line):
        """解析Apache日志"""
        pattern = self.patterns['apache']
        match = re.match(pattern, line)
        if match:
            return match.groupdict()
        return None
    
    def parse_json_log(self, line):
        """解析JSON日志"""
        try:
            return json.loads(line)
        except json.JSONDecodeError:
            return None
    
    def parse_line(self, line):
        """解析单行日志"""
        if self.log_format == 'nginx':
            return self.parse_nginx_log(line)
        elif self.log_format == 'apache':
            return self.parse_apache_log(line)
        elif self.log_format == 'json':
            return self.parse_json_log(line)
        return None
    
    def is_error_status(self, status):
        """判断是否为错误状态码"""
        try:
            status_code = int(status)
            return status_code >= 400
        except ValueError:
            return False
    
    def get_hour_from_timestamp(self, timestamp):
        """从时间戳提取小时"""
        try:
            if self.log_format in ['nginx', 'apache']:
                # 格式: 10/Oct/2023:14:30:45 +0000
                dt = datetime.strptime(timestamp.split()[0], '%d/%b/%Y:%H:%M:%S')
                return dt.hour
            elif self.log_format == 'json':
                # 假设JSON中有timestamp字段
                dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                return dt.hour
        except (ValueError, AttributeError):
            pass
        return 0
    
    def analyze_log(self):
        """分析日志文件"""
        print(f"📊 开始分析日志文件: {self.log_file}")
        
        try:
            with open(self.log_file, 'r', encoding='utf-8', errors='ignore') as f:
                for line_num, line in enumerate(f, 1):
                    line = line.strip()
                    if not line:
                        continue
                    
                    parsed = self.parse_line(line)
                    if not parsed:
                        continue
                    
                    # 统一字段名
                    ip = parsed.get('ip') or parsed.get('remote_addr')
                    status = parsed.get('status') or parsed.get('status_code')
                    url = parsed.get('url') or parsed.get('request_uri')
                    method = parsed.get('method') or parsed.get('request_method')
                    user_agent = parsed.get('user_agent')
                    timestamp = parsed.get('timestamp') or parsed.get('time')
                    size = parsed.get('size') or parsed.get('body_bytes_sent')
                    
                    # 如果只分析错误，跳过正常请求
                    if self.errors_only and not self.is_error_status(status):
                        continue
                    
                    # 更新统计
                    self.stats['total_requests'] += 1
                    
                    if status:
                        self.stats['status_codes'][status] += 1
                        
                        # 记录错误详情
                        if self.is_error_status(status):
                            self.stats['errors'].append({
                                'line': line_num,
                                'ip': ip,
                                'status': status,
                                'url': url,
                                'timestamp': timestamp
                            })
                    
                    if ip:
                        self.stats['ips'][ip] += 1
                    
                    if url:
                        self.stats['urls'][url] += 1
                    
                    if method:
                        self.stats['methods'][method] += 1
                    
                    if user_agent:
                        self.stats['user_agents'][user_agent] += 1
                    
                    if timestamp:
                        hour = self.get_hour_from_timestamp(timestamp)
                        self.stats['hourly_requests'][hour] += 1
                    
                    if size and size.isdigit():
                        self.stats['response_sizes'].append(int(size))
                    
                    # 进度显示
                    if line_num % 10000 == 0:
                        print(f"已处理 {line_num} 行...")
        
        except FileNotFoundError:
            print(f"❌ 文件不存在: {self.log_file}")
            sys.exit(1)
        except Exception as e:
            print(f"❌ 分析失败: {e}")
            sys.exit(1)
    
    def get_geo_info(self, ip):
        """获取IP地理位置信息"""
        try:
            # 需要下载GeoLite2数据库
            # wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb
            with geoip2.database.Reader('GeoLite2-City.mmdb') as reader:
                response = reader.city(ip)
                return f"{response.country.name}, {response.city.name}"
        except (geoip2.errors.AddressNotFoundError, FileNotFoundError):
            return "Unknown"
    
    def print_report(self):
        """打印分析报告"""
        print("\n" + "="*60)
        print("📈 日志分析报告")
        print("="*60)
        
        # 基本统计
        print(f"📊 总请求数: {self.stats['total_requests']:,}")
        print(f"❌ 错误请求数: {len(self.stats['errors']):,}")
        
        if self.stats['response_sizes']:
            avg_size = sum(self.stats['response_sizes']) / len(self.stats['response_sizes'])
            print(f"📦 平均响应大小: {avg_size:.2f} bytes")
        
        # 状态码统计
        if self.stats['status_codes']:
            print(f"\n📋 状态码分布 (Top {self.top_count}):")
            for status, count in self.stats['status_codes'].most_common(self.top_count):
                percentage = (count / self.stats['total_requests']) * 100
                print(f"  {status}: {count:,} ({percentage:.1f}%)")
        
        # IP统计
        if self.stats['ips']:
            print(f"\n🌐 访问IP (Top {self.top_count}):")
            for ip, count in self.stats['ips'].most_common(self.top_count):
                percentage = (count / self.stats['total_requests']) * 100
                print(f"  {ip}: {count:,} ({percentage:.1f}%)")
        
        # URL统计
        if self.stats['urls']:
            print(f"\n🔗 访问URL (Top {self.top_count}):")
            for url, count in self.stats['urls'].most_common(self.top_count):
                percentage = (count / self.stats['total_requests']) * 100
                url_display = url[:50] + "..." if len(url) > 50 else url
                print(f"  {url_display}: {count:,} ({percentage:.1f}%)")
        
        # 请求方法统计
        if self.stats['methods']:
            print(f"\n📝 请求方法:")
            for method, count in self.stats['methods'].most_common():
                percentage = (count / self.stats['total_requests']) * 100
                print(f"  {method}: {count:,} ({percentage:.1f}%)")
        
        # 小时分布
        if self.stats['hourly_requests']:
            print(f"\n⏰ 小时分布:")
            for hour in range(24):
                count = self.stats['hourly_requests'][hour]
                if count > 0:
                    percentage = (count / self.stats['total_requests']) * 100
                    bar = "█" * int(percentage / 2)
                    print(f"  {hour:02d}:00 {bar} {count:,} ({percentage:.1f}%)")
        
        # 错误详情
        if self.stats['errors'] and not self.errors_only:
            print(f"\n❌ 最近错误 (Top {min(10, len(self.stats['errors']))}):")
            for error in self.stats['errors'][-10:]:
                print(f"  行{error['line']}: {error['ip']} - {error['status']} - {error['url']}")
        
        # 用户代理统计
        if self.stats['user_agents'] and not self.errors_only:
            print(f"\n🖥️ 用户代理 (Top 5):")
            for ua, count in self.stats['user_agents'].most_common(5):
                percentage = (count / self.stats['total_requests']) * 100
                ua_display = ua[:60] + "..." if len(ua) > 60 else ua
                print(f"  {ua_display}: {count:,} ({percentage:.1f}%)")
    
    def save_report(self, output_file):
        """保存分析报告到文件"""
        report_data = {
            'timestamp': datetime.now().isoformat(),
            'log_file': self.log_file,
            'total_requests': self.stats['total_requests'],
            'error_count': len(self.stats['errors']),
            'top_ips': dict(self.stats['ips'].most_common(self.top_count)),
            'top_urls': dict(self.stats['urls'].most_common(self.top_count)),
            'status_codes': dict(self.stats['status_codes']),
            'methods': dict(self.stats['methods']),
            'hourly_distribution': dict(self.stats['hourly_requests'])
        }
        
        with open(output_file, 'w') as f:
            json.dump(report_data, f, indent=2)
        
        print(f"📄 报告已保存到: {output_file}")

def main():
    parser = argparse.ArgumentParser(description='日志分析脚本')
    parser.add_argument('log_file', help='日志文件路径')
    parser.add_argument('--format', choices=['nginx', 'apache', 'json'], 
                       default='nginx', help='日志格式')
    parser.add_argument('--errors-only', action='store_true', 
                       help='只分析错误请求')
    parser.add_argument('--top', type=int, default=10, 
                       help='显示Top N结果')
    parser.add_argument('--output', help='保存报告到文件')
    
    args = parser.parse_args()
    
    analyzer = LogAnalyzer(
        log_file=args.log_file,
        log_format=args.format,
        errors_only=args.errors_only,
        top_count=args.top
    )
    
    analyzer.analyze_log()
    analyzer.print_report()
    
    if args.output:
        analyzer.save_report(args.output)

if __name__ == "__main__":
    main()
