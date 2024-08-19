#[starknet::contract]
pub mod Bank {
    use starknet::storage::StoragePointerReadAccess;
    use starknet::event::EventEmitter;
    use starknet::storage::StorageMapReadAccess;
    use starknet::storage::StorageMapWriteAccess;
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::StoragePathEntry;
    use mock::mock_bank_interface::{IMock, IMockDispatcher, IMockDispatcherTrait};
    use mock::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait, IERC20LibraryDispatcher};
    use core::starknet::storage::Map;
    use starknet::{
        ContractAddress, get_caller_address, contract_address, get_contract_address, class_hash,
        ClassHash
    };
    use core::num::traits::Zero;
    use alexandria_storage::list::{List, ListTrait, IndexView};

    #[storage]
    struct Storage {
        user: Map::<ContractAddress, User>,
        balance: Map::<ContractAddress, u256>,
        totalFunds: u256,
        registered_users: List<ContractAddress>,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct User {
        name: felt252,
        phone: ByteArray,
        }
        
        #[event]
        #[derive(Drop, starknet::Event)]
        enum Event {
            AccountCreated: AccountCreated,
            Deposit: Deposit,
            Withdrawal: Withdrawal,
            }
            
            #[derive(Drop, starknet::Event)]
            struct AccountCreated {
                user: ContractAddress,
                name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct Deposit {
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdrawal {
        user: ContractAddress,
        amount: u256,
    }

    #[abi(embed_v0)]
    impl IMockImpl of IMock<ContractState> {
        fn create_account(ref self: ContractState, name: felt252, phone: ByteArray) {
            let caller = get_caller_address();
            let days = array![5, 'monday', 'Tuesday'];
            let mut registered_users = ArrayTrait::new();
            assert(name != '' && phone != "", 'name cannot be blank');
            self.user.entry(caller).write(User { name, phone });
            registered_users.append(caller);
            self.accept_arrays(registered_users);
            self.emit(AccountCreated { user: caller, name, });
        }

        fn deposit(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            let contract = get_contract_address();
            let contract_address: ContractAddress =
                0x07c535ddb7bf3d3cb7c033bd1a4c3aac02927a4832da795606c0f3dbbc6efd17
                .try_into()
                .unwrap();
            let contract_class: ClassHash =
                0x07c535ddb7bf3d3cb7c033bd1a4c3aac02927a4832da795606c0f3dbbc6efd18
                .try_into()
                .expect('wrong class');

            assert!(amount != 0, "amount cannot be zero");
            assert!(contract.is_non_zero(), "Zero address detected");
            let balance = self.balance.entry(caller).read();
            let totalFundsBalance = self.totalFunds.read();
            IERC20Dispatcher { contract_address }.transfer(contract, amount);
            IERC20LibraryDispatcher { class_hash: contract_class }.transfer(contract, amount);
            self.balance.entry(caller).write(balance + amount);
            self.totalFunds.write(totalFundsBalance + amount);
            self.emit(Deposit { user: caller, amount });
        }

        fn get_user_account_details(self: @ContractState) -> User {
            let caller: ContractAddress = get_caller_address();
            self.user.entry(caller).read()
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn accept_arrays(ref self: ContractState, users: Array<ContractAddress>) {}
    }
}
