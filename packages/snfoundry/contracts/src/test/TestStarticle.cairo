use contracts::Starticle::{IStarticleDispatcher, IStarticleDispatcherTrait};
use openzeppelin::tests::utils::constants::OWNER;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait};
use starknet::ContractAddress;

fn deploy_contract() -> ContractAddress {
    let contract = declare("Starticle").unwrap();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    /// @notice we don't need the constructor calldata here
    // let mut calldata = array![];
    // calldata.append_serde(OWNER());
    // let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_deployment_values() {

    let contract_address = deploy_contract();

    let dispatcher = IStarticleDispatcher { contract_address };

    // Test initialization
    let current_published = dispatcher.get_system_total_published_num();
    let expected_published: u256 = 0;
    assert_eq!(current_published, expected_published, "Should have the right total published");

    let current_user = dispatcher.get_system_total_user_num();
    let expected_user: u256 = 0;
    assert_eq!(current_user, expected_user, "Should have the right total user");

    // let new_greeting: ByteArray = "Learn Scaffold-Stark 2! :)";
    // dispatcher.set_gretting(new_greeting.clone(), 0); // we transfer 0 eth
    // assert_eq!(dispatcher.gretting(), new_greeting, "Should allow setting a new message");
}
