use crate::mock_bank::Bank::User;
use core::starknet::{storage::Vec};

#[starknet::interface]
pub trait IMock<T> {
    fn create_account(ref self: T, name: felt252, phone: ByteArray);
    fn deposit(ref self: T, amount: u256);
    fn get_user_account_details(self: @T) -> User;
    fn withdraw(ref self: T, amount: u256);
}

#[starknet::interface]
pub trait FactoryTrait<TContractState> {
    fn create_child_bank(ref self: TContractState, child_classhash: starknet::ClassHash, user_address: starknet::ContractAddress, name: felt252, phone: felt252);
    fn get_total_contracts_deployed(self: @TContractState)-> u256;
    fn get_all_child_contracts(self: @TContractState) -> Array<starknet::ContractAddress>;
    fn get_contracts_of_user(ref self: TContractState, user: starknet::ContractAddress ) -> Array<starknet::ContractAddress>;
}

