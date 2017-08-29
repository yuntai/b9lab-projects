const Http = require("http");
const Url = require("url");
const prepared = require("./prepare.js");
const EthUtil = require("ethereumjs-util");

//require("./prepare.js");

function serverError(err, response) {
	response.writeHeader(500, {"Content-Type": "text/plain"});
	response.write(err.toString());
	response.end();
}

function invalidMethod(response) {
	response.writeHeader(405);
	response.end();
}

function notFound(err, response) {
	console.log("not found....");
	response.writeHeader(404, {"Content-Type": "text/plain"});
	response.write(err.toString());
	response.end();
}

function badRequest(err, response) {
	response.writeHeader(400, {"Content-Type": "text/plain"});
	response.write(err.toString());
	response.end();
}

Http.createServer(function(request, response) {
  //console.log(request.url);
  var pathname = Url.parse(request.url).pathname;

  if(request.method == "GET") {
    if(pathname.startsWith("/balance/")) {
      var who = pathname.slice(9,51);
      if(!EthUtil.isValidAddress(who)) {
        badRequest(who + " is not a valid address", response);
      } else {
        prepared.MetaCoin.deployed()
          .then(instance => instance.getBalance.call(who))
          .then(balance => {
             //response.setHeader("Content-Type", "application/json; charset=UTF-8");
             response.writeHead(200, {"Content-Type": "application/json; charset=UTF-8"});
	     /*
             response.write(JSON.stringify({
               "address": who,
               "balance": balance.toString(10)
             }) + '\n', function(err) { response.end(); });
	     */
             var body = JSON.stringify({
               "address": who,
               "balance": balance.toString(10)
             }) + '\n';
	     console.log("body:",body);
	     response.write(body);
             response.end();
	  })
          .catch(err => {
		  console.log("ERRROR!!!!!!!", err);
		  serverError(response, err)
	  });
      } 
    }
    else if(pathname.startsWith("/tx/")) {
      var txHash = pathname.slice(4, 70);
      web3.eth.getTransaction(txHash, function(err, tx) {
        if(err) {
          serverError(err, response);
        } else if (tx == null) {
          notFound(txHash + " is not a known transaction", response);
        } else {
          response.writeHeader(200, {"Content-Type": "application/json"});
          response.write(JSON.stringify(tx) + '\n');
          response.end();
        }
      });
     } else {
			notFound("", response);
		}
	} else {
		invalidMethod(response);
	}
}).listen(8080);

