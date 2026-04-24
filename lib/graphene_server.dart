library graphene_server;

import 'dart:io';
import 'dart:typed_data';
import 'package:compute/compute.dart';
import 'package:bson/bson.dart';
import 'package:mimalo/mimalo.dart';

//Types
class GetHandler{
  GetHandler({
    required this.handler,
  });
  final Future<Uint8List> Function(String path) handler;
}
class GrapheneQuery {
  GrapheneQuery({
    required this.resolver,
  });
  final Map<String, Future<dynamic> Function(Map<String,dynamic> arguments)> resolver;
}
class GrapheneMutation {
  GrapheneMutation({
    required this.resolver,
  });
  final Map<String, Future<dynamic> Function(Map<String,dynamic> arguments)> resolver;
}
//Functions

//Server
Future<void> startServer({
  required HttpServer server,
  required GetHandler getHandler,
  required GrapheneQuery query,
  required GrapheneMutation mutations,
  Map<String,dynamic>? isolateVariables,
})async{
  //URL in which the server is running
  print("http://${server.address.address}:${server.port}");
  //Handle all of the incoming requests
  await server.forEach((HttpRequest request)async{
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, ngrok-skip-browser-warning');
    request.response.headers.set('Access-Control-Expose-Headers', 'Content-Length');
    //Handle Get requests
    if (request.method == "OPTIONS") {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
    }else if(request.method == "GET"){
      try{
        try{
          request.response.headers.set('Content-Type', mimalo(filePathOrExtension: request.requestedUri.path));
        }catch(error){
          request.response.headers.set('Content-Type', "application/octet-stream");
        }
        request.response.add(await compute(getHandler.handler,request.requestedUri.path));
        await request.response.close();
      }catch(err){
        request.response.headers.contentType = ContentType.text;
        request.response.write(err.toString());
        await request.response.close();
      }
    }else if(request.requestedUri.path == "/graphene" && request.method == "POST"){
      try{
        //Reconstruct and parse request body
        final BytesBuilder builder = BytesBuilder();
        await for (var chunk in request) {
          builder.add(chunk);
        }
        Uint8List requestBody = builder.takeBytes();
        Map<String,dynamic> parsedRequest = BsonCodec.deserialize(BsonBinary.from(requestBody));
        //Handle request
        dynamic responseData;
        Map<String,dynamic> variables = parsedRequest["variables"];
        if(isolateVariables != null){
          variables.addAll(isolateVariables);
        }
        if(parsedRequest["query"] != null){
          responseData = (await compute(query.resolver[parsedRequest["query"]]!, variables));
        }else if(parsedRequest["mutation"] != null){
          responseData = (await compute(mutations.resolver[parsedRequest["mutation"]]!, variables));
        }else{
          Map<String,dynamic> error = {
            "error": "No query or mutation found",
          };
          responseData = error;
        }
        //Generate a response
        request.response.add(BsonCodec.serialize({
          "data": responseData,
        }).byteList);
        await request.response.close();
      }catch(err){
        Map<String,dynamic> error = {
          "error": err is String ? err : err.toString(),
        };
        request.response.add(BsonCodec.serialize(error).byteList);
        await request.response.close();
      }
    }else{
      //Return an error
      Map<String,dynamic> error = {
        "error": "Invalid Request",
      };
      request.response.add(BsonCodec.serialize(error).byteList);
      await request.response.close();
    }
  });
}