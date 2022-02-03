@isTest
public class TestDataFactory {
    public static Bitpod_Credentials__c bitpodConfiguration(){
         Bitpod_Credentials__c bitpod_con_obj = new Bitpod_Credentials__c();         
         bitpod_con_obj.Access_Key__c = 'ef7ae4e25d51753a878510fb7f5af616e7485d97d77c688759b6d225978324a2';
         bitpod_con_obj.Secret_Key__c= 'e4865ddb2bbb37875b1ab9704199232459ca9eb9fc1f6b3436f9d565a1542787';
         bitpod_con_obj.Event_Resource__c= '/svc/api/Events';
         bitpod_con_obj.Endpoint__c = 'https://eventwnnwx.test.bitpod.io';
         bitpod_con_obj.EventTicket_Resource__c = '/svc/api/Tickets';
         bitpod_con_obj.Attachment_Resource__c= '/svc/api/Attachments';
         bitpod_con_obj.Speaker_Resource__c= '/svc/api/Speakers';
         insert bitpod_con_obj;
         return bitpod_con_obj;
    }
    
    public static Event__c eventTestData() {
        Event__c event = new Event__c();
        event.Name = 'event1';
        event.Start_Date__c = date.today() + 5;
        event.End_Date__c= date.today() + 14;            
        event.Capture_Point__c= 'Salesforce';
        event.Venue_name__c= 'wtc';
        event.City__c = 'pune';
        event.State__c = 'mh';
        event.Zip_Code__c = '431110';
        event.Street__c = '201';
        event.Country__c = 'india';
        event.Timezone__c= '(GMT-08:00) Pacific Standard Time (America/Los_Angeles)';
        return event;
    }
    
    public static Event__c createEvent() {
        Event__c event = eventTestData();
        insert event;
        return event;
    }
    
    public static Event__c createEvent2() {
        Event__c event = new Event__c();
         event.Name = 'event2';
         event.Start_Date__c = date.today() + 5;
         event.End_Date__c= date.today() + 14; 
         event.Timezone__c= '(GMT-08:00) Pacific Standard Time (America/Los_Angeles)';
         event.Venue_name__c = 'wtc';
         insert event;
         return event;
    }
    
    public static Event_ticket__c ticketTestData() {
        Event_ticket__c ticket = new Event_ticket__c();
        ticket.Name = 'ticket1';     
        ticket.Start_Date__c = date.today() - 5;
        ticket.End_Date__c= date.today() ;
        ticket.Type__c = 'Free';    
       
        return ticket;
    }
    
    public static Event_ticket__c createTicket() {
        Event_ticket__c ticket = ticketTestData();
        Event__c event = createEvent();
        ticket.Event__c = event.id;
        insert ticket ;
        return ticket ;
    }
    
    public static ContentVersion createContentVersion(){
        ContentVersion cv = new Contentversion();
        cv.title='ABC';       
        Blob b=Blob.valueOf('This is version data');
        cv.versiondata=b;
        cv.PathOnClient = 'image1.jpg';
        cv.Is_Sync__c = true;
        Event__c event = createEvent();
        cv.FirstPublishLocationId = event.id;
        insert cv;  
        return cv;
    }
}