import asyncio
from web3 import AsyncWeb3, WebSocketProvider
from web3.utils.subscriptions import (
    NewHeadsSubscription,
    NewHeadsSubscriptionContext,
)

# -- declare handlers --
async def new_heads_handler(
    handler_context: NewHeadsSubscriptionContext,
) -> None:
    header = handler_context.result
    print(f"区块高度: {int(header['number'],16)} 区块哈希：{header['hash']}\n")


async def sub_manager():
    try:

        # -- initialize provider --
        w3 = await AsyncWeb3(WebSocketProvider(f"wss://eth.drpc.org"))


        sub = [
                NewHeadsSubscription(
                    label="newheads",
                    handler=new_heads_handler
                )
            ]

        # -- subscribe to event(s) --
        await w3.subscription_manager.subscribe(sub)
        await w3.subscription_manager.handle_subscriptions()
    except Exception   as e:
        print(e)



asyncio.run(sub_manager())
