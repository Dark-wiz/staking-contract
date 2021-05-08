require("@nomiclabs/hardhat-waffle");

const INFURA_URL = 'https://rinkeby.infura.io/v3/1d0ca15cd23f45d392029341b9c812b3';
const PRIVATE_KEY = 'ec352da5e11a687ec5d31f8514a54a8e17a3e37990a1c747b438b6ba42379edd';

module.exports = {
  solidity: "0.6.6",
  networks: {
    rinkeby: {
      url: INFURA_URL,
      accounts: [`0x${PRIVATE_KEY}`]
    }
  }
};

