@isTest
global class MockBitpodEventsResponse implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {               
        Bitpod_Credentials__c bitpod_con_obj = new Bitpod_Credentials__c();         
        bitpod_con_obj.Access_Key__c = 'ef7ae4e25d51753a878510fb7f5af616e7485d97d77c688759b6d225978324a2';
        bitpod_con_obj.Secret_Key__c= 'e4865ddb2bbb37875b1ab9704199232459ca9eb9fc1f6b3436f9d565a1542787';
        bitpod_con_obj.Event_Resource__c= '/svc/api/Events';
        bitpod_con_obj.Endpoint__c = 'https://eventwnnwx.test.bitpod.io';
        bitpod_con_obj.Access_Key__c = '';
        bitpod_con_obj.Access_Key__c = '';
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        if(req.getEndpoint().contains('events')){        
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Name":"test"}');
            res.setStatusCode(200);
        }  
        if(req.getEndpoint().contains('tickets')){        
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Name":"test"}');
            res.setStatusCode(200);
        } 
        if(req.getEndpoint().contains('attachments')){        
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Name":"test"}');
            res.setStatusCode(204);
        }     
        return res;
    }
}