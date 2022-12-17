# ImmutableSplits

ImmutableSplits are a set of lightweight, immutable, gas-efficient payout split contracts. They are designed to be deployed to a deterministic address by a factory contract, which tracks if a particular payout split has already been deployed.

## ImmutableSplits

```solidity
interface IImmutableSplit {
    function getRecipients() external view returns (Recipient[] memory);
    function splitErc20(address token) external;
    function proxyCall(address target, bytes calldata callData) external returns (bytes memory);
    function receiveHook() external payable;
    receive() external payable;
}
```

- Automatically splits Ether/native-token payments to a predetermined set of recipients.
  - The recipients and their respective shares are set at deployment time and cannot be changed for gas-efficiency
- Disburses ERC20 splits when the `splitErc20` function is called
- `Recipient` addresses included on an `ImmutableSplit` may call the `proxyCall` function to execute a transaction on behalf of the `ImmutableSplit`. This is useful for allowing withdrawal of non-fungible tokens accidentally sent to a smart contract, or to execute a withdrawal directly to the split contract.

## ImmutableSplitFactory

```solidity
interface IImmutableSplitFactory {
    function createImmutableSplit(Recipient[] calldata recipients) external returns (address payable);
    function getDeployedImmutableSplitAddress(Recipient[] calldata recipients) external returns (address);
}
```

- Deploys `ImmutableSplit`s to deterministic addresses
- Tracks which `ImmutableSplit`s have already been deployed, and will revert if attempting to re-deploy an `ImmutableSplit` for a given set of recipients + bps
- When creating a new `ImmutableSplit`, an array of `Recipient`s must be passed. The following validation is applied:
  - A `Recipient` may not have a `bps` value of `0` or `10_000`.
  - The `bps` values of all `Recipient`s must sum to `10_000`.
- To ensure duplicates are not created, the following rules are enforced:
 - The `Recipient`s must be sorted by `bps` in ascending order.
 - If two or more `Recipient`s have the same `recipient`, the `Recipient`s with the numerically "lower" addresses must come first.