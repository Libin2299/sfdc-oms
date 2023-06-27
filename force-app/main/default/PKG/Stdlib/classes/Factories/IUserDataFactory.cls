global interface IUserDataFactory {
    User createUser(Account account, Contact contact, String profile);
    User createUser(String name, String lastname, String profile);
    String createEmail(String name, String lastname);
    String createAlias(String name, String lastname);
}