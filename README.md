# Graphene Server
A GraphQL inspired server. Hecho en 🇵🇷 por Radamés J. Valentín Reyes

## Major Overhaul
~~~
- This program now sends and recieves data in binary. More speciffically **BSON**. **JSON is no longer the format used.**
- Can now handle Get requests easily
- isolateVariables was added to startServer to pass variable values to the isolates (because everything is in another thread)
~~~
## New
- Switched to BSON file for request and response

## HTTP POST Request body
In BSON format
**Important** This version no longer uses JSON. It now uses **BSON**.
### Query
~~~
{
  "variables": {
    "variable1": 2,
    "variable2": "Hello World"
  },
  "query": "functionName"
}
~~~
### Mutation
~~~
{
  "variables": {
    "variable1": 2,
    "variable2": "Hello World"
  },
  "mutation": "functionName"
}
~~~
## Library use examples
### Dart Server
~~~dart
import 'dart:typed_data';

import 'package:graphene_server/graphene_server.dart';
import 'dart:io';

void main()async{
  String message = "Hello World";

  await startServer(
    server: await HttpServer.bind(InternetAddress.loopbackIPv4, 8080),
    getHandler: GetHandler(
      handler: (arguments)async{
        return Uint8List.fromList(arguments["path"].codeUnits);
      },
    ),
    query: GrapheneQuery(
      resolver: {
        "helloWorld": (arguments)async{
          return {
            "message": message,
          };
        },
      },
    ),
    mutations: GrapheneMutation(
      resolver: {
        "helloWorld": (arguments)async{
          message = arguments["newMessage"];
          return {
            "message": message,
          };
        },
      },
    ),
  );
}
~~~
### Dart request example
Pass an empty BSON. <br> Request method is always of type POST. <br/>
Request body example below. Request body must always be of type JSON.

#### Request URL
Always send the requests to your ip:port/graphene
~~~
http://localhost:5432/graphene
~~~
#### Request Body
~~~bson
{
  "variables": {
    "newMessage": "New Message"
  },
  "mutation": "helloWorld"
}
~~~

## Authentication
A simple authentication system that stores user accounts in the designated authDatabase folder by making use of objective_db. Here simple auth functions are provided to streamline the creation of servers that require such functionality.

### Import authentication functions
~~~dart
import 'package:graphene_server/auth.dart';
~~~
- Create account
~~~dart
createAccount(
  authDatabase: authDatabase,
  username: "valentin.radames@gmail.com",
  password: "12345",
);
~~~
- Login
~~~dart
String accessToken = login(
  authDatabase: authDatabase, 
  username: "valentin.radames@gmail.com", 
  password: "12345",
);
~~~
- Logout
~~~dart
logout(
  authDatabase: authDatabase, 
  accessToken: accessToken,
);
~~~
- Token is valid
~~~dart
bool validToken =  tokenIsValid(
  authDatabase: authDatabase, 
  accessToken: accessToken,
);
~~~
- Update password
~~~dart
updatePassword(
  authDatabase: authDatabase, 
  username: "valentin.radames@gmail.com", 
  password: "12345", 
  newPassword: "012345",
);
~~~
- Add role
~~~dart
addRole(
  authDatabase: authDatabase, 
  username: "valentin.radames@gmail.com", 
  role: "Admin",
);
~~~
- Remove role
~~~dart
removeRole(
  authDatabase: authDatabase, 
  username: "valentin.radames@gmail.com", 
  role: "Admin",
);
~~~
- Has Role
~~~dart
bool itHasRole = hasRole(
  authDatabase: authDatabase, 
  accessToken: accessToken,
  role: "Admin",
);
~~~
- Delete Account
~~~dart
deleteAccount(
  authDatabase: authDatabase, 
  username: "valentin.radames@gmail.com",
);
~~~
- Add custom field
~~~dart
addCustomField(
  authDatabase: authDatabase, 
  username: "valentin.radames@gmail.com", 
  customFieldName: "typeOfAnimal",
  customFieldValue: "Human",
);
~~~
- Get all stored accounts
~~~dart
List<Map<String,dynamic>> allAccounts = getAllAccounts(authDatabase: authDatabase);
print(allAccounts);
~~~
- Get single stored account
~~~dart
Map<String,dynamic> updatedAccount = getSingleAccount(
  authDatabase: authDatabase, 
  username: "valentin.radames@gmail.com",
);
~~~
------------------------------------------------------------

## Contribute/donate by tapping on the Pay Pal logo/image

<a href="https://www.paypal.com/paypalme/onlinespawn"><img src="https://www.paypalobjects.com/webstatic/mktg/logo/pp_cc_mark_74x46.jpg"/></a>

------------------------------------------------------------