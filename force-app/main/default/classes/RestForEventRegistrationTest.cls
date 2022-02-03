@istest
public class RestForEventRegistrationTest{

    static testMethod void  insertMethodTest(){  
        Event__c event = TestDataFactory.createEvent();    
        Event_ticket__c  ticket = TestDataFactory.createTicket();                  
      
      
        String eventId = event.id;        
        String ticketId = ticket.id;
        
    
        String jsonInput2 = '{' +
        
        '"Attendee":[{' +  
            '"_CurrentAddress":{' +
            '"AddressLine": "wtc", '+
            '"City": "pune", '+
            '"Country": "india", '+
            '"PostalCode": "431112", '+
            '"State": "mh" '+'},'  +                         
            '"CompanyName": "dsfdsfsdsd", '+
            '"Email": "xcvxcv@dsf.dfs",'+
            '"FirstName": "vxcv",'+             
            '"LastName": "xcvxcv",'+
            '"Salutation": "Mr."'+    
         '}],'+ 
         
        '"Registration":{' +
        '"EventId":' + '"' + eventId + '"'+','  +
        '"TicketId":[' + '"' + ticketId + '"'+'],'  +      
        '"_CurrentAddress":{' +
        '"AddressLine": "wtc", '+
        '"City": "pune", '+
        '"Country": "india", '+
        '"PostalCode": "431112", '+
        '"State": "mh" '+'},'  +               
        '"CompanyName": "dsfdsfsdsd", '+
        '"Email": "xcvxcv@dsf.dfs",'+
        '"FirstName": "vxcv",'+
        '"Title": "fsdfdsfs",'+
        '"TotalAmount": 200,'+
        '"LastName": "xcvxcv",'+
        '"Salutation": "Mr.",'+    
        '"CurrencyName": "EUR"'+ 
        '}'+
         
         
         
        '}';

        RestForEventRegistration reqst=new RestForEventRegistration();
         
        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            
            req.requestURI = 'https://bitpod-dev-ed.my.salesforce.com/services/apexrest/eventbriteforce/EventRegistration';  //Request URL
            req.httpMethod = 'POST';//HTTP Request Type
            req.requestBody = Blob.valueof(jsonInput2);
            RestContext.request = req;
            RestContext.response= res;
            Test.setMock(HttpCalloutMock.class, new MockBitpodEventsResponse());
            RestForEventRegistration.doPost();
            jsonInput2 = '';
            req.requestBody = Blob.valueof(jsonInput2);
            string response = RestForEventRegistration.doPost();
            System.AssertNotEquals(response, null);
        
        Test.stopTest();

   }
}