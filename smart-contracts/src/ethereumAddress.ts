import {ethers} from "ethers";
import {option} from "fp-ts"

interface IHasAddress {
    address: string
}

interface INativeCurrencyAddress extends IHasAddress {
    _tag: "NativeToken"
}

interface INotNativeCurrencyAddress extends IHasAddress {
    _tag: "NotNativeToken"
}

type EthereumAddress = INativeCurrencyAddress | INotNativeCurrencyAddress

const eth: INativeCurrencyAddress = {
    _tag: "NativeToken",
    address: "0x0000000000000000000000000000000000000000"
}
const someEth = option.some(eth)

const nativeAddressRegex = /(0[xX])?0{40}/

function isNativeToken(address: string): boolean {
    return ethers.utils.isAddress(address) && nativeAddressRegex.test(address)
}

export function toEthereumAddress(address: string): option.Option<EthereumAddress> {
    if (ethers.utils.isAddress(address)) {
        if (isNativeToken(address)) {
            return someEth
        } else {
            return option.some({_tag: "NotNativeToken", address: address})
        }
    } else {
        return option.none
    }
}