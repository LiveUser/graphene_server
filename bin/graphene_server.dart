import 'package:graphene_server/graphene_server.dart';
import 'dart:io';

void main()async{
  String message = "Hello World";

  await startServer(
    server: await HttpServer.bind(InternetAddress.loopbackIPv4, 8080),
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