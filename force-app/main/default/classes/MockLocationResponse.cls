@isTest
global class MockLocationResponse implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {               
        if(!req.getEndpoint().contains('googleapis'))
        {           
            if(req.getMethod() == 'GET')                
                System.assertEquals('GET', req.getMethod());
        }
              
        // Create a fake response
        HttpResponse res = new HttpResponse();
        if(req.getEndpoint().contains('googleapis')){        
            res.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            res.setBody('{"results":[{"geometry":{"location":{"lat": 111.0,"lng":94494}}}]}');
            res.setStatusCode(200);
        }  
        
        return res;
    }
}