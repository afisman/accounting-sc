//accounting
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Accounting {
    address public owner;

    struct Transaction {
        uint256 amount;
        address sender;
        address receiver;
        uint256 timestamp;
        string description;
    }

    mapping(address => uint256) public balances;

    Transaction[] public transactions;

    event Deposit(address indexed account, uint256 amount);

    event Withdrawal(address indexed account, uint256 amount);

    event TransactionAdded(
        uint256 indexed id,
        uint256 amount,
        address indexed sender,
        address receiver,
        uint256 timestamp,
        string description
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function deposit() public payable {
        require(msg.value > 0, "Amount must be greater than 0");

        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0.");
        require(amount <= balances[msg.sender], "Insufficient balance.");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function addTransaction(
        address receiver,
        uint256 amount,
        string memory description
    ) public {
        require(amount > 0, "Amount must be greater than 0.");
        require(balances[msg.sender] >= amount, "Insufficient balance.");

        balances[msg.sender] -= amount;
        balances[receiver] += amount;

        transactions.push(
            Transaction(
                amount,
                msg.sender,
                receiver,
                block.timestamp,
                description
            )
        );
        emit TransactionAdded(
            transactions.length - 1,
            amount,
            msg.sender,
            receiver,
            block.timestamp,
            description
        );
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransactionById(
        uint256 id
    ) public view returns (uint256, address, address, uint256, string memory) {
        require(id < transactions.length, "Invalid transaction Id.");

        Transaction memory transaction = transactions[id];

        return (
            transaction.amount,
            transaction.sender,
            transaction.receiver,
            transaction.timestamp,
            transaction.description
        );
    }
}
