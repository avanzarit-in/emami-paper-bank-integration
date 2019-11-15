"use strict";

exports.handler = async function(event, context, callback) {
  console.log(JSON.parse(event.body));
  var transferUniqueNumber = JSON.parse(event.body).validate.transfer_unique_no;
  var response = {};
  if (transferUniqueNumber === "N01234567890") {
    response = {
      statusCode: 400,
      headers: {
        "Content-Type": "text/html; charset=utf-8"
      }
    };
  } else if (transferUniqueNumber === "N01234567891") {
    response = {
      statusCode: 401,
      headers: {
        "Content-Type": "text/html; charset=utf-8"
      }
    };
  } else if (transferUniqueNumber === "N01234567892") {
    response = {
      statusCode: 500,
      headers: {
        "Content-Type": "text/html; charset=utf-8"
      }
    };
  } else if (transferUniqueNumber === "N01234567893") {
    response = {
      statusCode: 200,
      headers: {
        "Content-Type": "text/html; charset=utf-8"
      },
      body: JSON.stringify({
        validateResponse: {
          decision: "pending"
        }
      })
    };
  }else if (transferUniqueNumber === "N01234567894") {
    response = {
      statusCode: 200,
      headers: {
        "Content-Type": "text/html; charset=utf-8"
      },
      body: JSON.stringify({
        validateResponse: {
          decision: "pass"
        }
      })
    };
  }else if (transferUniqueNumber === "N01234567895") {
    response = {
      statusCode: 200,
      headers: {
        "Content-Type": "text/html; charset=utf-8"
      },
      body: JSON.stringify({
        validateResponse: {
          decision: "reject"
        }
      })
    };
  }

  callback(null, response);
};
