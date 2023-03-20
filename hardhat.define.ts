import "./hardhat.config"
import { ethers, network } from "hardhat";

import { BigNumberish, BigNumber } from "ethers";
export const Wei = ethers.BigNumber.from(1)
export const GWei = ethers.BigNumber.from(1e9)
export const Eth = ethers.BigNumber.from(1e9).mul(1e9)
export const formatEther = (wei: BigNumberish, to: "wei" | "gwei" | "ether" = "ether", signed?: boolean) => {
    if (signed) return " " + ethers.utils.formatUnits(wei, to) + " " + to + " "
    else return ethers.utils.formatUnits(wei, to)
}
export const delta = (a: BigNumberish, b: BigNumberish) => {
    let delta = ethers.BigNumber.from(a).sub(ethers.BigNumber.from(b)).abs()
    return delta
}
export const signer = async (acc: 'owner' | 'buyer' | number |string) => {
    const signers = await ethers.getSigners()
    if(acc)
    switch (acc) {
        case 'owner': return signers[0];
        case 'buyer': return signers[1];
        default: return signers[acc];
    }
}
export const exeTxAndWait = async (call: Promise<any>, confirm = 0) => {
    return call.then(async (tx) => {
        return await tx.wait(confirm)
    })
}
export const getToken = async (address?: string) => {
    const TestFlameTokenFactory = await ethers.getContractFactory("TestFlameToken");
    if (address) {
        return await TestFlameTokenFactory.attach(address)
    } else {
        const signers = await ethers.getSigners()
        let token = await TestFlameTokenFactory.connect(signers[0]).deploy()
        return await token.deployed()
    }
}

export const foreach = async<T>(args0: T[], call: (arg: T) => any) => {
    for(let i=0; i<args0.length; i++) {
        call(args0[i])
    }
}

export const getBlockTime = async () => {
    let block = await ethers.provider.getBlock('latest')
    return new Date(block.timestamp*1000)
}

export const localNet = {
    setBalance: (account: string, amount: BigNumberish) => {
        return network.provider.send("hardhat_setBalance", [account, ethers.BigNumber.from(amount)._hex.replace(/0x0+/, "0x")]);
    },
    increaseTime: async (time: number, unit: "weeks" | "days" | "seconds" | "hours" | "minutes" = "seconds",now?,automint=true) => {
        if (unit != "seconds") {
            time *= 60
            if (unit != "minutes") {
                time *= 60
                if (unit != "hours") {
                    time *= 24
                    if (unit != "days") time *= 7
                }
            } 
        }
        let seconds = Math.floor(time)
        if(now) { 
            seconds = Math.floor(time + now / 1000 - (await ethers.provider.getBlock('latest')).timestamp)
        }
        await network.provider.send("evm_increaseTime", [seconds])
        if(automint) await network.provider.send("hardhat_mine", ["0x1"]);
    },
    setTimestamp: async (time: number) => {
        await network.provider.send("evm_increaseTime", [Math.floor(time)])
        await network.provider.send("hardhat_mine", ["0x1"]);
    },
    mine: () => {
        return network.provider.send("evm_mine")
    }
}

export const Etherscan = {
    verify: async (addr: string,args?:any[]) => {
        console.log('verifing contract ',addr)
        await require('hardhat').run("verify:verify", {
            address: addr,
            //constructorArguments: args,
        }).then(()=>{
            console.log('success')
        }).catch((e)=>{
            console.log(addr,' verify failed')
            console.log(e)
        });
    }
}