# [SONATA](http://www.sonata-nfv.eu)'s Gatekeeper Rate Limit micro-service
[![Build Status](http://jenkins.sonata-nfv.eu/buildStatus/icon?job=son-gkeeper)](http://jenkins.sonata-nfv.eu/job/son-gkeeper)


This is the folder of the Rate Limiter micro-service. A rate limiter restricts
each client to N requests in a given time span. 


# Rate Limit API
The rate limiter micro-service exposes a RESTful HTTP API that can perform basic
CRUD operations on rate limit definitions, and an endpoint to check resource
usage allowance.


## Create or update a rate limit definition
```
PUT /limits/{resource-limit-id}
```

A rate limit establishes how many requests in a time interval a client is
allowed to perform. For example, a client is allowed to perform at maximum 10
requests per hour.

This operation accepts the following parameters:

- **period** - Time sliding window (in seconds) for which the control of maximum
  number of requests is verified. (*required*)
- **limit** - Maximum number of requests that a client is allowed to perform in
  the specified period. (*required*)

### Sample request / response
The following request creates a limit, identified by
"check_account_balance_limit" where a client is allowed to perform a maximum of
10 requests per hour.

```json
PUT /limits/check_account_balance_limit
Content-Type: application/json
{
  "period": 3600,
  "limit": 10
}

-- response
204 No Content
```

This operation can return the following HTTP status codes:
 - 204 No Content - The limit has been created or updated
 - 400 Bad Request - If the request is malformed, i.e., invalid values or missing parameters



## Delete resource limit
``` 
DELETE /limits/{resource-limit-id} 
```

This operation can return the following HTTP status codes:
 - 204 No Content - The limit was deleted 
 - 404 Not Found -  The specified resource limit does not exist.


## Retrieve existing resource limit definitions
``` 
GET /limits 
```
### Sample request / response
```json
GET /limits
-- response
200 OK
Content-Type: application/json
[
  { "id": "other_account_operations", "period": 60, "limit": 100 }, 
  { "id": "create_account", "period": 3600, "limit": 10 },
  { "id": "default", "period": 1, "limit": 10 }
]
```


## Check limit
```
POST /check
```

This operation checks if a client is either allowed or not allowed to perform
the request according to the specified limit. Each call to this endpoint will
consume one request associated to the given client.


### Sample request / response
```json
POST /check
{
  "limit_id": "create_account",
  "client_id": "user_a"
}

-- response

200 Ok
{
  "allowed": true,
  "remaining": 10
}
```
Where the response body attributes:
 * allowed - If the client is allowed to perform the request. This can be either
   *true* or *false*.
 * remaining - Total number of available requests at the current time.

This operation can return the following HTTP status codes:
 - 200 Ok - Request was successfully processed. Client should inspect response
   body in order to check if client is allowed to perform the request.
 - 400 Bad Request - If the specified "limit_id" does not exist or the request
   is malformed




# Running
TODO...

## License
The license of the SONATA Gatekeeper is Apache 2.0 (please see the
[license](https://github.com/sonata-nfv/son-editorgkeeper/blob/master/LICENSE)
file).


#### Feedback-Chanels

Please use the [GitHub issues](https://github.com/sonata-nfv/son-gkeeper/issues)
and the SONATA development mailing list `sonata-dev@lists.atosresearch.eu` for
feedback.

