trigger EventTrigger on Event__c (after delete,after update ,after insert) {
    if(Trigger.isAfter){
        if(Trigger.isDelete) {       
            Set<Id> allDeletedIds = trigger.oldMap.keySet(); 
            List<Id> setIdList = new List<Id>();
            setIdList.addAll(allDeletedIds );
            String Ids2 = String.join(setIdList, ',');
            String filter = '{"id": {"in":["'+Ids2+'"]}}';          
            BitpodPublish.DeleteEventsToBitpod(filter); 
        }        
    }
}