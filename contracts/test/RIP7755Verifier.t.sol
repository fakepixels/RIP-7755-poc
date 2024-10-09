// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {DeployRIP7755Verifier} from "../script/DeployRIP7755Verifier.s.sol";
import {Call, CrossChainCall, FulfillmentInfo} from "../src/RIP7755Structs.sol";
import {RIP7755Verifier} from "../src/RIP7755Verifier.sol";

contract RIP7755VerifierTest is Test {
    RIP7755Verifier verifier;

    Call[] calls;
    address FILLER = makeAddr("filler");

    function setUp() public {
        DeployRIP7755Verifier deployer = new DeployRIP7755Verifier();
        verifier = deployer.run();
    }

    function test_fulfill_revertsIfInvalidChainId() external {
        CrossChainCall memory _request = _initRequest();

        _request.destinationChainId = 0;

        vm.prank(FILLER);
        vm.expectRevert(RIP7755Verifier.RIP7755Verifier__InvalidChainId.selector);
        verifier.fulfill(_request);
    }

    function test_fulfill_revertsIfInvalidDestinationAddress() external {
        CrossChainCall memory _request = _initRequest();

        _request.verifyingContract = address(0);

        vm.prank(FILLER);
        vm.expectRevert(RIP7755Verifier.RIP7755Verifier__InvalidVerifyingContract.selector);
        verifier.fulfill(_request);
    }

    function test_fulfill_storesFulfillment() external {
        CrossChainCall memory _request = _initRequest();

        vm.prank(FILLER);
        verifier.fulfill(_request);

        bytes32 callHash = verifier.callHashCalldata(_request);
        FulfillmentInfo memory info = verifier.getFillInfo(callHash);

        assertEq(info.filler, FILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function _initRequest() private view returns (CrossChainCall memory) {
        return CrossChainCall({
            calls: calls,
            originationContract: address(0),
            originChainId: 0,
            destinationChainId: block.chainid,
            nonce: 0,
            verifyingContract: address(verifier),
            l2Oracle: address(0),
            l2OracleStorageKey: bytes32(0),
            rewardAsset: address(0),
            rewardAmount: 0,
            finalityDelaySeconds: 0,
            precheckContract: address(0),
            precheckData: ""
        });
    }
}