library graphene_server;

import 'dart:io';
import 'dart:typed_data';
import 'package:compute/compute.dart';
import 'package:bson/bson.dart';

//Types
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
  required GrapheneQuery query,
  required GrapheneMutation mutations,
})async{
  //URL in which the server is running
  print("http://${server.address.address}:${server.port}");
  //Handle all of the incoming requests
  await server.forEach((HttpRequest request)async{
    if(request.requestedUri.path == "/graphene" && request.method == "POST"){
      try{
        //Reconstruct and parse request body
        final BytesBuilder builder = BytesBuilder();
        await for (var chunk in request) {
          builder.add(chunk);
        }
        Uint8List requestBody = builder.takeBytes();
        Map<String,dynamic> parsedRequest = BsonCodec.deserialize(BsonBinary.from(requestBody));
        //Handle request
        Map<String,dynamic> responseData;
        if(parsedRequest["query"] != null){
          responseData = (await compute(query.resolver[parsedRequest["query"]]!, parsedRequest["variables"] as Map<String,dynamic>)) as Map<String,dynamic>;
        }else if(parsedRequest["mutation"] != null){
          responseData = (await compute(mutations.resolver[parsedRequest["mutation"]]!, parsedRequest["variables"] as Map<String,dynamic>)) as Map<String,dynamic>;
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
      request.response.close();
    }
  });
}