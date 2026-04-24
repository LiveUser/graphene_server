# 0.1.8+19
- Attempt to fight CORS and work with Ngrok

# 0.1.7+18
- isolateVariables was added to startServer to pass variable values to the isolates (because everything is in another thread)

# 0.1.5+16
- Should now support CORS

# 0.1.4+15
- Can now handle Get requests easily

## 0.1.3+14
- Data return fix. Was returning a string instead of bytes

## 0.1.2+13
- Updated dependency on objective_db
- BSON for recieving and sending data

## 0.1.0+11
- Added the getAllAccounts function

## 0.0.9+10
- Has role function now uses access token instead of username

## 0.0.5+5
- All responses coming out of the server will now be in the form of:
{
    "data": response
}
## 0.0.4+4
- Updated the documentation (removed the schema part as it is not supported and no plans to support it are in plans)

## 0.0.3+3
- Simple authentication system created

## 0.0.2+2
- Server is now multi-threaded thanks to the compute(https://pub.dev/packages/compute) package I found online.

## 0.0.1+1
- Basic functionality added