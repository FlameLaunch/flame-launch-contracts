import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { formatEther, signer } from "../hardhat.define";
import { FlameAirdrop, FlameStake, FlameToken, TestWrappedAvailableToken } from "../typechain-types";
// deploy/00_deploy_my_contract.js
module.exports = async ({ deployments }) => {
    let signers = await ethers.getSigners()
    let deployer = signers[0]
    console.log('deployer:',deployer.address,' ',formatEther(await deployer.getBalance(),'ether',true))
    const getDeployment = async (name: string, args?:any[])=> {
        try {
            let ctt = await deployments.get(name)
            let myctt = await ethers.getContractFactory(name)
            console.log(name,'@',ctt.address)
            return myctt.attach(ctt.address)
        } catch {
            const ctt = await deployments.deploy(name,{ 
                from: deployer.address,
                args,
                log:true,
            })
            await deployments.save(name,ctt)
            return await getDeployment(name)
        }
    }

    let ctt = await getDeployment('FlameToken') as FlameToken
    await getDeployment('TestWrappedAvailableToken', [ctt.address, "FLT Wrapped Available","FLTAvail"]) as TestWrappedAvailableToken
    await getDeployment('FlameAirdrop', [ctt.address]) as FlameAirdrop
    await getDeployment('FlameStake') as FlameStake
};
module.exports.tags = ['FlameToken'];