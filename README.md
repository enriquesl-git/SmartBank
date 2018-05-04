# Smart Bank
**Another way of keeping and managing your Ethers.**

Testing: https://ropsten.etherscan.io/address/0x5e5605758ff207d34a1ea26e22259c9c41e9e752


## A simple automated online bank of Ethers

The intention of this system is that **you can use your Ethers without easy 
trace of transactions**, also avoiding others to easily see your balance on 
block explorers. (It is yet possible anyway, because data on smart contracts 
is public, as well as the functions called and the value of its arguments.) 

The way it works is that all the Ethers of accounts is inside the contract, 
which keep accounting of the balance of each account. Then, internal 
transfers are just increasing one account while decreasing the other, with 
no loses. **It is even possible to do operations without Ether in your 
address**, because gas is charged to your internal account (contract sends 
you the neccessary ETH to cover the operation gas cost). 

Thus you can use this Smart Bank system as an Ether online wallet, i. e., 
another way of keeping and managing your Ethers. **The state machine of 
Ethereum keeps balances of accounts instead of the history of transactions**. 
Doing internal transactions between accounts is the best way to avoid 
keeping trace of your activity, maximizing your privacy. 

You can deposit ETH to the contract, which keeps account of what is yours. 
Then you can transfer any amount of your account balance to another account. 
Or you can send ETH from your account, that is, the contract will send 
the ETH, not you, and they will be discounted from your account. 
You can also send ETH to another account. Or you can even send ETH to ETH, 
from address to address, going through the contract but without modifying 
account balances, just resending the ETH received to another address. 
In that case the Smart Bank acts just as a mixer, breaking the trace of the 
Ethers in the Ethereum blockchain.

As an added interesting authomated service, **you can trust another account 
to take all your balance in case that you can't operate, like in the case 
that you die, or if you lose the private key** of your account address. 


### pros: 
- history of transactions is lost, no events either
- balances of addresses are not watched in block explorers
- someone you trust can retrieve your balance (if you die, or ...)

### cons:
- not for places which may need a payback (ICO, exchange, ...)
- not allowed sending to contract addresses

## Operations: 
- `myBalance()`:                 get your account balance 
- `deposit` (fallback function): from your ETH to your account 
- `transfer(account, amount)`:   from your account      to other account
- `transfer(account)`:           from your ETH address  to other account 
- `pay(address, amount)`:        from your account      to other ETH address
- `pay(address)`:                from your ETH address  to other ETH address 

- `entrust(account)`: set backup account, which can retrieve your balance
    (to remove backup, just set to 0x0, or to a new address)
- `reclaim(account)`: rescue the balance of backed up account to your account, 
    and delete the backed up account
- `reclaim()`: rescue all your balance to your ETH address, 
    and delete your account
