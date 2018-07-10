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