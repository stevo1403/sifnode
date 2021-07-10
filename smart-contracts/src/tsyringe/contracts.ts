import {ethers} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {container, instanceCachingFactory} from "tsyringe";
import {HardhatRuntimeEnvironmentToken} from "./hardhat";

export type ContractFactories = {
    BridgeBank: ethers.ContractFactory
    CosmosBridge: ethers.ContractFactory
    BridgeRegistry: ethers.ContractFactory
    BridgeToken: ethers.ContractFactory
}

export async function buildContractFactories(hre: HardhatRuntimeEnvironment): Promise<ContractFactories> {
    const bridgeBank = hre.ethers.getContractFactory("BridgeBank");
    const cosmosBridge = hre.ethers.getContractFactory("CosmosBridge");
    const bridgeRegistry = hre.ethers.getContractFactory("BridgeRegistry");
    const bridgeToken = hre.ethers.getContractFactory("BridgeToken");
    return {
        BridgeBank: await bridgeBank,
        CosmosBridge: await cosmosBridge,
        BridgeRegistry: await bridgeRegistry,
        BridgeToken: await bridgeToken,
    }
}

export const ContractFactoriesToken = Symbol("ContractFactories")

container.register<Promise<ContractFactories>>(ContractFactoriesToken, {
    useFactory: instanceCachingFactory<Promise<ContractFactories>>(c => buildContractFactories(c.resolve(HardhatRuntimeEnvironmentToken)))
})

