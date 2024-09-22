import Server "mo:server";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Text "mo:base/Text";

shared ({ caller = creator }) actor class () {
  type Request = Server.Request;
  type Response = Server.Response;
  type HttpRequest = Server.HttpRequest;
  type HttpResponse = Server.HttpResponse;
  type ResponseClass = Server.ResponseClass;

  stable var serializedEntries : Server.SerializedEntries = ([], [], [creator]);
  stable var urls = Array.init<Text>(10, "");

  public shared (msg) func set(i : Nat, t : Text) {
    if (msg.caller != creator) Debug.trap("not allowed");
    urls[i] := t;
    server.get(
      "/.well-known/ii-alternative-origins",
      func(_ : Request, res : ResponseClass) : async Response {
        res.json({
          status_code = 200;
          // headers = [("Content-Type", "text/plain")];
          body = json();
          cache_strategy = #default;
          // streaming_strategy = null;
        });
      },
    );
  };

  public query func get() : async [Text] {
    Array.freeze(urls);
  };

  let server = Server.Server({ serializedEntries });

  let json = func() : Text {
    var str = "{ \"alternativeOrigins\": [\n";
    var firstLine = true;
    for (s in urls.vals()) {
      if (s != "") {
        if (not firstLine) str #= ",\n";
        firstLine := false;
        str #= "  \"" # s # "\"";
      };
    };
    if (not firstLine) str #= "\n";
    str #= "] }";
    str
  };

  server.get(
    "/.well-known/ii-alternative-origins",
    func(_ : Request, res : ResponseClass) : async Response {
      res.json({
        status_code = 200;
        // headers = [("Content-Type", "text/plain")];
        body = json();
        cache_strategy = #default;
        // streaming_strategy = null;
      });
    },
  );

  // Bind the server to the HTTP interface
  public query func http_request(req : HttpRequest) : async HttpResponse {
    server.http_request(req);
  };
  public func http_request_update(req : HttpRequest) : async HttpResponse {
    await server.http_request_update(req);
  };

  public func invalidate_cache() : async () {
    server.empty_cache();
  };

  system func preupgrade() {
    serializedEntries := server.entries();
  };

  system func postupgrade() {
    ignore server.cache.pruneAll();
    server.empty_cache();
  };
};
