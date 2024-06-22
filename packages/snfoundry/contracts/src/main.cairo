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
    );
    
    // system get function
    fn get_system_total_published_num(self: @TContractState) -> u256;
    fn get_system_total_user_num(self: @TContractState) -> u256;
    
    // publication get function
    fn get_publication(self: @TContractState, address: ContractAddress) -> Startikle::Publication;
    fn is_registered(self: @TContractState, address: ContractAddress) -> bool;

    // post get function
    fn get_post(self: @TContractState, address: ContractAddress, index: u256) -> Startikle::Post;
    fn get_likes(self: @TContractState, author: ContractAddress, index: u256) -> number;
}

#[starknet::contract]
pub mod Startikle {
    use starknet::{ContractAddress, get_caller_address, storage_access::StorageBaseAddress};
    
    #[derive(Drop, Serde, starknet::Store)]
    pub struct Post {
        index: u256, // the number of this post
        author_address: ContractAddress, // user's account address
        title: felt252, // short string
        context: ByteArray,  // long string
        post_time: u64, // timestamp
        likes_num: u256
    }
    
    #[derive(Drop, Serde, starknet::Store)]
    pub struct Publication {
        registered: bool,
        author_address: ContractAddress, // user's account address
        author_name: felt252, // short string
        total_published: u256,
        registry_time: u64 // timestamp
    }

    #[storage]
    struct Storage {
        total_user: u256,
        total_published: u256, 
        post: LegacyMap::<(ContractAddress, u256), Post>,
        publications: LegacyMap::<ContractAddress, Publication>,
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
    impl Startikle of IStarticle<ContractState> {
        
        fn register(
            ref self: TContractState, name: felt252
        ) {
            // register the user info
            let sender = get_caller_address();
            let mut current_publication = Publication {
                registered: true,
                author_address: sender,
                author_name: name, 
                total_published: 0,
                registry_time: get_block_number()
            };
            self.publications.write(sender, current_publication);

            // increment the total user number
            let user = self.total_user.read() + 1;
            self.total_user.write(user);
        }

        fn publish(
            ref self: TContractState, title: felt252, context: ByteArray
        ) {
            let sender = get_caller_address();
            // increment the user post number
            let pubication = self.publications.read(sender);
            let user_post = pubication.total_published + 1;
            pubication.total_published = user_post
            self.publications.write(sender, pubication);

            // publish the post
            let mut current_post = Post {
                index: user_post, 
                author_address: sender, 
                title: title,
                context: context,
                post_time: get_block_number(),
                likes_num: 0
            };
            self.post.write((sender, user_post), current_post);

            // increment the total post number
            let total_post = self.total_published.read() + 1;
            self.total_published.write(total_post);
        }

        fn like(
            ref self: TContractState, author: ContractAddress, index: u256
        ) {
            let post = self.post.read((author, index));
            let likes = post.likes_num + 1;
            post.likes_num = likes
            self.post.write((author, index), post);
        }
        
        fn get_system_total_published_num(self: @TContractState) -> u256 {
            return self.total_published.read();
        }
        fn get_system_total_user_num(self: @TContractState) -> u256 {
            return self.total_user.read();
        }
    }
    
    mod Errors {
        pub const USER_NOT_REGISTERED: felt252 = 'Publish: User has not registried';
        pub const PUBLISH_ZERO_CONTEXT: felt252 = 'Publish: There is not any context in post';
    }
    
    // TODO: error handling
    /// @dev Asserts implementation for the Starticle
    #[generate_trait]
    impl AssertsImpl of AssertsTrait {
        /// @dev Internal function that checks if an user is allowed to publish
        fn _assert_allowed_publish(ref self: ContractState, address: ContractAddress) {
            let is_registered = self.is_registered(address);
            assert(!is_registered, Errors::USER_NOT_REGISTERED);
        }
    }
}