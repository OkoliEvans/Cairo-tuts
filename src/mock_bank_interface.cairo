use mock::mock_bank::Bank::User;

#[starknet::interface]
pub trait IMock <T> {
    fn create_account(ref self: T, name: felt252, phone: ByteArray);
    fn deposit(ref self: T, amount: u256);
    fn get_user_account_details(self: @T) -> User;
}

