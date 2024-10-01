#[starknet::contract]
mod Factory {
    use starknet::storage::{MutableVecTrait, Vec, VecTrait};
    use starknet::storage::{
        StoragePointerWriteAccess, StoragePointerReadAccess, Map, StoragePathEntry
    };
    use starknet::{syscalls::deploy_syscall, ContractAddress, get_caller_address, ClassHash};
    use crate::mock_bank_interface::FactoryTrait;
    use core::serde::Serde;

    #[storage]
    struct Storage {
        total_child_contracts: u256,
        child_contracts: Vec<ContractAddress>,
        user_contracts: Map<ContractAddress, Vec<ContractAddress>>,
    }

    // #[event]
    // #[derive(Drop, starknet::Event)]
    // enum Event {
    // }

    #[abi(embed_v0)]
    impl FactoryImpl of FactoryTrait<ContractState> {
        fn create_child_bank(
            ref self: ContractState,
            child_classhash: ClassHash,
            user_address: starknet::ContractAddress,
            name: felt252,
            phone: felt252
        ) {
            let caller = get_caller_address();
            let mut payload = array![];
            child_classhash.serialize(ref payload);
            user_address.serialize(ref payload);
            name.serialize(ref payload);
            phone.serialize(ref payload);

            let (child_contract, _) = deploy_syscall(child_classhash, 0, payload.span(), false)
                .unwrap();

            self.total_child_contracts.write(self.total_child_contracts.read() + 1);
            self.child_contracts.append().write(child_contract);

            let vec = self.user_contracts.entry(caller);

            loop {
                let mut i = 0;
                if i > self.child_contracts.len() {
                    break;
                }
                let mut child_contract = self.child_contracts.at(i).read();
                vec.append().write(child_contract);
                i += 1;
            }
        }


        fn get_total_contracts_deployed(self: @ContractState) -> u256 {
            self.total_child_contracts.read()
        }

        fn get_all_child_contracts(self: @ContractState) -> Array<starknet::ContractAddress> {
            let mut address_arr = array![];
            for index in 0
                ..self
                    .child_contracts
                    .len() {
                        address_arr.append(self.child_contracts.at(index).read());
                    };
            address_arr
        }

        fn get_contracts_of_user(
            ref self: ContractState, user: ContractAddress
        ) -> Array<ContractAddress> {
            let stored_addresses = self.user_contracts.entry(user);
            let mut arr = array![];
            let mut i = 0;

            loop {
                if i > stored_addresses.len() {
                    break;
                }
                let mut contract = stored_addresses.at(i).read();
                arr.append(contract);
                i += 1;
            };
            arr
        }
    }
}
