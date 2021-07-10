import * as chai from "chai"
import {expect} from "chai"
import {describe, it} from "mocha"
import {
    buildContractFactories,
    ContractFactories,
    ContractFactoriesToken
} from "../../src/tsyringe/contracts";
import * as hardhat from "hardhat"
import {container, instanceCachingFactory} from "tsyringe";
import JSON = Mocha.reporters.JSON;

describe("ContractFactories", function () {
    before(() => container.register("HardhatRuntimeEnvironment", {useValue: hardhat}))
    it("Should return ContractFactories", async () => {
        const c = await container.resolve<Promise<ContractFactories>>(ContractFactoriesToken)
        expect(c).to.be.not.null
    });
});