use starknet::ContractAddress;

#[starknet::interface]
pub trait IStarticle<TContractState> {
    /// @notice This function is used to register new user
    fn register(
        ref self: TContractState, name: felt252
    );
    
    /// @notice This function is used to publish new post
    fn publish(
        ref self: TContractState, title: felt252, ctx: ByteArray
    );
    
    /// @notice This function is used to like the post with (author, index)
    fn like(
        ref self: TContractState, author: ContractAddress, index: u256
    );
    
    // system get function
    fn get_system_total_published_num(self: @TContractState) -> u256;
    fn get_system_total_user_num(self: @TContractState) -> u256;
    
    // publication get function
    fn get_publication(self: @TContractState, address: ContractAddress) -> Publication;
    fn is_registered(self: @TContractState, address: ContractAddress) -> bool;

    // post get function
    fn get_post(self: @TContractState, address: ContractAddress, index: u256) -> Post;
    fn get_contest(self: @TContractState, address: ContractAddress, index: u256) -> ByteArray;
    fn get_likes(self: @TContractState, author: ContractAddress, index: u256) -> u256;
}

#[derive(Drop, Serde, Copy, starknet::Store)]
pub struct Publication {
    pub registered: bool,
    pub author_address: ContractAddress, // user's account address
    pub author_name: felt252, // short string
    pub total_published: u256,
    pub registry_time: u64 // timestamp
}

#[derive(Drop, Serde, Copy, starknet::Store)]
pub struct Post {
    pub index: u256, // the number of this post
    pub author_address: ContractAddress, // user's account address
    pub title: felt252, // short string
    pub post_time: u64, // timestamp
    pub likes_num: u256
}

#[starknet::contract]
pub mod Starticle {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, storage_access::StorageBaseAddress};
    
    use super::Publication;
    use super::Post;

    #[storage]
    struct Storage {
        pub total_user: u256,
        pub total_published: u256, 
        pub post: LegacyMap::<(ContractAddress, u256), Post>,
        pub context: LegacyMap::<(ContractAddress, u256), ByteArray>,
        pub publications: LegacyMap::<ContractAddress, Publication>,
    }

    #[event]
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    enum Event {
        Register: Register,
        Publish: Publish,
        Like: Like
    }
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    struct Register {
        pub author_address: ContractAddress,
        pub author_name: felt252,
        pub registry_time: u64
    }
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    struct Publish {
        pub index: u256, 
        pub author_address: ContractAddress,
        pub title: felt252,
        pub post_time: u64
    }
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    struct Like {
        pub author_address: ContractAddress,
        pub index: u256,
        pub liker_address: ContractAddress,
    }
    
    #[constructor]
    fn constructor(ref self: ContractState) {
        self.total_published.write(0);
        self.total_user.write(0); 
    }

    // Public functions inside an impl block
    #[abi(embed_v0)]
    impl Starticle of super::IStarticle<ContractState> {
        
        fn register(
            ref self: ContractState, name: felt252
        ) {
            // register the user info
            let sender = get_caller_address();
            let time = get_block_timestamp();
            let mut current_publication = Publication {
                registered: true,
                author_address: sender,
                author_name: name, 
                total_published: 0,
                registry_time: time
            };
            self.publications.write(sender, current_publication);

            // increment the total user number
            let user = self.total_user.read() + 1;
            self.total_user.write(user);

            // emit the event
            self.emit(
                Event::Register(Register { 
                            author_address: sender,
                            author_name: name,
                            registry_time: time
                        }
                    )
                );
        }

        fn publish(
            ref self: ContractState, title: felt252, ctx: ByteArray
        ) {
            let sender = get_caller_address();
            let time = get_block_timestamp();
            // increment the user post number
            let publication = self.publications.read(sender);
            let current_index = publication.total_published;
            let new_publication = Publication {
                registered: true,
                author_address: publication.author_address,
                author_name: publication.author_name, 
                total_published: publication.total_published + 1,
                registry_time: publication.registry_time
            };
            self.publications.write(sender, new_publication);

            // publish the post
            self.post.write((sender, current_index), Post {
                index: current_index, 
                author_address: sender, 
                title: title,
                post_time: time,
                likes_num: 0
            });
            self.context.write((sender, current_index), ctx);

            // increment the total post number
            let total_post = self.total_published.read() + 1;
            self.total_published.write(total_post);

            // emit the event
            self.emit(
                Event::Publish(Publish { 
                            index: current_index, 
                            author_address: sender,
                            title: title,
                            post_time: time
                        }
                    )
                );
        }

        fn like(
            ref self: ContractState, author: ContractAddress, index: u256
        ) {
            let liker = get_caller_address();
            let post = self.post.read((author, index));
            let new_post = Post {
                index: post.index, 
                author_address: post.author_address, 
                title: post.title,
                post_time: post.post_time,
                likes_num: post.likes_num + 1
            };
            self.post.write((author, index), new_post);

            // emit the event
            self.emit(
                Event::Like(Like { 
                            author_address: author,
                            index: index,
                            liker_address: liker,
                        }
                    )
                );
        }
        
        fn get_system_total_published_num(self: @ContractState) -> u256 {
            return self.total_published.read();
        }

        fn get_system_total_user_num(self: @ContractState) -> u256 {
            return self.total_user.read();
        }

        fn get_publication(self: @ContractState, address: ContractAddress) -> Publication {
            return self.publications.read(address);
        }

        fn is_registered(self: @ContractState, address: ContractAddress) -> bool {
            let publication = self.publications.read(address);
            return publication.registered;
        }

        fn get_post(self: @ContractState, address: ContractAddress, index: u256) -> Post {
            return self.post.read((address, index));
        }

        fn get_contest(self: @ContractState, address: ContractAddress, index: u256) -> ByteArray {
            return self.context.read((address, index));
        }
        
        fn get_likes(self: @ContractState, author: ContractAddress, index: u256) -> u256 {
            let post = self.post.read((author, index));
            return post.likes_num;
        }
    }

    // TODO: error handling
    
    // mod Errors {
    //     pub const USER_NOT_REGISTERED: felt252 = 'Publish: User has not registried';
    //     pub const PUBLISH_ZERO_ctx: felt252 = 'Publish: There is not any ctx in post';
    // }
    
    /// @dev Asserts implementation for the Starticle
    // #[generate_trait]
    // impl AssertsImpl of AssertsTrait {
    //     /// @dev Internal function that checks if an user is allowed to publish
    //     fn _assert_allowed_publish(ref self: ContractState, address: ContractAddress) {
    //         let is_registered = self.is_registered(address);
    //         assert(!is_registered, Errors::USER_NOT_REGISTERED);
    //     }
    // }
}