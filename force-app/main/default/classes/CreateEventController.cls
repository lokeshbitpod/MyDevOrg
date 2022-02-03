public with sharing class CreateEventController {
    @AuraEnabled
    public static String createEvent(Event__c eventRecord, List<Event_ticket__c> ticketRecords){
        Map<String,Object> responseMap=new Map<String,Object>();
        Boolean isSuccess=false;
        String message='';
        Id eventRecordId=null;
        String previewLink = '';
        String eventName = '';
        try{            
            if(Event__c.sObjectType.getDescribe().isCreateable() && !ticketRecords.isEmpty()){
                eventRecord.Currency__c = UserInfo.getDefaultCurrency();
                insert eventRecord;
            
                eventRecordId   = eventRecord.Id;
                eventName       = eventRecord.name.replace(' ','-');
                //start: code to removed
                List<Bitpod_Credentials__c > bitpodConList = [Select id,Access_Key__c, Secret_Key__c,Endpoint__c from Bitpod_Credentials__c order by createdDate Limit 1];
                if(bitpodConList.size() > 0) {   
                    if(bitpodConList[0].Endpoint__c.right(1) == '/')        
                        eventRecord.Preview_Link__c = bitpodConList[0].Endpoint__c + 'events/'+eventRecordId;
                    else
                        eventRecord.Preview_Link__c = bitpodConList[0].Endpoint__c + '/events/'+eventRecordId;
                    if(Event__c.sObjectType.getDescribe().isUpdateable()){
                        update eventRecord;
                    }
                }
                //end: code to removed
                for(Event_ticket__c ticketObj:ticketRecords){
                    ticketObj.Event__c=eventRecord.Id;
                }
                if(!ticketRecords.isEmpty() && Event_ticket__c.sObjectType.getDescribe().isCreateable()){
                    insert ticketRecords;
                }
                isSuccess       = true;
                message         = 'Event created successfully.';
                eventName       = eventRecord.name.replace(' ','-');  
            }          
        }
        catch(Exception ex){           
            System.debug('=createEvent==exception=');            
        }
        responseMap.put('isSuccess',isSuccess);
        responseMap.put('message',message);
        responseMap.put('eventRecordId',eventRecordId);
        responseMap.put('previewLink',previewLink);

        return JSON.serialize(responseMap);
    }

    @AuraEnabled(cacheable=true)
    public static string getCurrentUserAndEventDate(){  // current user information
        Map<String,Object> responseMap=new Map<String,Object>();
        User currentUser = [SELECT Id, Name, TimeZoneSidKey, Username, Email, Street, Address, City,
                                PostalCode, State, Country
                            FROM User
                            WHERE Id =: userInfo.getUserId()];
        String timezone = UserInfo.getTimeZone().getDisplayName();  
        Datetime startDate = System.now().addDays(30);
        Datetime endDate = System.now().addDays(34);
        Datetime ticketStartDate = System.now();
        Datetime ticketEndDate = System.now().addDays(33);
        string currencyCode = UserInfo.getDefaultCurrency();
        Bitpod_Credentials__c bitpodConfigObj = UtilityClass.getBitpodCredentials();
        
        responseMap.put('currentuser',currentUser);    
        responseMap.put('timezone',timezone);    
        responseMap.put('startDate',startDate);    
        responseMap.put('endDate',endDate);  
        responseMap.put('ticketStartDate',ticketStartDate);
        responseMap.put('ticketEndDate',ticketEndDate);
        responseMap.put('currencyCode',currencyCode);
        responseMap.put('bitpodConfigObj',bitpodConfigObj);     
        return JSON.serialize(responseMap);
    }

    @AuraEnabled(cacheable=true)
    public static string getEvent(string recordId){
        String allFields;
        String soql;
        Set<String> fieldList = new Set<String>();
		Map<String,Boolean> mapOfFields = new Map<String,Boolean>();
		
        Bitpod_Credentials__c bitpodConfigObj = UtilityClass.getBitpodCredentials();
		if(! Event__c.sObjectType.getDescribe().isAccessible()){
			return null;
		}
		mapOfFields = UtilityClass.getObjectAndFieldsMap('bitpod__Event__c', 'query');
        allFields = 'Id, Name, bitpod__Preview_Link__c, bitpod__Is_Sync__c, bitpod__Status__c, bitpod__SEO_Title__c';
		
		for(String field : allFields.split(',')){
            if(mapOfFields.get(field.trim().toLowerCase()) != null && mapOfFields.get(field.trim().toLowerCase())){
                fieldList.add(field.trim());
            }
        }
		if(!fieldList.isEmpty()){  
            soql = 'SELECT ' + String.join(new List<String>(fieldList), ',') + ' FROM Event__c WHERE Id =: recordId';
        }   
        System.debug('++++debgsoql'+soql);
        List<Event__c> eventList = Database.query(soql);
        Event__c event = eventList[0];

        string previewLink ;
        if(event != null && event.Preview_Link__c != null)
            previewLink = event.Preview_Link__c ;
        else { 
            if(bitpodConfigObj != null){
                bitpodConfigObj.Endpoint__c = bitpodConfigObj.Endpoint__c.removeEnd('/');
                previewLink = bitpodConfigObj.Endpoint__c+'/'+ event.Name.replace(' ','-')+'-tickets-'+ event.id;
            }
        }
        Map<String,Object> responseMap=new Map<String,Object>();
        responseMap.put('status',event.Status__c);   
        responseMap.put('previewlink',previewLink);   
        responseMap.put('isSync',event.Is_Sync__c);     
        return JSON.serialize(responseMap);
    }

    @AuraEnabled
    public static Boolean getEventCount(string apiurl,string accesskey,string secretkey){
        String contentType          = 'application/json';
        Boolean isSuccess           = false;
        
        AWSS3_GetService.APP_URL    = apiurl;
        AWSS3_GetService.ACCESS_KEY = accesskey;
        AWSS3_GetService.SECRET_KEY = secretkey;

        String event_resource       = '/svc/api/Events';
        event_resource              = event_resource +'/count';
        string requestbodyforpost   = '';
        string filter               = '';
        // Bitpod_Credentials__c bitpodConfigObj = UtilityClass.getBitpodCredentials();
        List<Bitpod_Credentials__c> bitpodConfigList =  [SELECT Id, Access_Key__c, Secret_Key__c, Endpoint__c, 
                                                                Event_Resource__c, EventTicket_Resource__c, 
                                                                Speaker_Resource__c, Attachment_Resource__c 
                                                        FROM Bitpod_Credentials__c 
                                                        ORDER BY createdDate 
                                                        LIMIT 1];
        Bitpod_Credentials__c  bitpodConfigObj = new Bitpod_Credentials__c(); 
        if(bitpodConfigList.size() > 0){
            bitpodConfigObj = bitpodConfigList[0];
        }

      
        HttpResponse response;
        try{
            response = BitpodPublish.MakeCallout(apiurl,event_resource,requestBodyForPost, 'GET',filter,contentType);
            if(response.getStatusCode() == 200){ 
                isSuccess = true;               
                bitpodConfigObj.bitpod__Access_Key__c           = accesskey;               
                bitpodConfigObj.bitpod__Secret_Key__c           = secretkey;
                bitpodConfigObj.bitpod__Endpoint__c             = apiurl;
                bitpodConfigObj.bitpod__Attachment_Resource__c  = '/svc/api/Attachments';
                bitpodConfigObj.bitpod__Event_Resource__c       = '/svc/api/Events';
                bitpodConfigObj.bitpod__EventTicket_Resource__c = '/svc/api/Tickets';
                bitpodConfigObj.bitpod__Speaker_Resource__c     = '/svc/api/Speakers';
                upsert bitpodConfigObj; 
            }
            else 
                isSuccess = false;
        }catch(Exception ex){
            System.debug('=getEventCount==exception=');           
            isSuccess = false;
        }       
        return isSuccess;
    }

    // required in setup bitpod connection
    @AuraEnabled(cacheable=true)
    public static string getBitpodCredentials(){
        Bitpod_Credentials__c bitpodConfigObj = UtilityClass.getBitpodCredentials();
      
        Map<String,Object> responseMap = new Map<String,Object>();
        if(bitpodConfigObj != null){ 
            responseMap.put('apiurl',bitpodConfigObj.Endpoint__c);
           // responseMap.put('accesskey',bitpodConfigObj.Access_Key__c);   
           // responseMap.put('secretkey',bitpodConfigObj.Secret_Key__c);   
           // responseMap.put('accesskey','*******');   
           // responseMap.put('secretkey','*******');
            responseMap.put('configid',bitpodConfigObj.Id);
        }
        return JSON.serialize(responseMap);
    }
}