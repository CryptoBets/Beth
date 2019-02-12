pragma solidity ^0.5.3;

contract Match {

    struct Bet{
        uint value;
        uint8 option;
    }

    // Important addresses
    address payable private owner;
    address payable private admin;

    // Public vars
    address payable[] public bettors;        // holds all adresses
    mapping (address => Bet) public bets;    // maps adress to value and choice
    uint[] public bets_sum;
    uint32 public match_id;
    uint public match_time;
    uint public closing_time;
    int8 public result;
    uint8 public options_num;
    bool public canceled;
    string public description;
    uint32 public dev_fee;
    uint public min_bet;

    // Consts
    uint32 constant hour = 60*60;

    // Match constructor - this contract contains all bets which belongs to certain match
    constructor(uint32 _match_id, address payable _admin, uint _match_time, uint8 _options_num,
        string memory _description, uint32 _dev_fee, uint _min_bet) public {
        owner = msg.sender;         // owning contract
        admin = _admin;             // set admin to prevent owning contract failure
        match_id = _match_id;
        match_time = _match_time;   // match start time
        closing_time = match_time - 3*hour;
        canceled = false;
        result = -1;                // -1 unknown ... the rest corresponds to option
        options_num = _options_num; // possible match results
        bets_sum = new uint[](options_num);
        description = _description;
        dev_fee = _dev_fee;
        min_bet = _min_bet;
    }

    // ------------ USER FUNCTIONS -------------

    function bet(uint8 option) external payable {
        require(now < closing_time && !canceled, "bet cannot be made now");
        require(option >= 0 && option < options_num, "impossible option");
        require(msg.value >= min_bet, "too low bet");

        uint funds = msg.value*dev_fee/1000;          // dev fee
        if (bets[msg.sender].value == 0){
            bets[msg.sender].value = funds;
            bets[msg.sender].option = option;
            bets_sum[option] += funds;
            bettors.push(msg.sender);
        } else {
            bets_sum[bets[msg.sender].option] -= bets[msg.sender].value;
            bets[msg.sender].value += funds;
            bets[msg.sender].option = option;
            bets_sum[option] += bets[msg.sender].value;
        }
    }

    function withdraw_funds() external {
        // you can withraw funds from match which did not start yet or has been canceled
        require(now < closing_time || canceled, "funds cannot be withdrawn");

        uint return_value;
        if (canceled){
            return_value = bets[msg.sender].value*1000/dev_fee;  // return dev fee
        } else {
            return_value = bets[msg.sender].value;
        }
        bets_sum[bets[msg.sender].option] -= bets[msg.sender].value;
        bets[msg.sender].value = 0;
        msg.sender.transfer(return_value);
    }

    function claim_win() external {
        require(result >= 0 && !canceled, "match is not finished");
        require(uint8(result) == bets[msg.sender].option, "you are not a winner");
        require(bets[msg.sender].value > 0, "your funds has been already withdrawn");

        uint winned_sum = 0;
        // return some fee thanks to user making the withdrawal
        uint winner_fraction = bets_sum[uint(result)]/(bets[msg.sender].value*(dev_fee+10)/dev_fee);
        for (uint8 i = 0; i < options_num; i++){
            if (i != uint8(result)) {
                uint option_win = bets_sum[i]/winner_fraction;
                winned_sum += option_win;
                bets_sum[i] -= option_win;
            }
        }
        winned_sum += bets[msg.sender].value;
        bets_sum[uint(result)] -= bets[msg.sender].value;
        bets[msg.sender].value = 0;
        msg.sender.transfer(winned_sum);
    }

    // ------------ ADMIN FUNCTIONS ------------

    // GETTERS

    function get_bettors() external view returns(address payable[] memory) {
        return bettors;
    }

    function get_address_bet(address addr) external view returns(uint) {
        return bets[addr].value;
    }

    function get_address_option(address addr) external view returns(int16) {
        if (bets[addr].value > 0) {
            return bets[addr].option;
        } else {
            return -1;
        }
    }

    function bets_sums() public view returns(uint) {
        uint sum;
        for (uint8 i = 0; i < options_num; i++) {
            sum += bets_sum[i];
        }
        return sum;
    }

    // SETTERS

    function set_result(uint8 _result) external {
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");
        require(_result >= 0 && _result < options_num, "impossible result");
        require(match_time + hour < now, "match is not finished yet");
        require(!canceled, "match was canceled");
        require(bets_sum[_result] > 0 && bets_sum[_result] < bets_sums());

        result = int8(_result);
    }

    function cancel_match() external {
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");
        require(result < 0, "match has already result");

        canceled = true;
    }

    // CROWD CONTROL

    function return_funds(address payable recipient) public {
        // in case of canceling the match, this method return funds of certain address
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");
        require(canceled, "match is not canceled, funds cannot be returned");

        uint return_value = bets[recipient].value*1000/dev_fee;   // return dev_fee
        bets_sum[bets[recipient].option] -= bets[recipient].value;
        bets[recipient].value = 0;
        recipient.transfer(return_value);
    }

    function payout(address payable winner) external {
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");
        require(result >= 0 && !canceled, "match is not finished");
        require(uint8(result) == bets[winner].option, "you are not a winner");
        require(bets[winner].value > 0, "your funds has been already withdrawn");

        uint winned_sum = 0;
        uint winner_fraction = bets_sum[uint8(result)]/bets[winner].value;
        for (uint8 i = 0; i < options_num; i++){
            if (i != uint8(result)) {
                uint option_win = bets_sum[i]/winner_fraction;
                winned_sum += option_win;
                bets_sum[i] -= option_win;
            }
        }
        winned_sum += bets[winner].value;
        bets_sum[uint8(result)] -= bets[winner].value;
        bets[winner].value = 0;
        winner.transfer(winned_sum);
    }

    function close_contract() external {
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");
        require(now > match_time + hour*24*7 || bets_sums() == 0, "match cannot be closed yet");

        selfdestruct(admin);
    }
}

contract EthBet {
    address payable private admin;
    mapping (uint32 => Match) public matches;
    uint32 public last_match_id;
    uint32 public dev_fee;
    uint public min_bet;

    // Parent contract constructor
    constructor() public {
        admin = msg.sender;
        last_match_id = 0;
        dev_fee = 975;
        min_bet = 10 finney;
    }

    // method for initialisation of match, match_time is in UTC unix time in sec
    function init_match(uint match_time, uint8 options_num, string calldata description) external {
        require(msg.sender == admin, "only owner can call this");
        require(options_num > 1, "every match must have at least two stacks");

        last_match_id++;
        matches[last_match_id] = new Match(last_match_id, admin, match_time, options_num,
            description, dev_fee, min_bet);
    }

    // SETTERS
    function set_dev_fee(uint32 _dev_fee) external {
        require(msg.sender == admin, "only owner can call this");
        require(_dev_fee > 500 && dev_fee < 1000, "should be in mille");

        dev_fee = _dev_fee;
    }

    function set_min_bet(uint _min_bet) external {
        require(msg.sender == admin, "only owner can call this");
        require(_min_bet > 1 finney, "this would be very small bet");

        min_bet = _min_bet;
    }

    // GETTERS
    function get_match_address(uint32 _id) external view returns(address) {
        return address(matches[_id]);
    }

    // DESTROY CONTRACTS
    function close_match(uint32 _id) external{
        require(msg.sender == admin, "only owner can call this");

        matches[_id].close_contract();
    }

    function close_contract() external {
        require(msg.sender == admin, "only owner can call this");

        selfdestruct(admin);
    }
}