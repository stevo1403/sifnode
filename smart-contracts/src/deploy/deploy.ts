import * as hardhat from "hardhat"
import {container} from "tsyringe";
import {ContractFactories, ContractFactoriesToken} from "../tsyringe/contracts";
import {HardhatRuntimeEnvironmentToken} from "../tsyringe/hardhat";

console.log("deployingx")

async function main() {
    container.register(HardhatRuntimeEnvironmentToken, {useValue: hardhat})
    const factories = await container.resolve<ContractFactories>(ContractFactoriesToken)
    console.log("factories", factories)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });