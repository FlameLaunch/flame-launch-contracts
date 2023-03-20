import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-deploy";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ]
  },
  paths: {
    artifacts: "artifacts",
    cache: "cache",
    deploy: "deploy",
    deployments: "deployments",
    imports: "imports",
    sources: process.env.CONTRACTS_PATH || "contracts",
    tests: "test",
  },
  networks: {
    hardhat: {
      accounts: {
        accountsBalance: "200000000000000000000001",
      },
      allowUnlimitedContractSize: true,
      saveDeployments: true,
      tags: ["FlameToken"],
    },
    tfil: {
      url: process.env.TFIL_URL || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY.split(",") : [],
      saveDeployments: true,
      tags: ["FlameToken"],
    }, 
    fil: {
      url: process.env.FIL_URL || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY.split(",") : [],
      saveDeployments: true,
      tags: ["FlameToken"],
    },
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
    },
    rinkby: {
      url: process.env.RINKBY_URL || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY.split(",") : [],
    },
    goerli: {
      url: process.env.GOERLI_URL || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY.split(",") : [],
    },
    tbsc: {
      url: process.env.TBSC_URL || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY.split(",") : [],
    },
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY!,
      rinkeby: process.env.ETHERSCAN_API_KEY!,
      mainnet: process.env.ETHERSCAN_API_KEY!,
      bsc: process.env.BSCSCAN_API_KEY!,
      bscTestnet: process.env.BSCSCAN_API_KEY!
    }
  },
};

export default config;
