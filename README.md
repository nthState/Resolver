# Resolver
Dependency Injection for RealCode &amp; UI Tests

    public protocol WebServiceProtocol
    {
        func myWebMethod()
    }

    public class WebService : NSObject, WebServiceProtocol
    {
        func myWebMethod() {}
    }

    public class TestWebService : NSObject, WebServiceProtocol
    {
        func myWebMethod() {}
    }

    class MyService : NSObject
    {
        var webService:WebServiceProtocol!
        func satisfy()
        {
            webService = Resolver.Resolve("WebService")
        }
    
        override init()
        {
            super.init()
            satisfy()
        }
    }
