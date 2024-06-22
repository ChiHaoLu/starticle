
# System Design

## Glossary

TBD

## Workflow

TBD

## Contract

```cairo=
use starknet::ContractAddress;

#[starknet::interface]
pub trait IStarticle<TContractState> {
    /// @notice This function is used to register new user
    fn register(
        ref self: TContractState, name: felt252
    );
    
    /// @notice This function is used to publish new post
    /// @dev author info fetch from `get_caller_address()`
    /// @dev `index` must strictly increase, get from `Publication.total_published`
    /// @dev `timestamp` get from environment variable
    fn publish(
        ref self: TContractState, title: felt252, context: ByteArray
    );
    
    /// @notice This function is used to like the post with (author, index)
    fn like(
        ref self: TContractState, author: ContractAddress, index: u256
    )
    
    // system get function
    fn get_system_total_published_num(self: @TContractState) -> u256;
    fn get_system_total_user_num(self: @TContractState) -> u256;
    
    // publication get function
    fn get_publication(self: @TContractState, address: ContractAddress) -> Startikle::Publication;
    fn is_registered(self: @TContractState, address: ContractAddress) -> bool;

    // post get function
    fn get_post(self: @TContractState, address: ContractAddress, index: u256) -> Startikle::Post;
    fn is_liked(self: @TContractState, author: ContractAddress, index: u256, liker: ContractAddress) -> bool;
}

#[starknet::contract]
mod Startikle {
    use starknet::{ContractAddress, get_caller_address, storage_access::StorageBaseAddress};
    
    #[derive(Drop, Serde, starknet::Store)]
    pub struct Post {
        index: u256, // the number of this post
        author_address: ContractAddress, // user's account address
        title: felt252, // short string
        context: ByteArray,  // long string
        post_time: u64, // timestamp
        likes: LegacyMap::<ContractAddress, bool>
        likes_num: u256
    }
    
    #[derive(Drop, Serde, starknet::Store)]
    pub struct Publication {
        registered: bool,
        author_address: ContractAddress, // user's account address
        author_name: felt252, // short string
        posts: LegacyMap::<u256, Post>, // use index to find
        total_published: u256,
        registry_time: u64 // timestamp
    }
    
    /// @params owner The owner account address of Starticle
    /// @params total_user The quantity of users in Starticle
    /// @params total_published The quantity of posts Starticle
    #[storage]
    struct Storage {
        publications: LegacyMap::<ContractAddress, Publication>,
        total_user: u256,
        total_published: u256, 
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Register: Register,
        Publish: Publish,
        Like: Like
    }
    #[derive(Drop, starknet::Event)]
    struct Register {
        // TBD
    }
    #[derive(Drop, starknet::Event)]
    struct Publish {
        // TBD
    }
    #[derive(Drop, starknet::Event)]
    struct Like {
        // TBD
    }
    
    #[constructor]
    fn constructor(ref self: ContractState) {
        self.total_published.write(0);
        self.total_user.write(0); 
    }

    // Public functions inside an impl block
    #[abi(embed_v0)]
    impl Startikle of super::IStarticle<ContractState> {
        
        
        
        
        
        
        
    }
    
    mod Errors {
        pub const USER_NOT_REGISTERED: felt252 = 'Publish: User has not registried';
        pub const PUBLISH_ZERO_CONTEXT: felt252 = 'Publish: There is not any context in post';
        pub const USER_HAS_LIKED: felt252 = 'Like: User has liked this post';
    }
    
    /// @dev Asserts implementation for the Starticle
    #[generate_trait]
    impl AssertsImpl of AssertsTrait {
        /// @dev Internal function that checks if an user is allowed to publish
        fn _assert_allowed_publish(ref self: ContractState, address: ContractAddress) {
            let is_registered bool = self.is_registered(address);
            assert(!is_registered, Errors::USER_NOT_REGISTERED);
        }
        
        /// @dev Internal function that checks if an user is allowed to like
        /// @notice The liker could not be an registried user, everyone can like the post 
        fn _assert_allowed_like(ref self: ContractState, author: ContractAddress, index: u256, liker: ContractAddress) {
            let is_liked bool = self.is_liked(author, index, liker);
            assert(!is_liked, Errors::USER_HAS_LIKED);
        }
    }
}
```

## Website

TBD
