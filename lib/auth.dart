import 'package:objective_db/objective_db.dart';

//Username, Password, accesTokens, Roles.
List<DbObject> _getStoredAccounts({
  required Entry authDatabase,
}){
  try{
    List<DbObject> storedAccounts = authDatabase.select().selectMultiple(
      key: "accounts",
    );
    return storedAccounts;
  }catch(error){
    return [];
  }
}
List<DbObject> _getStoredAccessTokens({
  required Entry authDatabase,
}){
  try{
    List<DbObject> storedAccounts = authDatabase.select().selectMultiple(
      key: "accessTokens",
    );
    return storedAccounts;
  }catch(error){
    return [];
  }
}
//Get account using access token
DbObject? _getAccountUsingAccessToken({
  required Entry authDatabase,
  required String accessToken,
}){
  try{
    String accountUUID = DbObject(
      uuid: accessToken, 
      dbPath: authDatabase.dbPath, 
      cipherKeys: authDatabase.cipherKeys,
    ).view()["accountUUID"];
    return DbObject(
      uuid: accountUUID, 
      dbPath: authDatabase.dbPath, 
      cipherKeys: authDatabase.cipherKeys,
    );
  }catch(error){
    return null;
  }
}
DbObject? _getAccount({
  required Entry authDatabase,
  required String username,
}){
  List<DbObject> storedAccounts = _getStoredAccounts(
    authDatabase: authDatabase,
  );
  //Make sure that the account is unique
  for(DbObject storedAccount in storedAccounts){
    Map<String,dynamic> objectContents = storedAccount.view();
    if(objectContents["username"] == username){
      return storedAccount;
    }
  }
  return null;
}
void _removeAccessToken({
  required Entry authDatabase,
  required String accessToken,
}){
  //Find account by reading access token data
  DbObject? account = _getAccountUsingAccessToken(
    authDatabase: authDatabase, 
    accessToken: accessToken,
  );
  if(account == null){
    throw "Invalid access token.";
  }else{
    //Delete access token
    authDatabase.select().delete(
      key: "accessTokens", 
      uuid: accessToken,
    );
    //Delete reference to access token
    Map<String,dynamic> accountContent = account.view();
    List<dynamic> accountAccessTokens = accountContent["accessTokens"];
    int index = accountAccessTokens.indexOf(accessToken);
    if(index != -1){
      account.pop(index: index, key: "accessTokens");
    }
  }
}
//-------------------------------------------------------------------------
String createAccount({
  required Entry authDatabase,
  required String username,
  required String password,
  List<String>? roles,
}){
  DbObject? existingAccount = _getAccount(
    authDatabase: authDatabase, 
    username: username,
  );
  if(existingAccount == null){
    authDatabase.select().insert(
      key: "accounts", 
      value: [
        {
          "username": username,
          "password": password,
          "roles": roles ?? [],
          "accessTokens": [],
        },
      ],
    );
    return "Account creation for $username successful.";
  }else{
    throw "Account associated with $username already exist.";
  }
}
String deleteAccount({
  required Entry authDatabase,
  required String username,
}){
  DbObject? accountForDeletion = _getAccount(
    authDatabase: authDatabase,
    username: username,
  );
  if(accountForDeletion == null){
    throw "No account found asociated with the username $username.";
  }else{
    //Delete authentication tokens recursively
    Map<String,dynamic> accountContent = accountForDeletion.view();
    List<String> accessTokens = List<String>.from(accountContent["accessTokens"]);
    for(String token in accessTokens){
      try{
        _removeAccessToken(
          authDatabase: authDatabase, 
          accessToken: token,
        );
      }catch(error){
        //Prevent error propagation
      }
    }
    //Delete the account
    authDatabase.select().delete(
      key: "accounts", 
      uuid: accountForDeletion.uuid,
    );
    return "Account asociated with $username deleted successfully.";
  }
}
String login({
  required Entry authDatabase,
  required String username,
  required String password,
}){
  DbObject? account = _getAccount(
    authDatabase: authDatabase, 
    username: username,
  );
  if(account == null){
    throw "No account found asociated with the username $username.";
  }else{
    //Create access token if password is a match
    if(password == account.view()["password"]){
      List<String> accessToken = authDatabase.select().insert(
        key: "accessTokens", 
        value: [
          {
            "accountUUID": account.uuid,
            //TODO: Implement auto removal when expired in the future.
            "creation": DateTime.now().toUtc().toString(),
          },
        ],
      );
      //Create a reference to link, find and delete when needed.
      account.insert(
        key: "accessTokens",
        value: [
          accessToken.first,
        ],
      );
      return accessToken.first;
    }else{
      throw "Incorrect credentials.";
    }
  }
}
String logout({
  required Entry authDatabase,
  required String accessToken,
}){
  _removeAccessToken(authDatabase: authDatabase, accessToken: accessToken);
  return "Logged out successfully.";
}
//Get rid of all access tokens
String logOutFromEverywhere({
  required Entry authDatabase,
  required String username,
  required String password,
}){
  DbObject? account = _getAccount(
    authDatabase: authDatabase,
    username: username,
  );
  if(account == null){
    throw "No account found asociated with the username $username.";
  }else if(account.view()["username"] == username && account.view()["password"] == password){
    //Delete authentication tokens recursively
    Map<String,dynamic> accountContent = account.view();
    List<dynamic> accessTokens = accountContent["accessTokens"];
    for(String token in accessTokens){
      try{
        _removeAccessToken(
          authDatabase: authDatabase, 
          accessToken: token,
        );
      }catch(error){
        //Prevent error propagation
      }
    }
  }
  return "Logged out from all devices successfully.";
}
//Update password
String updatePassword({
  required Entry authDatabase,
  required String username,
  required String password,
  required String newPassword,
}){
  DbObject? account = _getAccount(
    authDatabase: authDatabase, 
    username: username,
  );
  if(account == null){
    throw "Invalid credentials.";
  }else{
    account.insert(
      key: "password", 
      value: newPassword,
    );
    return "Password changed successfully";
  }
}
//Remove role
String removeRole({
  required Entry authDatabase,
  required String username,
  required String role,
}){
  DbObject? account = _getAccount(
    authDatabase: authDatabase, 
    username: username,
  );
  if(account != null){
    Map<String,dynamic> accountContent = account.view();
    List<dynamic> roles = accountContent["roles"];
    int index = roles.indexOf(role);
    if(0 <= index){
      account.pop(index: index, key: "roles");
      return "Role $role removed successfully.";
    }else{
      throw "Role $role not found.";
    }
  }else{
    throw "Invalid username.";
  }
}
//Add role
String addRole({
  required Entry authDatabase,
  required String username,
  required String role,
}){
  DbObject? account = _getAccount(
    authDatabase: authDatabase, 
    username: username,
  );
  if(account != null){
    account.insert(
      key: "roles", 
      value: [
        role,
      ],
    );
    return "Role $role added successfully.";
  }else{
    throw "Invalid username.";
  }
}
//Has Role
bool hasRole({
  required Entry authDatabase,
  required String accessToken,
  required String role,
}){
  DbObject? account = _getAccountUsingAccessToken(
    authDatabase: authDatabase, 
    accessToken: accessToken,
  );
  if(account != null){
    Map<String,dynamic> accountContent = account.view();
    List<dynamic> roles = accountContent["roles"];
    int index = roles.indexOf(role);
    if(0 <= index){
      return true;
    }else{
      return false;
    }
  }else{
    throw "Invalid username.";
  }
}
//Token is valid
bool tokenIsValid({
  required Entry authDatabase,
  required String accessToken,
}){
  DbObject? account = _getAccountUsingAccessToken(
    authDatabase: authDatabase, 
    accessToken: accessToken,
  );
  if(account == null){
    return false;
  }else{
    return true;
  }
}
//Get all accounts
List<Map<String,dynamic>> getAllAccounts({
  required Entry authDatabase,
}){
  List<DbObject> storedAccounts = _getStoredAccounts(authDatabase: authDatabase);
  List<Map<String,dynamic>> accountsWithContents = [];
  for(DbObject storedAccount in storedAccounts){
    accountsWithContents.add(storedAccount.view());
  }
  return accountsWithContents;
}
//Find single account
Map<String,dynamic> getSingleAccount({
  required Entry authDatabase,
  required String username,
}){
  List<Map<String,dynamic>> allAccounts = getAllAccounts(authDatabase: authDatabase);
  for(Map<String,dynamic> account in allAccounts){
    if(account["username"] == username){
      return account;
    }
  }
  throw "No account matching $username found.";
}
//Add custom text field
String addCustomField({
  required Entry authDatabase,
  required String username,
  required String customFieldName,
  required dynamic customFieldValue,
}){
  DbObject? account = _getAccount(
    authDatabase: authDatabase, 
    username: username,
  );
  if(account == null){
    throw "No account found asociated with the username $username.";
  }else{
    if(customFieldName == "roles" || customFieldName == "password" || customFieldName == "username" || customFieldName == "accessTokens"){
      throw "$customFieldName cannot be overriden";
    }else{
      account.insert(
        key: customFieldName,
        value: customFieldValue,
      );
      return "Added $customFieldName succesfully.";
    }
  }
}