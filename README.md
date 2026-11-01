> [!CAUTION]
> This is experimental and simply proof-of-concept, has not been tested. Discouraged from any form of use.
# Boba
Something to make with your "tea".

A roblox networking package, courtesy to [Sencha](https://github.com/JDevon/sencha), that enforces a "Bring your own typechecker" ideology. Works best with a typechecker that is able to cast their underlying type.

### Best used with:
- [GreenTea](https://github.com/Corecii/GreenTea)
- [Boba](https://github.com/welcomestohell/boba) (Swear I didn't mean to copy, only found out after making this)

### Can work with:
- [t](https://github.com/osyrisrblx/t)
- [Guard](https://util.redblox.dev/guard.html)

## Usage
> [!NOTE]
> [GreenTea](https://github.com/Corecii/GreenTea) will be use as the typechecker example.

### Define
Define Boba's parent storage and resolver
```luau
-- src/shared/Network.luau
local Boba = require(path.to.Boba)
local gt = require(path.to.GreenTea)

return Boba.define(script, function(checker: gt.Type, value: any): (boolean, string?)
    local ok, cause = checker:matches(value)
    if not ok then
        return false, cause:formatErr()
    end

    return true
end)
```

### Remotes
```luau
-- src/shared/ShopNetwork.luau
local Network = require(script.Parent.Network)
local gt = require(path.to.GreenTea)

return {
    -- RemoteFunction                                   Arguments                 Returns
    buyItemFunc = Network.remoteFunction("BuyItemFunc")(gt.string(), gt.number())(gt.boolean(), gt.optional(gt.string()))
    -- RemoteEvent                                       Arguments
    sellItemEvent = Network.remoteEvent("SellItemEvent")(gt.string(), gt.optional(gt.number()))
}
```
```luau
-- src/server/ShopServer.server.luau
local ShopNetwork = require(path.to.shared.ShopNetwork)

ShopNetwork.buyItemFunc:SetServerInvoke(function(player, itemName, quantity)
    quantity = math.clamp(quantity or 1, 1, 999)
    local canBuy = false

    -- Some logic

    if canBuy then
        return true
    else
        return false, `Cannot buy {quantity} {if quantity == 1 then itemName .. "s" else itemName}`
    end
end)

ShopNetwork.sellItemEvent.OnServerEvent:Connect(function(player, itemName, quantity)
    -- Some logic
end)
```
```luau
-- src/client/ShopClient.client.luau
local ShopNetwork = require(path.to.shared.ShopNetwork)
local Players = game:GetService("Players")

local playerGui = Players.LocalPlayer.PlayerGui

local buyButton = playerGui.to.BuyButton :: TextButton
local buyItem = playerGui.to.BuyItem :: TextLabel
local buyQuantity = playerGui.to.BuyQuantity :: TextLabel
buyButton.Activated:Connect(function()
    local buySuccess, reason = ShopNetwork.buyItemFunc:InvokeServer(buyItem.Text, tonumber(buyQuantity.Text))
    if not buySucess then
        print(reason)
    end
end)

local sellButton = playerGui.to.SellButton :: TextButton
local sellItem = playerGui.to.SellItem :: TextLabel
local sellQuantity = playerGui.to.SellQuantity :: TextLabel
sellButton.Activated:Connect(function()
    ShopNetwork.sellItemEvent:FireServer(sellItem.Text, tonumber(sellQuantity.Text))
end)
```

### Replicators
> [!WARNING]
> Type checking hasn't been implemented for replicators, anything passed will be accepted.
```luau
-- src/shared/CurrencyNetwork.luau
local Network = require(script.Parent.Network)
local gt = require(path.to.GreenTea)

return {
    -- PlayerReplicator (each player holds a seperate value)
    playerMoneyReplicator = Network.playerReplicator("PlayerMoneyReplicator")(gt.number(), 0)
    -- GlobalReplicator (server holds one value)
    bankTotalMoneyReplicator = Network.globalReplicator("BankTotalMoneyReplicator")(gt.number(), 1000)
}
```
```luau
-- src/server/CurrencyServer.luau
local ShopNetwork = require(path.to.shared.CurrencyNetwork)

local CurrencyServer = {}

function CurrencyServer.playerTakeFromBank(player: Player, amount: number)
    local bankCurrentAmount = CurrencyNetwork.bankTotalMoneyRepliator:get()
    if bankCurrentAmount <= 0 then
        return
    end

    local fixedAmount = math.clamp(amount, 0, bankCurrentAmount)
    CurrencyNetwork.bankTotalMoneyRepliator:set(bankCurrentAmount + fixedAmount)
    local playerCurrentAmount = CurrencyNetwork.playerMoneyReplicator:get(player)
    CurrencyNetwork.playerMoneyReplicator:set(player, playerCurrentAmount + fixedAmount)
end

return CurrencyServer
```
```luau
-- src/client/CurrencyClient.client.luau
local ShopNetwork = require(path.to.shared.CurrencyNetwork)
local Players = game:GetService("Players")

local playerGui = Players.LocalPlayer.PlayerGui

local moneyLabel = playerGui.to.MoneyLabel :: TextLabel
CurrencyNetwork.playerMoneyReplicator:observe(function(newAmount)
    moneyLabel.Text = "$" .. tostring(newAmount)
end)

local bankMoneyLabel = playerGui.to.BankMoneyLabel :: TextLabel
CurrencyNetwork.bankTotalMoneyReplicator:observe(function(newAmount)
    bankMoneyLabel = "Global Bank: $" .. tostring(newAmount)
end)
```
### Predictions
```luau
-- src/client/ShopClient.client.luau
local ShopNetwork = require(path.to.shared.ShopNetwork)
local CurrencyNetwork = require(path.to.shared.CurrencyNetwork)
local Players = game:GetService("Players")

local playerGui = Players.LocalPlayer.PlayerGui

local buyButton = playerGui.to.BuyButton :: TextButton
local buyItem = playerGui.to.BuyItem :: TextLabel
local buyQuantity = playerGui.to.BuyQuantity :: TextLabel
buyButton.Activated:Connect(function()
    local price = 0
    -- Logic to get price
    local buyPredictionServerInvoke = ShopNetwork.buyItemFunc:PredictionServerInvoker({
        CurrencyNetwork.playerMoneyReplicator:predictUpdate(function(money)
            return money - price
        end)
    })

    local buySuccess, reason = buyPredictionServerInvoke(buyItem.Text, tonumber(buyQuantity.Text))
    if not buySucess then
        print(reason)
    end
end)

```
## Limitations
- Remotes does not support vararg (`...: T`) as some typecheckers supports it while some don't. Your best bet (and probably better practice) is passing an array of a type at the end. i.e
```luau
local someEvent = Network.remoteEvent("SomeEvent")(gt.string(), gt.array(gt.number()))
```
