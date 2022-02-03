@istest
public class BitpodPublishTest {
    public static string response;
    public static Boolean status;
    public class EventWrapper{
        public boolean BitpodConfigStatus{get;set;}
    }
    
    static testMethod void publishMethodTest(){  
        Event__c event = TestDataFactory.createEvent();  
        Event_ticket__c  ticket = TestDataFactory.createTicket();      
        Bitpod_Credentials__c bitpod_con_obj = TestDataFactory.bitpodConfiguration(); 
      //  ContentVersion cv = TestDataFactory.createContentVersion();
                                   
         ContentVersion cv=new Contentversion();
         cv.title='ABC';      
         Blob b=Blob.valueOf('This is version data');
         cv.versiondata=b;
         cv.PathOnClient = 'image1.jpg';
         cv.Is_Sync__c = true;
         cv.FirstPublishLocationId = event.id;
         insert cv; 
         
         List<ContentDocument> cdList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];                    
        
   
        Test.startTest();    
             Test.setMock(HttpCalloutMock.class, new MockBitpodEventsResponse());           
             response = BitpodPublish.publish(event.id,'Event__c');
             BitpodPublish.publishTickets(event.id,'Event_ticket__c ');
             BitpodPublish.updateGeolocationToBitpod(event.id);
             
             BitpodPublish.CommonWrapper wrapObj = new BitpodPublish.CommonWrapper();
             wrapObj.id = event.id;
             BitpodPublish.eventWrapList = new List<BitpodPublish.CommonWrapper>();
             BitpodPublish.eventWrapList.add(wrapObj);
             status = BitpodPublish.updatePublishStatus(BitpodPublish.eventWrapList,'Event__c');
             System.assertEquals(status,true);
        
             BitpodPublish.CommonWrapper wrapObj2 = new BitpodPublish.CommonWrapper();
             wrapObj2.id = ticket.id;
             BitpodPublish.ticketWrapList= new List<BitpodPublish.CommonWrapper>();
             BitpodPublish.ticketWrapList.add(wrapObj2);
             status = BitpodPublish.updatePublishStatus(BitpodPublish.ticketWrapList,'Event_ticket__c');
             System.assertEquals(status,true);
        
             BitpodPublish.CommonWrapper wrapObj3 = new BitpodPublish.CommonWrapper();
             wrapObj3.id = ticket.id;
             BitpodPublish.imageWrapList= new List<BitpodPublish.CommonWrapper>();
             BitpodPublish.imageWrapList.add(wrapObj3);
             status = BitpodPublish.updatePublishStatus(BitpodPublish.imageWrapList,'ContentVersion');
             System.assertEquals(status,true);
        Test.stopTest();

   }
   
   static testMethod void  publishMethodTest2(){  
         Event__c event = TestDataFactory.createEvent();  
      //  Event_ticket__c  ticket = TestDataFactory.createTicket();      
         Bitpod_Credentials__c bitpod_con_obj = TestDataFactory.bitpodConfiguration();          
        
                       
         Event_ticket__c ticket = new Event_ticket__c();
         ticket.Name = 'ticket1';
         ticket.type__c= 'Free';
         ticket.Event__c = event.id;
         ticket.Is_Sync__c = true;
         ticket.Start_Date__c = date.today();
         ticket.End_Date__c= date.today() + 5;         
         insert ticket;            
        
         
         List<ContentDocument> cdList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];                   
             
           
        Test.startTest();    
             Test.setMock(HttpCalloutMock.class, new MockBitpodEventsResponse());           
             response = BitpodPublish.publish(event.id,'Event__c');
             ticket.Publish_Date__c = date.today();  
             update ticket;
             Test.setMock(HttpCalloutMock.class, new MockBitpodEventsResponse());           
             response = BitpodPublish.publish(event.id,'Event__c');
             EventWrapper eventWrapObj = (EventWrapper)JSON.deserialize(response, EventWrapper.class);               
             System.assertEquals(eventWrapObj.BitpodConfigStatus,true);
       
             BitpodPublish.publishTickets(event.id,'Event_ticket__c ');
             BitpodPublish.publishTicketsToBitpod(event.id);
             delete ticket;
             response = BitpodPublish.publish(event.id,'Event__c');
             EventWrapper eventWrapObj2 = (EventWrapper)JSON.deserialize(response, EventWrapper.class);               
             System.assertEquals(eventWrapObj2.BitpodConfigStatus,true);
       
        Test.stopTest();

   } 
   
   static testMethod void  publishMethodTest3(){  
      //  Event__c event = TestDataFactory.createEvent();  
      //  Event_ticket__c  ticket = TestDataFactory.createTicket();      
         Bitpod_Credentials__c bitpod_con_obj = TestDataFactory.bitpodConfiguration();                        
       
         Event__c event = new Event__c();
         event.Name = 'event1';
         event.Start_Date__c = date.today() + 5;
         event.End_Date__c= date.today() + 14; 
         event.Description__c= 'wtc';        
         event.Capture_Point__c= 'Salesforce';
         event.Venue_name__c= 'wtc';
         event.City__c = 'pune';
         event.State__c = 'mh';
         event.Zip_Code__c= '431110';
         event.Street__c = '201';
         event.Country__c = 'india';
         event.Timezone__c= '(GMT-08:00) Pacific Standard Time (America/Los_Angeles)';         
         insert event;    
         
         Event_ticket__c ticket = new Event_ticket__c();
         ticket.Name = 'ticket1';
         ticket.type__c= 'Free';
         ticket.Event__c = event.id;
         ticket.Is_Sync__c = true;
         ticket.Start_Date__c = date.today();
         ticket.End_Date__c= date.today() + 5;         
         insert ticket;            
                
        Test.startTest();    
             Test.setMock(HttpCalloutMock.class, new MockBitpodEventsResponse());           
             response = BitpodPublish.publish(event.id,'Event__c');
             response = BitpodPublish.publish(event.id,'Event__c');
             BitpodPublish.publishEvents(event.id,'Event__c ');
             BitpodPublish.publishTickets(event.id,'Event_ticket__c ');
             boolean isReady = BitpodPublish.readyToPublish(event.id,'Event_ticket__c');
             System.assertEquals(isReady,true);
        Test.stopTest();

   } 
}