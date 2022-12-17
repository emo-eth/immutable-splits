# ImmutableSplits

Immutable splits are lightweight, immutable, gas-efficient payout split contracts. They are designed to be deployed to a deterministic address by a factory contract, which tracks if a particular payout split has already been deployed.

## ImmutableSplits

Automatically splits Ether/native-token payments to a predetermined set of recipients. The recipients and their respective shares are set at deployment time and cannot be changed.
Transfers ERC20 splits when the `splitErc20` function is called.
`Recipient`s included on an `ImmutableSplit` may call the `proxyCall` function to execute a transaction on behalf of the `ImmutableSplit`. This is useful for allowing withdrawal of non-fungible tokens accidentally sent to a smart contract, or to execute a withdrawal directly to the split contract.

## ImmutableSplitFactory

Factory contract for deploying `ImmutableSplit`s. The factory contract tracks which splits have already been deployed, and will not deploy a new split if one already exists for the given recipients and shares.

When creating a new `ImmutableSplit`, an array of `Recipient`s must be passed. The following validation is applied:
- A `Recipient` may not have a `bps` value of `0` or `10_000`.
- The `bps` values of all `Recipient`s must sum to `10_000`.

To ensure duplicates are not created, the following rules are enforced:
 - The `Recipient`s must be sorted by `bps` in ascending order.
 - If two or more `Recipient`s have the same `recipient`, the `Recipient`s with the numerically "lower" addresses must come first.