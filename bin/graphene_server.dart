import 'dart:convert';
import 'dart:typed_data';
import 'package:graphene_server/graphene_server.dart';
import 'dart:io';

import 'package:mimalo/mimalo.dart';

void main()async{
  String message = "Hello World";

  await startServer(
    server: await HttpServer.bind(InternetAddress.loopbackIPv4, 8080),
    getHandler: GetHandler(
      handler: (arguments)async{
        return GetResponse(
          bytes: Uint8List.fromList(utf8.encode("Hello World")),
          mimeType: mimalo(filePathOrExtension: ".html")
        );
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
    redirectHandler: (variables){
      return Redirect(
        mimeType: "text/plain",
        url: variables["url"],
      );
    },
  );
}