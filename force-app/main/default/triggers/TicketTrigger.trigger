trigger TicketTrigger on Event_ticket__c(after delete) {
    
    List<Event__c> eventList = new List<Event__c>();
    
    if (Trigger.isDelete && Trigger.isAfter) {    
        Set<Id> eventIds = new set<Id>();
        for(Event_ticket__c ticket: trigger.old){
            eventIds.add(ticket.Event__c); 
        }
        try{ 
             Map<ID, Event__c> eventMap = new Map<ID, Event__c >([select id,Deleted_Ticket__c,Publish_Date__c,LastModifiedDate from Event__c where id in :eventIds]);    
             for(Event_ticket__c ticket: trigger.old){
                 
                 if(ticket.Is_Sync__c == true && eventMap.get(ticket.Event__c) != null){
                     string deleted_ticket = eventMap.get(ticket.Event__c).Deleted_Ticket__c ;
                     Event__c event = new Event__c ();
                     event.id = ticket.Event__c;
                     if(eventMap.get(ticket.Event__c).Publish_Date__c > eventMap.get(ticket.Event__c).LastModifiedDate)                         
                        event.Publish_Date__c = System.now().addMinutes(1);
                     if(deleted_ticket != null)
                         event.Deleted_Ticket__c = deleted_ticket+','+ticket.id;
                     else
                         event.Deleted_Ticket__c = ticket.id;
                     eventList.add(event);
                 }             
             }
            if(eventList.size() > 0)
                update eventList;
        }
        catch(Exception ex){
            system.debug('==Ticket trigger=');           
        }
    } 
}