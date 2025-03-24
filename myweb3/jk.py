import time
from eth_account import Account
from web3 import Web3, HTTPProvider
from flashbots import flashbot


found = False


# 连接 Sepolia 节点（HTTP Provider）
url = "https://sepolia.drpc.org"
flashbots_signer = Account.from_key(
    "0x16773eea72f7f5b9661cdf05be889dc645ac03160f5d2872bcb31dc17a1ce23b")
# Flashbots测试网中继地址（Goerli/Sepolia使用此地址；主网则用 https://relay.flashbots.net）
FLASHBOTS_RELAY_URL = "https://relay-sepolia.flashbots.net"

w3 = Web3(Web3.HTTPProvider(url))
w = flashbot(w3,flashbots_signer, FLASHBOTS_RELAY_URL)
sender = Account.from_key("")
key = sender.key.hex()
print(sender.address)

if w3.is_connected():
    print("连接成功！")
else:
    print("连接失败！")
    exit()

latest_block = w3.eth.get_block("latest")
base_fee = latest_block["baseFeePerGas"]
max_priority_fee = w3.to_wei(5, "gwei")  # 小费，设置为2 Gwei
max_fee_per_gas = base_fee + max_priority_fee
nonce = w3.eth.get_transaction_count(sender.address)


# 目标合约地址（Checksum 格式）
contract_address = w3.to_checksum_address("0xC61A20067FB2475BCf596317f5Ef06d0dEd078fb")

# 合约 ABI，仅包含 enablePresale 函数
ABI = [
    {
        "inputs": [],
        "name": "enablePresale",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },

    {
        "inputs": [{"internalType": "uint256", "name": "amount", "type": "uint256"}],
        "name": "presale",
        "outputs": [],
        "stateMutability": "payable",  # 注意是 payable
        "type": "function"
    }
]

# 创建合约实例
contract = w3.eth.contract(address=contract_address, abi=ABI)

tx2 = contract.functions.presale(1).build_transaction({
    "chainId": w3.eth.chain_id,
    "from": sender.address,
    "nonce": nonce,
    "maxFeePerGas": max_fee_per_gas,
    "maxPriorityFeePerGas": max_priority_fee,
    "value": w3.to_wei("0.01", "ether"),  # 调用 presale 是 payable 的
})
tx2["gas"] = int(w3.eth.estimate_gas(tx2) * 1.2)
signed_tx = w3.eth.account.sign_transaction(tx2, key)

bundle = [  # 第一笔已经签好名
    {"transaction": tx2, "signer": sender},  # 第二笔还未签名
]

# 9. 发送打包交易到Flashbots，这里只尝试挖下一块(block + 1)
current_block = w3.eth.block_number
send_result = w.flashbots.send_bundle(
    bundle,
    target_block_number=current_block + 1
)

print(send_result)


#拿到tx
print("开始监控 pending 区块中调用 enablePresale 的交易……")
while True:
    try:
        # 获取 pending 区块（包含所有交易详情）
        pending_block = w3.eth.get_block("pending", full_transactions=True)
        if pending_block and pending_block.get("transactions"):
            for tx in pending_block["transactions"]:
                # 跳过没有目标地址的交易
                if not tx.get("to"):
                    continue

                # 判断交易目标是否为指定合约
                if tx["to"].lower() != contract_address.lower():
                    continue

                # 尝试解码交易 input 数据
                try:
                    decoded = contract.decode_function_input(tx["input"])
                except Exception:
                    continue

                func_obj, params = decoded
                # 如果调用的函数名称为 enablePresale，则输出交易信息
                if func_obj.fn_name == "enablePresale":
                    print("检测到 enablePresale 调用！")
                    print("交易哈希:", tx["hash"].hex())
                    print("发送方:", tx["from"])
                    print("input 数据:", tx["input"].hex())
                    print("-" * 40)
                    tx1 = tx
                    print(tx1)
                    # 发送交易
                    # tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
                    # print(tx_hash)
                    found = True  # 设置标志为 True



        else:
            print("当前 pending 区块无交易或数据不可用。")
        if found:
            break  # 跳出 while True 循环
    except Exception as e:
        print("获取 pending 交易时出错:", e)
    time.sleep(5)


