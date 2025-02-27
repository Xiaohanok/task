from web3 import Web3



# 连接到 Ethereum 节点
url = "https://eth.llamarpc.com"
web3 = Web3(Web3.HTTPProvider(url))

usdc_abi = [
    {
        "anonymous": False,
        "inputs": [
            {
                "indexed": True,
                "name": "from",
                "type": "address"
            },
            {
                "indexed": True,
                "name": "to",
                "type": "address"
            },
            {
                "indexed": False,
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "Transfer",
        "type": "event"
    }
]
usdc_address = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"

# 获取 USDC 合约实例
usdc_contract = web3.eth.contract(address=usdc_address, abi=usdc_abi)

block_number = web3.eth.get_block_number()

logs = usdc_contract.events.Transfer().get_logs(
    from_block=block_number -100,
    to_block=block_number,
)


for i in logs:
    from_address = i['args']['from']
    to_address = i['args']['to']
    value = i['args']['value'] / 10**6
    print(f"address,{from_address}, to:{to_address}, value:{value}USDC, hash:{i['transactionHash'].hex()}")




