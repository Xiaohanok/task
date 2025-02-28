import asyncio
from web3 import AsyncWeb3, WebSocketProvider
from web3.utils.subscriptions import (
    LogsSubscription,
    LogsSubscriptionContext,
)


async def log_handler(
    handler_context: LogsSubscriptionContext,
) -> None:
    log_receipt = handler_context.result

    # 打印交易信息按照指定格式

    print(f"在 {log_receipt['blockNumber']} 区块 0x{log_receipt['blockHash'].hex()} 交易中从 0x{log_receipt['topics'][1].hex()[-40:]} 转账 {int(log_receipt['data'].hex(),16) / 10**6 } USDC 到 {log_receipt['topics'][2].hex()[-40:]}")
async def sub_manager():
    try:

        # -- initialize provider --
        w3 = await AsyncWeb3(WebSocketProvider(f"wss://eth.drpc.org"))


        sub = [
                LogsSubscription(
                    label="USDT transfers",
                    address=w3.to_checksum_address(
                        "0xdac17f958d2ee523a2206206994597c13d831ec7"
                    ),
                    topics=["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"],
                    handler=log_handler,
                )
            ]

        # -- subscribe to event(s) --
        await w3.subscription_manager.subscribe(sub)
        await w3.subscription_manager.handle_subscriptions()
    except Exception   as e:
        print(e)



asyncio.run(sub_manager())