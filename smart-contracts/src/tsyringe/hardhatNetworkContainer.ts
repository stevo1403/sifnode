import {container} from "tsyringe";
import {DeploymentEnv} from "../deploymentEnv";

const defaultDeploymentEnv: DeploymentEnv = {
    consensusThreshold: 100,
    initialPowers: [100]
}

const mycontainer = container.createChildContainer()

container.register("DeploymentEnv", {useValue: defaultDeploymentEnv});
container.register("fnord", {useValue: "is fnord"})

export {container}