public with sharing class UtilityClass {
    public static Bitpod_Configuration__c getBitpodConfiguration() {       
        Bitpod_Configuration__c bitpodConfigObj = null;
        List<Bitpod_Configuration__c > bitpodConList = [SELECT Id, Access_Key__c,
                                                Secret_Key__c,
                                                Endpoint__c, 
                                                Event_Resource__c, EventTicket_Resource__c, 
                                                Speaker_Resource__c, Attachment_Resource__c 
                                                FROM Bitpod_Configuration__c 
                                                ORDER BY createdDate 
                                                LIMIT 1];
        if(!bitpodConList.isEmpty() &&
            String.isNotBlank(bitpodConList[0].Access_Key__c) &&
            String.isNotBlank(bitpodConList[0].Secret_Key__c) &&  
            String.isNotBlank(bitpodConList[0].Endpoint__c) && 
            String.isNotBlank(bitpodConList[0].EventTicket_Resource__c) && 
            String.isNotBlank(bitpodConList[0].Speaker_Resource__c)){
                bitpodConfigObj = bitpodConList[0];
        }
        return bitpodConfigObj;
    }

    public static Bitpod_Credentials__c getBitpodCredentials() {       
        Bitpod_Credentials__c bitpodConfigObj = null;
        List<Bitpod_Credentials__c > bitpodConList = [SELECT Id, Access_Key__c,
                                                Secret_Key__c,
                                                Endpoint__c, 
                                                Event_Resource__c, EventTicket_Resource__c, 
                                                Speaker_Resource__c, Attachment_Resource__c 
                                                FROM Bitpod_Credentials__c 
                                                ORDER BY createdDate 
                                                LIMIT 1];
        if(!bitpodConList.isEmpty() &&
            String.isNotBlank(bitpodConList[0].Access_Key__c) &&
            String.isNotBlank(bitpodConList[0].Secret_Key__c) &&  
            String.isNotBlank(bitpodConList[0].Endpoint__c) && 
            String.isNotBlank(bitpodConList[0].EventTicket_Resource__c) && 
            String.isNotBlank(bitpodConList[0].Speaker_Resource__c)){
                bitpodConfigObj = bitpodConList[0];
        }
        return bitpodConfigObj;
    }

    public Static Map<String,Boolean> getObjectAndFieldsMap(String objectName, String databaseOperation){
        Map<String,Boolean> fieldMap = new Map<String,Boolean>();
        SObjectType accountType = Schema.getGlobalDescribe().get(objectName);
        Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();
        for(String fName : mfields.keySet()){
            Schema.SObjectField sObj = mfields.get(fName);
            Schema.DescribeFieldResult dfr = sObj.getDescribe();          
            if(dfr.isUpdateable() && databaseOperation.equalsIgnoreCase('update')){
                fieldMap.put(fName,true);
            }
            else if(dfr.isCreateable() && databaseOperation.equalsIgnoreCase('insert')){ 
                fieldMap.put(fName,true);
            }
            else if(dfr.isAccessible() && databaseOperation.equalsIgnoreCase('query')){
                fieldMap.put(fName,true);
            }
            else
                fieldMap.put(fName,false);
        }
        return fieldMap;
    } 
    public Static Map<String,Boolean> getFieldMap(String objectName){
        Map<String,Boolean> fieldMap = new Map<String,Boolean>();
        SObjectType accountType = Schema.getGlobalDescribe().get(objectName);
        Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();
        for(String fName : mfields.keySet()){
            Schema.SObjectField sObj = mfields.get(fName);
            Schema.DescribeFieldResult dfr = sObj.getDescribe();
            if(dfr.isUpdateable())
                fieldMap.put(fName,true);
            else if(dfr.isCreateable())
                fieldMap.put(fName,true);
            else
                fieldMap.put(fName,false);
        }
        return fieldMap;
   }
  
}