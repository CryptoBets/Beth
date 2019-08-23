&nbsp; &nbsp; ![EthBet](images/bethlogo.png) <br/>
# Place your beths!
* **Win ethereum**
* **Get the best odds on the internet**
* **No registration needed**

[![Metamask](images/metamask.png)](https://metamask.io)
[![Discord](images/discord.png)](https://discordapp.com) &nbsp; &nbsp;
[![Github](images/github.png)](https://github.com/CryptoBets/EthBet)
* **Metamask** - your gateway to Web 3.0. You have to install Metamask to interact with our website.
* **Discord** - give us feedback and suggest the matches.
* **Github** - check out the [contract](ethbet.sol) and docs.

## Read first:
 #### 1) How it works
 &nbsp; &nbsp; This contract allows its users to bet against themselves.
 For example consider tennis match where both players (A and B) have equal chances.
 It means that the sum of bets should be equal for both players.
 Odds of player A are calculated based on following formula:
 ```all funds in contract / funds betting on player A```. <br/>
 This means that in this case both players has odds `2:1`. 
 Even the biggest betting office can not give you such a good odds because they need to stay safely in profit.
 Usually you get `1.8:1` when there are equal chances for both players. <br/>
 &nbsp; &nbsp; We are updating odds on our website every **5 min** but winners are payed by odds in the time of contract closure.
 That is usually **few hours before match time**. 
 When the match is closed you can not make bet or discard your bet anymore.
 
 #### 2) Fees
 * **0 %** when the match is canceled <br/>
 * **1.5 %** when the win is claimed manually by user
 * **2.5 %** when the bet is discarded or the win payed out automatically
 
 &nbsp; &nbsp; Fees are used to pay the gas necessary for running the contracts.
 Match is canceled when there is no winning or loosing bet or the match is canceled in real world. 
 Users have **three days after match time** to claim their win manually.
 After this period the automatic payout is triggered and the contract which belongs to match is destroyed.
 
 #### 3) Warning
 &nbsp; &nbsp; You can not bet on multiple results in one match from one address. All funds from previous bet will be reallocated to the new bet.
 We have **no access** to your funds, everything is stored on Ethereum blockchain.
 There is minimal bet, which is currently set to **10 finney** (0.01 ETH).
 We advise to set the bet size proportionally to the sum of funds in whole match, otherwise you can change the odds drastically.
 
 
