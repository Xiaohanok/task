from web3 import Web3

# RPC URL
RPC_URL = "https://eth-sepolia.public.blastapi.io"
CONTRACT_ADDRESS = Web3.to_checksum_address("0x3Cf6666FC6FAcc6036322E587b3e5CB9f5963BE5")

# 连接到 RPC 节点
web3 = Web3(Web3.HTTPProvider(RPC_URL))
if not web3.is_connected():
    print("无法连接到 Ethereum Sepolia 测试网")
    exit()

# 计算 Keccak256 哈希
def keccak256(value: int) -> int:
    value_bytes = value.to_bytes(32, "big")
    return int.from_bytes(Web3.keccak(value_bytes), "big")

# 读取合约存储槽数据
def eth_getStorageAt(slot):

    return web3.eth.get_storage_at(CONTRACT_ADDRESS, slot)

# 获取 _locks 数组的长度（slot 0 存储的是数组长度）

locks_length = int.from_bytes(eth_getStorageAt(0), "big")
print(f"Locks length: {locks_length}")

# 计算 `_locks` 数组起始位置（Keccak256(slot 0)）
array_start_slot = keccak256(0)

# 遍历并读取 `_locks[i]`
for i in range(locks_length):
    # 计算 _locks[i] 的存储位置（keccak256(array_start_slot + i)）
    element_slot = array_start_slot
    amount_slot = element_slot + 1

    # 读取 `user + startTime`
    data = eth_getStorageAt(element_slot)
    user = "0x" + data[12:32].hex()  # 取后 20 字节的地址
    startTime = int.from_bytes(data[4:12], "big")  # 取最后 8 字节的时间戳

    # 读取 `amount`
    amount = int.from_bytes(eth_getStorageAt(amount_slot), "big")

    print(f"Lock {i}: user={user}, startTime={startTime}, amount={amount}")
    array_start_slot = array_start_slot + 2
