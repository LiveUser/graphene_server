import 'package:test/test.dart';
import 'package:graphene_server/auth.dart';
import 'package:objective_db/objective_db.dart';

void main() {
  Entry authDatabase = Entry(dbPath: "./database/auth");
  test("Create account", ()async{
    createAccount(
      authDatabase: authDatabase,
      username: "valentin.radames@gmail.com",
      password: "12345",
    );
  });
  test("Multiple operations", ()async{
    String accessToken = login(
      authDatabase: authDatabase, 
      username: "valentin.radames@gmail.com", 
      password: "12345",
    );
    print("Access token: $accessToken");
    updatePassword(
      authDatabase: authDatabase, 
      username: "valentin.radames@gmail.com", 
      password: "12345", 
      newPassword: "012345",
    );
    addRole(
      authDatabase: authDatabase, 
      username: "valentin.radames@gmail.com", 
      role: "Admin",
    );
    bool itHasRole = hasRole(
      authDatabase: authDatabase, 
      accessToken: accessToken,
      role: "Admin",
    );
    print("It has role $itHasRole");
    removeRole(
      authDatabase: authDatabase, 
      username: "valentin.radames@gmail.com", 
      role: "Admin",
    );
    bool validToken =  tokenIsValid(
      authDatabase: authDatabase, 
      accessToken: accessToken,
    );
    print("Token is valid: $validToken");
    logout(
      authDatabase: authDatabase, 
      accessToken: accessToken,
    );
  });
  test("Delete account", (){
    deleteAccount(
      authDatabase: authDatabase, 
      username: "valentin.radames@gmail.com",
    );
  });
  test("Display all accounts", (){
    List<Map<String,dynamic>> allAccounts = getAllAccounts(authDatabase: authDatabase);
    print(allAccounts);
  });
  test("Get single account and add and view custom text fields.", (){
    addCustomField(
      authDatabase: authDatabase, 
      username: "valentin.radames@gmail.com", 
      customFieldName: "typeOfAnimal",
      customFieldValue: "Human",
    );
    Map<String,dynamic> updatedAccount = getSingleAccount(
      authDatabase: authDatabase, 
      username: "valentin.radames@gmail.com",
    );
    print(updatedAccount);
  });
}
