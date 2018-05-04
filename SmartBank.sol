pragma solidity ^0.4.23;

/** Smart Bank: a simple automated online bank of Ethers. 

    The intention of this system is that you can use your Ethers without easy 
    trace of transactions, also avoiding others to easily see your balance on 
    block explorers. (It is yet possible anyway, because data on smart contracts 
    is public, as well as the functions called and the value of its arguments.) 

    The way it works is that all the Ethers of accounts is inside the contract, 
    which keep accounting of the balance of each account. Then, internal 
    transfers are just increasing one account while decreasing the other, with 
    no loses. It is even possible to do operations without Ether in your 
    address, because gas is charged to your internal account (contract sends 
    you the neccessary ETH to cover the operation gas cost). 

    Thus you can use this Smart Bank system as an Ether online wallet, i. e., 
    another way of keeping and managing your Ethers. The state machine of 
    Ethereum keeps balances of accounts instead of the history of transactions. 
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

    As an added interesting authomated service, you can trust another account 
    to take all your balance in case that you can't operate, like in the case 
    that you die, or if you lose the private key of your account address. 


pros: 
- history of transactions is lost, no events either
- balances of addresses are not watched in block explorers
- someone you trust can retrieve your balance (if you die, or ...)

cons:
- not for places which may need a payback (ICO, exchange, ...)
- not allowed sending to contract addresses
*/


/** @title Basic bank of Ethers. 

Operations: 
- deposit (fallback function): from ETH to your account 
- myBalance(): get your account balance 
- transfer(account, amount) from your account      to other account
- transfer(account):        from your ETH address  to other account 
- pay(address, amount):     from your account      to other ETH address
- pay(address)              from your ETH address  to other ETH address 

- entrust(account): set backup account, which can retrieve your balance
    (to remove backup, just set to 0x0, or to a new address)
- reclaim(account): rescue the balance of backed up account to your account, 
    and delete the backed up account
- reclaim(): rescue all your balance to your ETH address, 
    and delete your account

*/
contract SmartBank {

    /** Balances of accounts. An account is just an address with balance */
    mapping (address => uint) accountBalance;

    /* Trusted accounts, to rescue your account if needed */
    mapping (address => address) trustedAccount;

    /* Know your own balance 
    gas cost: 21272(overhead) + 601(execution) */
    function myBalance() view external returns (uint) {
        return accountBalance[msg.sender];
    }

    /** The Ether that you send to this contract is deposited to your account */
    function () payable external {
        deposit();
    }

    /** from ETH to your account, 
    you do a deposit to your own account 
    gas cost: 21272(overhead) + 5609(execution) [+ 15000(first time)] */
    function deposit() payable public {
        transfer(msg.sender);
    }

    /** from your ETH address to any account, 
    you do a deposit to somebody else,
    gas cost: 21272(overhead) + 5581(execution) = 28261 */
    function transfer(address account) payable public {
        uint amount = msg.value;  // to read state only once
        require (amount > 0);  // to save gas of assigning a state variable

        accountBalance[account] += amount;
    }

    /** from your ETH address to any ETH address, 
    your Ethers are received by contract, and resent to somebody, 
    neither account is needed, nor created. 
    Destination can not be a contract, to avoid attacks or other problems. 
    gas cost: 21272(overhead) + 8531(execution) + 22*64  = 31211 */
    function pay(address somebody) notContract(somebody) payable external {
        uint amount = msg.value;  // to read state only once
        require (amount > 0);  // to save gas of transfer

        somebody.transfer(amount);
    }

    /** from your account to any account, 
    internal transfer. WARNING: gas cost is charged to this contract. 
    gas cost: 21272(overhead) + 33725(execution) + 22*64 = 56917 */
    function transfer(address account, uint amount) external {
        require (amount > 0);  // to save gas of assigning a state variable

        senderAccounting(0, amount, 56917);
        accountBalance[account] += amount;
    }

    /** from your account to any ETH address, 
    external send, Ethers are sent from contract to somebody, 
    substracting from the internal account balance. 
    Destination can not be a contract, to avoid attacks or other problems. 
    WARNING: gas cost is charged to this contract. 
    gas cost: 21272(overhead) + 21653(execution) + ~31*64  = 44909 */
    function pay(address somebody, uint amount) notContract(somebody) external {
        require (amount > 0);  // to save gas of transfer

        senderAccounting(0, amount, 44845);
        somebody.transfer(amount);  // it doesn't fullfill the withdraw pattern
    }

    /** rescue all the balance of the account who trusted on you, 
    gas cost will be repercuted to the sum of balances 
    gas cost: 21272(overhead) + 18967(execution) + 22*64 - 15000(delete) = 26647 */
    function reclaim(address deadAccount) external {
        require (msg.sender == trustedAccount[deadAccount]);

        senderAccounting(accountBalance[deadAccount], 0, 26647);
        delete(accountBalance[deadAccount]);  // set balance to zero
        delete(trustedAccount[deadAccount]);
    }

    /** rescue all the balance of your account to your ETH address 
    gas cost: 21272(overhead) + (execution) + *64 - 15000(delete) =  */
    function reclaim() external {
        address me = msg.sender;
        require (accountBalance[me] > 0);

        me.transfer(accountBalance[me]);
        delete(accountBalance[me]);  // set balance to zero
        delete(trustedAccount[me]);
    }

    /** set surrogate account, as a backup, who can retrieve all the balance 
    gas cost: 21272(overhead) + 20619(execution) + 22*64 = 43299 */
    function entrust(address friendAccount) external {
        trustedAccount[msg.sender] = friendAccount;
    }

    /** accounting on the sender side, to be used by other functions here. 
    msg.sender can be a contract address, so it is needed to use tx.origin */
    function senderAccounting(uint amountAdd, uint amountSub, uint txGas) private {
        txGas *= tx.gasprice;
        amountSub += txGas;
        amountAdd += accountBalance[msg.sender];

        require (amountSub <= amountAdd);
        accountBalance[msg.sender] = amountAdd - amountSub;

        // Refund gas cost
        tx.origin.transfer(txGas);
    }

    /** Taken from ERC223, modified to modifier. 
    If bytecode exists then the _addr is a contract, and is rejected. */
    modifier notContract(address _addr) {
        uint codeLength;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            codeLength := extcodesize(_addr)
        }
        require (codeLength == 0);
        require (_addr != address(0x0));  // It is a 
        _;
    }

}
