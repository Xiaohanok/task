import hashlib
import time

# 原始数据
data = "肖子涵"

# 开始计时
start_time = time.time()

# 初始化 nonce
nonce = 0

# 循环直到哈希值以 4 个零开始
while True:
    # 拼接数据和当前的 nonce
    combined_data = f"{data}{nonce}"

    # 创建 sha256 对象并计算哈希值
    sha256_hash = hashlib.sha256()
    sha256_hash.update(combined_data.encode('utf-8'))
    hash_value = sha256_hash.hexdigest()

    # 检查哈希值是否以 4 个零开始
    if hash_value.startswith("0000"):
        # 记录花费时间
        end_time = time.time()
        elapsed_time = end_time - start_time

        # 打印结果
        print(f"SHA-256 Hash: {hash_value}")
        print(f"花费时间: {elapsed_time:.6f} 秒")
        break

    # 增加 nonce
    nonce += 1