@istest
public class SyncEventsToBitpodHandlerTest {
  
   static testMethod void  updateMethodTest(){
       Event__c event = TestDataFactory.createEvent();    
                  
        event.Venue_name__c= 'kpit';
        event.City__c = 'Pune12';
        event.State__c = 'Maharashtra';
        event.Zip_Code__c = '431112';
        event.Street__c = 'Hinjewadi';
        event.Country__c = 'India'; 
        event.End_Date__c= date.today() + 15;
        update event; 
        
        Event_ticket__c  ticket = TestDataFactory.createTicket();      
        Bitpod_Credentials__c bitpod_con_obj = TestDataFactory.bitpodConfiguration(); 
                
        Test.startTest();    
            Test.setMock(HttpCalloutMock.class, new MockBitpodEventsResponse());  
            System.assertEquals(event.Venue_name__c,'kpit');
        Test.stopTest();

   }
   
   static testMethod void  deleteMethodTest(){
        Event__c event = TestDataFactory.createEvent();    
        Event_ticket__c  ticket = TestDataFactory.createTicket();      
        Bitpod_Credentials__c bitpod_con_obj = TestDataFactory.bitpodConfiguration();      
        
        ContentVersion cv = TestDataFactory.createContentVersion();
              
        List<ContentDocument> cdList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
                       
        delete ticket;
        if(cdList.size() > 0)
        delete cdList;
        delete event;
                          
   
        Test.startTest();    
            Test.setMock(HttpCalloutMock.class, new MockBitpodEventsResponse());
            System.assertEquals(event.Name,'event1');
        Test.stopTest();

   } 
   
   static testMethod void  awsMethodTest() 
    {
    
        String xml = ''
                + '<?xml version="1.0" encoding="UTF-8"?>'
                + '<DiscountCode>'
                + '<code name="code1"> Code1</code>'
                + '<code name="code2"> Code2</code>'
                + '</DiscountCode>'
                ;

        // Parses XML
        Dom.Document doc = new DOM.Document();        
        doc.load(xml);      
        dom.XmlNode xroot = doc.getRootElement();    
        Boolean b1 = AWS.getChildNodeBoolean(xroot ,'1', 'Code1');
        DateTime d1 = AWS.getChildNodeDateTime(xroot ,'1', 'Code1');
        Integer d2 = AWS.getChildNodeInteger(xroot ,'1', 'Code1');
        String d3 = AWS.getChildNodeText(xroot ,'1', 'Code1');
        
        AWS.ServiceException serExc = new AWS.ServiceException(xroot);
        Test.startTest();      
            System.assertEquals(d3,null);
        Test.stopTest();        
    } 
}