#!/usr/bin/env python3

"""
负载测试脚本
用法: python load-test.py <url> [--concurrent 10] [--requests 100] [--duration 60]
"""

import asyncio
import aiohttp
import time
import argparse
import json
import statistics
from datetime import datetime
import sys

class LoadTester:
    def __init__(self, url, concurrent=10, total_requests=100, duration=None, timeout=30):
        self.url = url
        self.concurrent = concurrent
        self.total_requests = total_requests
        self.duration = duration
        self.timeout = timeout
        
        # 统计数据
        self.results = []
        self.errors = []
        self.start_time = None
        self.end_time = None
    
    async def make_request(self, session, request_id):
        """发送单个请求"""
        start_time = time.time()
        try:
            async with session.get(self.url, timeout=aiohttp.ClientTimeout(total=self.timeout)) as response:
                content = await response.text()
                end_time = time.time()
                
                result = {
                    'request_id': request_id,
                    'status_code': response.status,
                    'response_time': end_time - start_time,
                    'content_length': len(content),
                    'timestamp': datetime.now().isoformat()
                }
                
                self.results.append(result)
                return result
                
        except asyncio.TimeoutError:
            end_time = time.time()
            error = {
                'request_id': request_id,
                'error': 'Timeout',
                'response_time': end_time - start_time,
                'timestamp': datetime.now().isoformat()
            }
            self.errors.append(error)
            return error
            
        except Exception as e:
            end_time = time.time()
            error = {
                'request_id': request_id,
                'error': str(e),
                'response_time': end_time - start_time,
                'timestamp': datetime.now().isoformat()
            }
            self.errors.append(error)
            return error
    
    async def worker(self, session, semaphore, request_queue):
        """工作协程"""
        while True:
            try:
                request_id = await asyncio.wait_for(request_queue.get(), timeout=1.0)
                async with semaphore:
                    await self.make_request(session, request_id)
                request_queue.task_done()
            except asyncio.TimeoutError:
                break
            except Exception as e:
                print(f"Worker error: {e}")
                break
    
    async def run_duration_test(self):
        """运行基于时间的测试"""
        print(f"🚀 开始负载测试: {self.url}")
        print(f"⏱️ 测试时长: {self.duration}秒")
        print(f"🔄 并发数: {self.concurrent}")
        
        self.start_time = time.time()
        end_time = self.start_time + self.duration
        
        semaphore = asyncio.Semaphore(self.concurrent)
        request_queue = asyncio.Queue()
        
        # 创建HTTP会话
        connector = aiohttp.TCPConnector(limit=self.concurrent * 2)
        async with aiohttp.ClientSession(connector=connector) as session:
            # 启动工作协程
            workers = [
                asyncio.create_task(self.worker(session, semaphore, request_queue))
                for _ in range(self.concurrent)
            ]
            
            request_id = 0
            try:
                while time.time() < end_time:
                    await request_queue.put(request_id)
                    request_id += 1
                    
                    # 显示进度
                    if request_id % 100 == 0:
                        elapsed = time.time() - self.start_time
                        rps = len(self.results) / elapsed if elapsed > 0 else 0
                        print(f"📊 已发送 {request_id} 个请求, RPS: {rps:.2f}")
                
                # 等待队列清空
                await request_queue.join()
                
            finally:
                # 取消工作协程
                for worker in workers:
                    worker.cancel()
                
                await asyncio.gather(*workers, return_exceptions=True)
        
        self.end_time = time.time()
    
    async def run_count_test(self):
        """运行基于请求数量的测试"""
        print(f"🚀 开始负载测试: {self.url}")
        print(f"📊 总请求数: {self.total_requests}")
        print(f"🔄 并发数: {self.concurrent}")
        
        self.start_time = time.time()
        
        semaphore = asyncio.Semaphore(self.concurrent)
        
        # 创建HTTP会话
        connector = aiohttp.TCPConnector(limit=self.concurrent * 2)
        async with aiohttp.ClientSession(connector=connector) as session:
            # 创建任务
            tasks = []
            for i in range(self.total_requests):
                task = asyncio.create_task(self.make_request(session, i))
                tasks.append(task)
                
                # 控制并发数
                if len(tasks) >= self.concurrent:
                    await asyncio.gather(*tasks[:self.concurrent])
                    tasks = tasks[self.concurrent:]
                
                # 显示进度
                if (i + 1) % 100 == 0:
                    elapsed = time.time() - self.start_time
                    rps = len(self.results) / elapsed if elapsed > 0 else 0
                    print(f"📊 已发送 {i + 1} 个请求, RPS: {rps:.2f}")
            
            # 等待剩余任务完成
            if tasks:
                await asyncio.gather(*tasks)
        
        self.end_time = time.time()
    
    def calculate_statistics(self):
        """计算统计数据"""
        if not self.results:
            return None
        
        response_times = [r['response_time'] for r in self.results]
        status_codes = [r['status_code'] for r in self.results]
        content_lengths = [r['content_length'] for r in self.results]
        
        total_time = self.end_time - self.start_time
        total_requests = len(self.results) + len(self.errors)
        successful_requests = len(self.results)
        
        stats = {
            'total_time': total_time,
            'total_requests': total_requests,
            'successful_requests': successful_requests,
            'failed_requests': len(self.errors),
            'success_rate': (successful_requests / total_requests) * 100 if total_requests > 0 else 0,
            'requests_per_second': successful_requests / total_time if total_time > 0 else 0,
            'response_time': {
                'min': min(response_times),
                'max': max(response_times),
                'mean': statistics.mean(response_times),
                'median': statistics.median(response_times),
                'p95': self.percentile(response_times, 95),
                'p99': self.percentile(response_times, 99)
            },
            'content_length': {
                'min': min(content_lengths),
                'max': max(content_lengths),
                'mean': statistics.mean(content_lengths)
            },
            'status_codes': self.count_status_codes(status_codes)
        }
        
        return stats
    
    def percentile(self, data, percentile):
        """计算百分位数"""
        sorted_data = sorted(data)
        index = int((percentile / 100) * len(sorted_data))
        return sorted_data[min(index, len(sorted_data) - 1)]
    
    def count_status_codes(self, status_codes):
        """统计状态码"""
        counts = {}
        for code in status_codes:
            counts[code] = counts.get(code, 0) + 1
        return counts
    
    def print_report(self):
        """打印测试报告"""
        stats = self.calculate_statistics()
        if not stats:
            print("❌ 没有成功的请求，无法生成报告")
            return
        
        print("\n" + "="*60)
        print("📈 负载测试报告")
        print("="*60)
        
        print(f"🎯 目标URL: {self.url}")
        print(f"⏱️ 测试时长: {stats['total_time']:.2f} 秒")
        print(f"📊 总请求数: {stats['total_requests']:,}")
        print(f"✅ 成功请求: {stats['successful_requests']:,}")
        print(f"❌ 失败请求: {stats['failed_requests']:,}")
        print(f"📈 成功率: {stats['success_rate']:.2f}%")
        print(f"🚀 RPS: {stats['requests_per_second']:.2f}")
        
        print(f"\n⏱️ 响应时间统计 (秒):")
        rt = stats['response_time']
        print(f"  最小值: {rt['min']:.3f}")
        print(f"  最大值: {rt['max']:.3f}")
        print(f"  平均值: {rt['mean']:.3f}")
        print(f"  中位数: {rt['median']:.3f}")
        print(f"  95%分位: {rt['p95']:.3f}")
        print(f"  99%分位: {rt['p99']:.3f}")
        
        print(f"\n📦 响应大小统计 (字节):")
        cl = stats['content_length']
        print(f"  最小值: {cl['min']:,}")
        print(f"  最大值: {cl['max']:,}")
        print(f"  平均值: {cl['mean']:.0f}")
        
        print(f"\n📋 状态码分布:")
        for code, count in sorted(stats['status_codes'].items()):
            percentage = (count / stats['successful_requests']) * 100
            print(f"  {code}: {count:,} ({percentage:.1f}%)")
        
        if self.errors:
            print(f"\n❌ 错误详情 (最近10个):")
            for error in self.errors[-10:]:
                print(f"  请求{error['request_id']}: {error['error']}")
    
    def save_report(self, output_file):
        """保存测试报告"""
        stats = self.calculate_statistics()
        if not stats:
            return
        
        report_data = {
            'test_config': {
                'url': self.url,
                'concurrent': self.concurrent,
                'total_requests': self.total_requests,
                'duration': self.duration,
                'timeout': self.timeout
            },
            'timestamp': datetime.now().isoformat(),
            'statistics': stats,
            'raw_results': self.results[-100:],  # 只保存最后100个结果
            'errors': self.errors[-50:]  # 只保存最后50个错误
        }
        
        with open(output_file, 'w') as f:
            json.dump(report_data, f, indent=2)
        
        print(f"📄 报告已保存到: {output_file}")
    
    async def run(self):
        """运行测试"""
        try:
            if self.duration:
                await self.run_duration_test()
            else:
                await self.run_count_test()
            
            self.print_report()
            
        except KeyboardInterrupt:
            print("\n⏹️ 测试被用户中断")
            self.end_time = time.time()
            if self.results:
                self.print_report()
        except Exception as e:
            print(f"❌ 测试失败: {e}")
            sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='HTTP负载测试脚本')
    parser.add_argument('url', help='测试目标URL')
    parser.add_argument('--concurrent', '-c', type=int, default=10, 
                       help='并发连接数 (默认: 10)')
    parser.add_argument('--requests', '-n', type=int, default=100, 
                       help='总请求数 (默认: 100)')
    parser.add_argument('--duration', '-d', type=int, 
                       help='测试持续时间(秒), 设置后忽略--requests')
    parser.add_argument('--timeout', '-t', type=int, default=30, 
                       help='请求超时时间(秒) (默认: 30)')
    parser.add_argument('--output', '-o', 
                       help='保存报告到文件')
    
    args = parser.parse_args()
    
    # 验证URL
    if not args.url.startswith(('http://', 'https://')):
        args.url = 'http://' + args.url
    
    tester = LoadTester(
        url=args.url,
        concurrent=args.concurrent,
        total_requests=args.requests,
        duration=args.duration,
        timeout=args.timeout
    )
    
    # 运行测试
    asyncio.run(tester.run())
    
    # 保存报告
    if args.output:
        tester.save_report(args.output)

if __name__ == "__main__":
    main()
