from web3 import Web3

# 连接到以太坊节点
url = "https://eth.llamarpc.com"
web3 = Web3(Web3.HTTPProvider(url))

# 检查是否成功连接
if web3.is_connected():
    print("成功连接到以太坊节点")
else:
    print("无法连接到以太坊节点")

# 合约地址
contract_address = "0x0483B0DFc6c78062B9E999A82ffb795925381415"

# 合约 ABI（此处仅包含需要用到的部分 ABI）
abi = [
    {
        "inputs": [{"internalType": "uint256", "name": "tokenId", "type": "uint256"}],
        "name": "ownerOf",
        "outputs": [{"internalType": "address", "name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "uint256", "name": "tokenId", "type": "uint256"}],
        "name": "tokenURI",
        "outputs": [{"internalType": "string", "name": "", "type": "string"}],
        "stateMutability": "view",
        "type": "function"
    }
]

# 创建合约对象
contract = web3.eth.contract(address=contract_address, abi=abi)

# 读取 NFT 合约中的持有者地址
def get_owner_of(token_id):
    try:
        owner = contract.functions.ownerOf(token_id).call()
        return owner
    except Exception as e:
        print(f"读取持有者地址失败: {e}")
        return None

# 读取 NFT 合约中的元数据
def get_token_metadata(token_id):
    try:
        token_uri = contract.functions.tokenURI(token_id).call()
        return token_uri
    except Exception as e:
        print(f"读取元数据失败: {e}")
        return None

# 示例: 读取 tokenId 为 1 的 NFT 的持有者和元数据
token_id = 1
owner_address = get_owner_of(token_id)
if owner_address:
    print(f"Token ID {token_id} 的持有者地址为: {owner_address}")

token_metadata = get_token_metadata(token_id)
if token_metadata:
    print(f"Token ID {token_id} 的元数据 URI 为: {token_metadata}")