
#[starknet::contract]
pub mod Bank {
    use starknet::storage::StoragePointerReadAccess;
use starknet::event::EventEmitter;
use starknet::storage::StorageMapReadAccess;
use starknet::storage::StorageMapWriteAccess;
use starknet::storage::StoragePointerWriteAccess;
use starknet::storage::StoragePathEntry;
use mock::mock_bank_interface::IMock;
    use core::starknet::storage::Map;
    use starknet::{ ContractAddress, get_caller_address, contract_address, get_contract_address };
    use core::zeroable;

    #[storage]
    struct Storage {
        user: Map::<ContractAddress, User>,
        balance: Map::<ContractAddress, u256>,
        totalFunds: u256,
    }

    #[derive( Drop, Serde, starknet::Store)]
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
            assert(name != '' && phone != "", 'name cannot be blank');
            self.user.entry(caller).write(
                User {
                    name,
                    phone
                }
            );
            // self.balance.entry(caller).write(0);
            self.emit(AccountCreated {
                user: caller,
                name,
            });
        }

        fn deposit(ref self: ContractState, amount: u256, recipient: ContractAddress) {
            let caller = get_caller_address();
            let contract = get_contract_address();

            assert!(amount != 0, "amount cannot be zero");
            // assert!(recipient.);
            let balance = self.balance.entry(caller).read();
            let totalFundsBalance = self.totalFunds.read();
            self.balance.entry(caller).write(balance + amount);
            self.totalFunds.write(totalFundsBalance + amount);

            // TODO IERC20 TRANSFER
        }

        fn get_user_account_details(self: @ContractState) -> User;
    }




}
