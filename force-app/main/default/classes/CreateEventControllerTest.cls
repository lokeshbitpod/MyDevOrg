@istest
public class CreateEventControllerTest {
    public static string response;
    public static string userResponse;
    public static string eventResponse;
    public static string configResponse;
    
    public class EventWrapper{          
        public string message {get;set;}
        public Boolean isSuccess {get;set;}     
        public string status {get;set;}
        public Boolean isSync {get;set;}     
    }
    
    public class UserWrapper{       
        public string currencyCode {get;set;}
        public string timezone {get;set;}       
    }

    public class ConfigWrapper{       
        public string apiurl {get;set;}
        public string accesskey {get;set;} 
        public string secretkey {get;set;} 
    }    
    
            
    static testMethod void  insertMethodTest(){   
        Event__c event = TestDataFactory.eventTestData();    
        Event_ticket__c  ticket = TestDataFactory.ticketTestData();   
                
        List<Event_ticket__c> ticketList = new List<Event_ticket__c>();
        ticketList.add(ticket);        
        
        Bitpod_Credentials__c bitpod_con_obj = TestDataFactory.bitpodConfiguration(); 
   
        Test.startTest();        
            Test.setMock(HttpCalloutMock.class, new MockBitpodEventsResponse());
            CreateEventController createEventCntrl = new CreateEventController();
            string response = CreateEventController.createEvent(event,ticketList);
            // added assertion    
            EventWrapper wrapObj = (EventWrapper)JSON.deserialize(response, EventWrapper.class);                      
            System.assertEquals(wrapObj.isSuccess,true);
            System.assertEquals(wrapObj.message,'Event created successfully.');
            
        Test.stopTest();

   }
   
   static testMethod void  insertMethodTest2(){     
         Event__c event = TestDataFactory.eventTestData();    
                
         Event_ticket__c ticket = new Event_ticket__c();
         ticket.Name = 'ticket1';                 
         List<Event_ticket__c> ticketList = new List<Event_ticket__c>();
         ticketList.add(ticket);        
             
         Bitpod_Credentials__c bitpod_con_obj = TestDataFactory.bitpodConfiguration(); 
   
     Test.startTest();
    
         Test.setMock(HttpCalloutMock.class, new MockBitpodEventsResponse());
         CreateEventController createEventCntrl = new CreateEventController();
         
         string apiurl = 'https://eventwnnwx.test.bitpod.io';
         string accesskey = 'ef7ae4e25d51753a878510fb7f5af616e7485d97d77c688759b6d225978324a2';
         string secretkey = 'e4865ddb2bbb37875b1ab9704199232459ca9eb9fc1f6b3436f9d565a1542787';
         Boolean isDataSeeded = CreateEventController.getEventCount(apiurl,accesskey,secretkey);
       
         response = CreateEventController.createEvent(event,ticketList);
         EventWrapper wrapObj = (EventWrapper)JSON.deserialize(response, EventWrapper.class);               
         System.assertEquals(wrapObj.isSuccess,false);
              
         userResponse = CreateEventController.getCurrentUserAndEventDate();           
         UserWrapper userWrapObj = (UserWrapper)JSON.deserialize(userResponse, UserWrapper.class);               
         System.assertEquals(userWrapObj.timezone,UserInfo.getTimeZone().getDisplayName());
         
         Event__c event2 = TestDataFactory.createEvent2();        
            
         eventResponse = CreateEventController.getEvent(event2.id);
         EventWrapper wrapObj2 = (EventWrapper)JSON.deserialize(eventResponse, EventWrapper.class);        
         System.assertEquals(wrapObj2.isSync,false);
      
         configResponse = CreateEventController.getBitpodCredentials();
         ConfigWrapper configWrap = (ConfigWrapper)JSON.deserialize(configResponse, ConfigWrapper.class); 
         System.assertEquals(configWrap.apiurl,'https://eventwnnwx.test.bitpod.io');
                        
    Test.stopTest();

   } 
}