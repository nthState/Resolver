# Resolver
Dependency Injection for RealCode &amp; UI Tests

```
    public protocol WebServiceProtocol {
        func myWebMethod()
    }

    public class WebService : WebServiceProtocol {
        func myWebMethod() {}
    }

    public class TestWebService : WebServiceProtocol {
        func myWebMethod() {}
    }

    class MyService {
    
        var webService:WebServiceProtocol!
        
        func satisfyDependencies() {
            webService = Resolver.Resolve("WebService")
        }
    
        init() {
            satisfyDependencies()
        }
    }
```

```
let networkService = TestWebService()
let httpResponse = HTTPURLResponse(url: URL(string: "z")!, statusCode: 404, httpVersion: nil, headerFields: nil)
networkService.addResponse(for: "/login", response:dataToReturn, httpResponse:httpResponse, error:nil)

let launchArgument = Resolver.DataForObjects(networkService)

let app = XCUIApplication()
app.launchEnvironment = ["UITEST":"true"]
app.launchArguments = [Resolver_test_argument, launchArgument]
app.launch()
```