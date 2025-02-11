from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP
from Crypto.Random import get_random_bytes
import binascii

# 生成 RSA 公私钥对
key = RSA.generate(2000)
print(key)
private_key = key.export_key()
public_key = key.publickey().export_key()

# 加载公钥和私钥
private_key = RSA.import_key(private_key)
public_key = RSA.import_key(public_key)

# 创建加密器对象（使用公钥）
cipher_rsa = PKCS1_OAEP.new(public_key)

# 创建解密器对象（使用私钥）
decipher_rsa = PKCS1_OAEP.new(private_key)

# 十六进制字符串消息（64 个十六进制字符）
message = "00008539bf02c4f3d31e3e2999790e77b10939458834a55c6eaa82f237e4fb0b"  # 64 位十六进制字符串

# 将十六进制字符串转换为字节
message_bytes = bytes.fromhex(message)

# 加密消息
encrypted_message = cipher_rsa.encrypt(message_bytes)

# 解密消息
decrypted_message = decipher_rsa.decrypt(encrypted_message)

# 将解密后的字节转换回十六进制字符串
decrypted_message_hex = binascii.hexlify(decrypted_message).decode()

print(f"原始消息: {message}")
print(f"加密后的消息: {binascii.hexlify(encrypted_message).decode()}")
print(f"解密后的消息: {decrypted_message_hex}")