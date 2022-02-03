trigger ImageTrigger on ContentDocument (before delete) {     
    List<Event__c> eventList = new List<Event__c>();
    Set<Id> contentIds = new set<Id>();
    Set<Id> eventIds = new set<Id>();
    for(ContentDocument image: trigger.old){          
        contentIds.add(image.id); 
    }
    
    for(ContentVersion content: [select id,FirstPublishLocationId from ContentVersion where ContentDocumentId in :contentIds]){         
        eventIds.add(content.FirstPublishLocationId); 
    }      
    
    
    try{ 
        Map<ID, Event__c> eventMap = new Map<ID, Event__c >([select id,Publish_Date__c,Deleted_Image__c,LastModifiedDate from Event__c where id in :eventIds]);    
        for(ContentVersion image: [select id,Bitpod_Id__c,FirstPublishLocationId,Is_Sync__c from ContentVersion where ContentDocumentId in :contentIds]){
            
            if(image.Is_Sync__c == true && eventMap.get(image.FirstPublishLocationId) != null){
                string deleted_image = eventMap.get(image.FirstPublishLocationId).Deleted_Image__c ;
                Event__c event = new Event__c ();
                event.id = image.FirstPublishLocationId;
                if(eventMap.get(image.FirstPublishLocationId).Publish_Date__c > eventMap.get(image.FirstPublishLocationId).LastModifiedDate)
                    event.Publish_Date__c = System.now().addMinutes(1);
                if(deleted_image != null)
                    event.Deleted_Image__c = deleted_image+','+image.Bitpod_Id__c;
                else
                    event.Deleted_Image__c = image.Bitpod_Id__c;
                eventList.add(event);
            }             
        }
        if(eventList.size() > 0)
            update eventList;
    }
    catch(Exception ex){
        system.debug('==image trigger=');       
    } 
}