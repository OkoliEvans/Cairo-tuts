#[starknet::contract]
pub mod Bank {
    use core::hash::{ HashStateTrait, HashStateExTrait};
    use starknet::event::EventEmitter;
    use starknet::storage::{
        StorageMapReadAccess, StoragePointerReadAccess, StorageMapWriteAccess,
        StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use mock::mock_bank_interface::{IMock, IMockDispatcher, IMockDispatcherTrait};
    use mock::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait, IERC20LibraryDispatcher};
    use starknet::{
        ContractAddress, get_caller_address, contract_address, get_contract_address, class_hash,
        ClassHash
    };
    use core::{poseidon::PoseidonTrait, pedersen::PedersenTrait, num::traits::Zero};
    use alexandria_storage::list::{List, ListTrait, IndexView};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    // component!(path: UpgradeableComponent, storage: upgradable, event: UpgradableEvent);

    #[storage]
    struct Storage {
        user: Map::<ContractAddress, User>,
        balance: Map::<ContractAddress, u256>,
        totalFunds: u256,
        registered_users: List<ContractAddress>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        upgradable: UpgradeableComponent::Storage,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct User {
        name: felt252,
        phone: ByteArray,
    }

    #[derive(Drop, starknet::Store)]
    enum UserLevel {
        basic,
        premium,
        veteran
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AccountCreated: AccountCreated,
        Deposit: Deposit,
        Withdrawal: Withdrawal,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct AccountCreated {
        user: ContractAddress,
        name: felt252,
    }

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

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

    #[constructor]
    fn constructor(ref self: ContractState) {
        let caller = get_caller_address();
        self.ownable.initializer(caller);
    }

    #[abi(embed_v0)]
    impl IMockImpl of IMock<ContractState> {
        fn create_account(ref self: ContractState, name: felt252, phone: ByteArray) {
            self.ownable.assert_only_owner();
            let caller = get_caller_address();
            let mut registered_users = ArrayTrait::new();
            assert(name != '' && phone != "", 'name cannot be blank');
            let name_hash: felt252 = PoseidonTrait::new().update_with(name).finalize();
            self.user.entry(caller).write(User { name: name_hash, phone });
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

            IERC20Dispatcher { contract_address }.transfer_from(caller, contract, amount);
            IERC20LibraryDispatcher { class_hash: contract_class }.transfer_from(caller, contract, amount);

            self.balance.entry(caller).write(balance + amount);
            self.totalFunds.write(totalFundsBalance + amount);

            self.emit(Deposit { user: caller, amount });
        }

        fn get_user_account_details(self: @ContractState) -> User {
            let caller: ContractAddress = get_caller_address();
            self.user.entry(caller).read()
        }
        
        fn withdraw(ref self: ContractState, amount: u256) {
            let contract: ContractAddress = get_contract_address();
            let caller: ContractAddress = get_caller_address();

            let token_address: ContractAddress =
                0x07c535ddb7bf3d3cb7c033bd1a4c3aac02927a4832da795606c0f3dbbc6efd17
                .try_into()
                .unwrap();

            let contract_balance = self.balance.entry(contract).read();
            let user_balance = self.balance.entry(caller).read();
            let total_funds_balance = self.totalFunds.read();

            assert!(contract_balance >= amount, "insufficient contract balance");
            assert!(user_balance >= amount, "insufficient funds");

            self.balance.entry(caller).write(user_balance - amount);
            self.totalFunds.write(total_funds_balance - amount);

            IERC20Dispatcher { contract_address: token_address }.transfer(caller, amount);

            self.emit(Withdrawal { user: caller, amount });
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn accept_arrays(ref self: ContractState, users: Array<ContractAddress>) {}

        fn get_user_level(ref self: UserLevel) -> ByteArray{
            match @self {
                UserLevel::basic => "basic",
                UserLevel::premium => "premium",
                UserLevel::veteran => "veteran"
            }
        }
    }
}
