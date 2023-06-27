global virtual class UserDataFactory implements IUserDataFactory {
    /**
    * @description get instance
    * @return IUserDataFactory
    **/
    global static IUserDataFactory get {
        get { return (IUserDataFactory)SystemX.getFactory(UserDataFactory.class); }
    }

    /**
    * @description creates a user object
    * @param account the account
    * @param contact the contact
    * @param profile the profile
    * @return User
    **/
    global virtual User createUser(Account account, Contact contact, String profile) {
        String alias = createAlias(contact.FirstName, contact.LastName);
        return new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = :profile LIMIT 1].Id,
            Username = contact.Email,
            FirstName = contact.FirstName,
            LastName = contact.LastName,
            Email = contact.Email,
            Alias = alias,
            CommunityNickname = alias + String.valueOf(Math.random() * 10000),
            CompanyName = account.Name,
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            ContactId = contact.Id,
            Department = 'test',
            Division = 'test'
        );
    }

    /**
    * @description creates a user object
    * @param name the name
    * @param lastname the lastname
    * @param profile the profile
    * @return User
    **/
    global virtual User createUser(String name, String lastname, String profile) {
        String alias = createAlias(name, lastname);
        String email = createEmail(name, lastname);
        return new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = :profile LIMIT 1].Id,
            Username = email,
            FirstName = name,
            LastName = lastname,
            Email = email,
            Alias = alias,
            CommunityNickname = alias + String.valueOf(Math.random() * 10000),
            CompanyName = String.join(new String[] { name, lastname }, ' '),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            Department = 'test',
            Division = 'test'
        );
    }

    /**
    * @description creates an email address
    * @param name the name
    * @param lastname the lastname
    * @return String
    **/
    global virtual String createEmail(String name, String lastname) {
        String email = name + '.' + lastname + '@test.com';
        return email.toLowerCase().replaceAll('\\s+', '_');
    }

    /**
    * @description creates an alias
    * @param name the name
    * @param lastname the lastname
    * @return String
    **/
    global virtual String createAlias(String name, String lastname) {
        String[] words = lastname.split('\\s+');
        String alias = name.split('')[0].toLowerCase();
        for (Integer i = 0; i < words.size() && i < 7; i++) {
            String word = words[i];
            String[] letters = word.split('');
            alias += letters[0].toLowerCase();
            // at last name
            if (i == words.size() - 1) {
                Integer j = 1;
                while (j < letters.size() && alias.length() < 8) { alias += letters[j]; j++; }
            }
        }
        return alias;
    }
}