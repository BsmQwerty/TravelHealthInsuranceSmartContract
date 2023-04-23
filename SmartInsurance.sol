pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HealthInsurance {

    struct Policy {
        uint256 premium;
        uint256 coverageAmount;
        uint256 startDate;
        uint256 endDate;
        bool active;
    }

    IERC20 public paymentToken;
    address public insurer;
    uint256 public policyCount;

    mapping(address => Policy) public policies;
    mapping(uint256 => address) public policyHolders;

    event PolicyPurchased(address indexed holder, uint256 indexed policyId);
    event PolicyClaimed(address indexed holder, uint256 indexed policyId, uint256 amount);

    modifier onlyInsurer() {
        require(msg.sender == insurer, "Caller is not the insurer");
        _;
    }

    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
        insurer = msg.sender;
    }

    function purchasePolicy(uint256 _premium, uint256 _coverageAmount, uint256 _startDate, uint256 _endDate) external {
        require(_endDate > _startDate, "End date must be after start date");
        require(_coverageAmount > 0, "Coverage amount must be greater than 0");
        require(_premium > 0, "Premium must be greater than 0");
        require(paymentToken.transferFrom(msg.sender, insurer, _premium), "Premium transfer failed");

        policyCount++;
        Policy memory newPolicy = Policy(_premium, _coverageAmount, _startDate, _endDate, true);
        policies[msg.sender] = newPolicy;
        policyHolders[policyCount] = msg.sender;

        emit PolicyPurchased(msg.sender, policyCount);
    }

    function claimInsurance(uint256 _policyId, uint256 _amount) external {
        require(policies[msg.sender].active, "Policy not active");
        require(policies[msg.sender].coverageAmount >= _amount, "Claim amount exceeds coverage");
        require(block.timestamp >= policies[msg.sender].startDate && block.timestamp <= policies[msg.sender].endDate, "Claim is outside policy dates");

        policies[msg.sender].coverageAmount -= _amount;
        paymentToken.transfer(msg.sender, _amount);

        emit PolicyClaimed(msg.sender, _policyId, _amount);
    }

    function cancelPolicy() external {
        require(policies[msg.sender].active, "Policy not active");
        policies[msg.sender].active = false;
    }

    function activatePolicy() external {
        require(!policies[msg.sender].active, "Policy already active");
        policies[msg.sender].active = true;
    }

    function getPolicyDetails(uint256 _policyId) external view returns (Policy memory) {
        return policies[policyHolders[_policyId]];
    }

    function changeInsurer(address _newInsurer) external onlyInsurer {
        insurer = _newInsurer;
    }
}
