"use strict";

exports.handler = async function(event, context, callback) {
  console.log(JSON.parse(event.body));
  var rmtrAccountNo = JSON.parse(event.body).validate.rmtr_account_no;
  var response = {};
  if (rmtrAccountNo === "123456780") {
    response = {
      statusCode: 400,
      headers: {
        "Content-Type": "text/html; charset=utf-8"
      }
    };
  } else if (rmtrAccountNo === "123456781") {
    response = {
      statusCode: 401,
      headers: {
        "Content-Type": "text/html; charset=utf-8"
      }
    };
  } else if (rmtrAccountNo === "123456782") {
    response = {
      statusCode: 500,
      headers: {
        "Content-Type": "text/html; charset=utf-8"
      }
    };
  } else if (rmtrAccountNo === "123456783") {
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
  }else if (rmtrAccountNo === "123456784") {
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
  }else if (rmtrAccountNo === "123456785") {
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
  }else{
    response = {
      statusCode: 400,
      headers: {
        "Content-Type": "text/html; charset=utf-8"
      }
    };
  }

  callback(null, response);
};
