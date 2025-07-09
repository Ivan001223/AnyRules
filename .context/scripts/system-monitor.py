#!/usr/bin/env python3

"""
系统监控脚本
用法: python system-monitor.py [--interval 5] [--output monitor.log] [--alert-cpu 80] [--alert-memory 85]
"""

import psutil
import time
import json
import argparse
import logging
import smtplib
from datetime import datetime
from email.mime.text import MimeText
from email.mime.multipart import MimeMultipart
import os

class SystemMonitor:
    def __init__(self, interval=5, output_file=None, alert_cpu=80, alert_memory=85):
        self.interval = interval
        self.output_file = output_file
        self.alert_cpu = alert_cpu
        self.alert_memory = alert_memory
        self.alert_sent = {'cpu': False, 'memory': False, 'disk': False}
        
        # 设置日志
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(output_file or 'system_monitor.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def get_system_info(self):
        """获取系统信息"""
        try:
            # CPU 信息
            cpu_percent = psutil.cpu_percent(interval=1)
            cpu_count = psutil.cpu_count()
            cpu_freq = psutil.cpu_freq()
            
            # 内存信息
            memory = psutil.virtual_memory()
            swap = psutil.swap_memory()
            
            # 磁盘信息
            disk_usage = psutil.disk_usage('/')
            disk_io = psutil.disk_io_counters()
            
            # 网络信息
            network_io = psutil.net_io_counters()
            
            # 进程信息
            processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                try:
                    proc_info = proc.info
                    if proc_info['cpu_percent'] > 1.0 or proc_info['memory_percent'] > 1.0:
                        processes.append(proc_info)
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
            
            # 按CPU使用率排序
            processes.sort(key=lambda x: x['cpu_percent'], reverse=True)
            
            return {
                'timestamp': datetime.now().isoformat(),
                'cpu': {
                    'percent': cpu_percent,
                    'count': cpu_count,
                    'frequency': cpu_freq.current if cpu_freq else None
                },
                'memory': {
                    'total': memory.total,
                    'available': memory.available,
                    'percent': memory.percent,
                    'used': memory.used,
                    'free': memory.free
                },
                'swap': {
                    'total': swap.total,
                    'used': swap.used,
                    'percent': swap.percent
                },
                'disk': {
                    'total': disk_usage.total,
                    'used': disk_usage.used,
                    'free': disk_usage.free,
                    'percent': (disk_usage.used / disk_usage.total) * 100,
                    'read_bytes': disk_io.read_bytes if disk_io else 0,
                    'write_bytes': disk_io.write_bytes if disk_io else 0
                },
                'network': {
                    'bytes_sent': network_io.bytes_sent,
                    'bytes_recv': network_io.bytes_recv,
                    'packets_sent': network_io.packets_sent,
                    'packets_recv': network_io.packets_recv
                },
                'top_processes': processes[:10]
            }
        except Exception as e:
            self.logger.error(f"获取系统信息失败: {e}")
            return None
    
    def format_bytes(self, bytes_value):
        """格式化字节数"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_value < 1024.0:
                return f"{bytes_value:.2f} {unit}"
            bytes_value /= 1024.0
        return f"{bytes_value:.2f} PB"
    
    def check_alerts(self, system_info):
        """检查告警条件"""
        alerts = []
        
        # CPU 告警
        if system_info['cpu']['percent'] > self.alert_cpu:
            if not self.alert_sent['cpu']:
                alerts.append(f"🚨 CPU使用率过高: {system_info['cpu']['percent']:.1f}%")
                self.alert_sent['cpu'] = True
        else:
            self.alert_sent['cpu'] = False
        
        # 内存告警
        if system_info['memory']['percent'] > self.alert_memory:
            if not self.alert_sent['memory']:
                alerts.append(f"🚨 内存使用率过高: {system_info['memory']['percent']:.1f}%")
                self.alert_sent['memory'] = True
        else:
            self.alert_sent['memory'] = False
        
        # 磁盘告警
        if system_info['disk']['percent'] > 90:
            if not self.alert_sent['disk']:
                alerts.append(f"🚨 磁盘使用率过高: {system_info['disk']['percent']:.1f}%")
                self.alert_sent['disk'] = True
        else:
            self.alert_sent['disk'] = False
        
        return alerts
    
    def send_alert_email(self, alerts):
        """发送告警邮件"""
        try:
            smtp_server = os.getenv('SMTP_SERVER', 'smtp.gmail.com')
            smtp_port = int(os.getenv('SMTP_PORT', '587'))
            email_user = os.getenv('EMAIL_USER')
            email_password = os.getenv('EMAIL_PASSWORD')
            alert_recipients = os.getenv('ALERT_RECIPIENTS', '').split(',')
            
            if not email_user or not email_password or not alert_recipients[0]:
                self.logger.warning("邮件配置不完整，跳过邮件告警")
                return
            
            msg = MimeMultipart()
            msg['From'] = email_user
            msg['To'] = ', '.join(alert_recipients)
            msg['Subject'] = f"系统监控告警 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
            
            body = "检测到以下系统告警:\n\n" + '\n'.join(alerts)
            msg.attach(MimeText(body, 'plain'))
            
            server = smtplib.SMTP(smtp_server, smtp_port)
            server.starttls()
            server.login(email_user, email_password)
            server.send_message(msg)
            server.quit()
            
            self.logger.info("告警邮件发送成功")
        except Exception as e:
            self.logger.error(f"发送告警邮件失败: {e}")
    
    def display_system_info(self, system_info):
        """显示系统信息"""
        print("\n" + "="*60)
        print(f"📊 系统监控报告 - {system_info['timestamp']}")
        print("="*60)
        
        # CPU 信息
        print(f"🖥️  CPU: {system_info['cpu']['percent']:.1f}% "
              f"({system_info['cpu']['count']} 核心)")
        
        # 内存信息
        memory = system_info['memory']
        print(f"💾 内存: {memory['percent']:.1f}% "
              f"({self.format_bytes(memory['used'])} / {self.format_bytes(memory['total'])})")
        
        # 磁盘信息
        disk = system_info['disk']
        print(f"💿 磁盘: {disk['percent']:.1f}% "
              f"({self.format_bytes(disk['used'])} / {self.format_bytes(disk['total'])})")
        
        # 网络信息
        network = system_info['network']
        print(f"🌐 网络: ↑{self.format_bytes(network['bytes_sent'])} "
              f"↓{self.format_bytes(network['bytes_recv'])}")
        
        # 进程信息
        if system_info['top_processes']:
            print("\n🔝 CPU占用最高的进程:")
            for i, proc in enumerate(system_info['top_processes'][:5], 1):
                print(f"  {i}. {proc['name']} (PID: {proc['pid']}) - "
                      f"CPU: {proc['cpu_percent']:.1f}% "
                      f"内存: {proc['memory_percent']:.1f}%")
    
    def run(self):
        """运行监控"""
        self.logger.info("开始系统监控...")
        print(f"🚀 系统监控启动 (间隔: {self.interval}秒)")
        print("按 Ctrl+C 停止监控")
        
        try:
            while True:
                system_info = self.get_system_info()
                if system_info:
                    # 显示信息
                    self.display_system_info(system_info)
                    
                    # 检查告警
                    alerts = self.check_alerts(system_info)
                    if alerts:
                        for alert in alerts:
                            print(alert)
                            self.logger.warning(alert)
                        self.send_alert_email(alerts)
                    
                    # 记录到文件
                    if self.output_file:
                        with open(self.output_file, 'a') as f:
                            f.write(json.dumps(system_info) + '\n')
                
                time.sleep(self.interval)
                
        except KeyboardInterrupt:
            print("\n👋 监控已停止")
            self.logger.info("监控已停止")

def main():
    parser = argparse.ArgumentParser(description='系统监控脚本')
    parser.add_argument('--interval', type=int, default=5, help='监控间隔(秒)')
    parser.add_argument('--output', type=str, help='输出日志文件')
    parser.add_argument('--alert-cpu', type=int, default=80, help='CPU告警阈值(%)')
    parser.add_argument('--alert-memory', type=int, default=85, help='内存告警阈值(%)')
    
    args = parser.parse_args()
    
    monitor = SystemMonitor(
        interval=args.interval,
        output_file=args.output,
        alert_cpu=args.alert_cpu,
        alert_memory=args.alert_memory
    )
    
    monitor.run()

if __name__ == "__main__":
    main()
