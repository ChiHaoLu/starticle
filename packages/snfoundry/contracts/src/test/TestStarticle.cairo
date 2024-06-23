use contracts::Starticle::{IStarticleDispatcher, IStarticleDispatcherTrait};
use openzeppelin::tests::utils::constants::OWNER;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address, spy_events, SpyOn, EventSpy};
use starknet::{
    ContractAddress, contract_address_const, SyscallResultTrait, syscalls::deploy_syscall
};

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
}

#[test]
fn test_register() {
    let contract_address = deploy_contract();
    let dispatcher = IStarticleDispatcher { contract_address };

    let caller = contract_address_const::<'caller'>();
    let new_user_name: felt252 = 'hello';

    start_cheat_caller_address(contract_address, caller);
    dispatcher.register(new_user_name);
    stop_cheat_caller_address(contract_address);

    let user_info = dispatcher.get_publication(caller);
    assert_eq!(user_info.registered, true, "Should be the expected registered");
    assert_eq!(user_info.author_address, caller, "Should be the expected registering author address");
    assert_eq!(user_info.author_name, new_user_name, "Should be the expected registering author name");
    assert_eq!(user_info.total_published, 0, "Should be the expected total_published");
}

#[test]
fn test_publish() {
    let contract_address = deploy_contract();
    let dispatcher = IStarticleDispatcher { contract_address };

    let caller = contract_address_const::<'caller'>();
    let new_title: felt252 = 'First Title';
    let new_ctx: ByteArray = "First Post";

    start_cheat_caller_address(contract_address, caller);
    dispatcher.publish(new_title, new_ctx.clone());
    stop_cheat_caller_address(contract_address);

    let user_info = dispatcher.get_publication(caller);
    assert_eq!(user_info.total_published, 1, "Should be the expected total_published");

    let post_info = dispatcher.get_post(caller, 0);
    assert_eq!(post_info.index, 0, "Should be the expected index");
    assert_eq!(post_info.author_address, caller, "Should be the expected author_address");
    assert_eq!(post_info.title, new_title, "Should be the expected title");
    assert_eq!(post_info.likes_num, 0, "Should be the expected likes_num");

    let context = dispatcher.get_context(caller, 0);
    assert_eq!(context, new_ctx.clone(), "Should be the expected context");
}

#[test]
fn test_like() {
    let contract_address = deploy_contract();
    let dispatcher = IStarticleDispatcher { contract_address };

    let caller = contract_address_const::<'caller'>();
    let new_title: felt252 = 'First Title';
    let new_ctx: ByteArray = "First Post";

    start_cheat_caller_address(contract_address, caller);
    dispatcher.publish(new_title, new_ctx.clone());
    stop_cheat_caller_address(contract_address);
    
    let liker = contract_address_const::<'liker'>();
    start_cheat_caller_address(contract_address, liker);
    dispatcher.like(caller, 0);
    stop_cheat_caller_address(contract_address);

    let post_info = dispatcher.get_post(caller, 0);
    assert_eq!(post_info.likes_num, 1, "Should be the expected likes_num");

}


