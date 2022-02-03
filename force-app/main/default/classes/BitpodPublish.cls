public with sharing class BitpodPublish {
    public static Bitpod_Credentials__c bitpodConfigObj{get;set;}  
    public static string contentType = 'application/json';  
    public static String filter = '';
    public static string method;
    public static string imageId;
    public static string sfEventId;
    public static string salesforceImageId;
    public static EventWrapper eventwrap;
    public static CommonWrapper commonWrapObj;
    public static Map<String,Object> responseMap;
    public static List<CommonWrapper> eventWrapList {get;set;} 
    public static List<CommonWrapper> ticketWrapList {get;set;} 
    public static List<CommonWrapper> imageWrapList {get;set;} 

    //call on publish button 
    @AuraEnabled
    public static string publish(string eventId, string objectName){
        responseMap             = new Map<String,Object>();
        eventWrapList           = new List<CommonWrapper>();
        ticketWrapList          = new List<CommonWrapper>();
        imageWrapList           = new List<CommonWrapper>();
        sfEventId               = eventId;
        string previewLink;
        setResponseMap();
        bitpodConfigObj = UtilityClass.getBitpodCredentials();
        
        if(bitpodConfigObj != null){ 
            responseMap.put('BitpodConfigStatus',true);
            
            bitpodConfigObj.Endpoint__c = bitpodConfigObj.Endpoint__c.removeEnd('/');
            previewLink = bitpodConfigObj.Endpoint__c+'/events/'+eventId;
            
            responseMap.put('previewLink',previewLink); 
            deleteChilds(eventId); // delete tickets,images from bitpod those are deleted from sf
            publishImages(eventId,'ContentVersion');
            
            publishEvents(eventId,objectName);
            if(responseMap.get('ReadyToEventPublish') == false || responseMap.get('IsSuccessEvent') == true){
                publishTickets(eventId,'Event_ticket__c');                
                
                if(eventWrapList != null && eventWrapList.size() > 0 || responseMap.get('IsDeleteChild') == true){ 
                    if(updatePublishStatus(eventWrapList,objectName) == true)
                        responseMap.put('IsUpdateEvent',true); 
                }
                if(ticketWrapList != null && ticketWrapList.size() > 0){ 
                    if(updatePublishStatus(ticketWrapList,'Event_ticket__c') == true)
                        responseMap.put('IsUpdateTicket',true); 
                }
                if(ticketWrapList != null && imageWrapList.size() > 0){ 
                    if(updatePublishStatus(imageWrapList,'ContentVersion') == true)
                        responseMap.put('IsUpdateImage',true); 
                }
            }
        }
        else{
            responseMap.put('BitpodConfigStatus',false);
        }
        return JSON.serialize(responseMap);
    }

    // publish event into bitpod
    public static void publishEvents(string eventId, string objectName){       
        Boolean isPublish = ReadyToPublish(eventId,objectName);
        if(isPublish){
            responseMap.put('ReadyToEventPublish',true);    
            eventWrapList = publishEventsToBitpod(eventId);
            if(eventWrapList != null){ 
                updateGeolocationToBitpod(eventId);
                responseMap.put('IsSuccessEvent',true);                
            }           
        }
        else if (responseMap.get('ReadyToEventPublish') == false && imageWrapList.size() > 0 ) {
            eventWrapList = publishEventsToBitpod(eventId);
            if(eventWrapList != null){ 
                updateGeolocationToBitpod(eventId);
                responseMap.put('IsSuccessImage',true);  
                responseMap.put('IsSuccessEvent',true);               
            }           
        }       
    }


    // publish ticket into bitpod
    public static void publishTickets(string eventId, string objectName){       
        Boolean isPublish = readyToPublish(eventId,objectName);
        if(isPublish){
            responseMap.put('ReadyToTicketPublish',true);    
            ticketWrapList = publishTicketsToBitpod(eventId);
            if(ticketWrapList != null){                
                    responseMap.put('IsSuccessTicket',true);                
            }           
        }        
    }

  
    // publish image into bitpod
    public static void publishImages(string eventId, string objectName){ 
        imageWrapList = new List<CommonWrapper>();      
        Boolean isPublish = readyToPublish(eventId,objectName);
        if(isPublish){
            responseMap.put('ReadyToImagePublish',true);    
            imageWrapList = publishImagesToBitpod(eventId);
            if(imageWrapList != null){                
                responseMap.put('IsSuccessImage',true); 
                if(updatePublishStatus(eventWrapList,'Event__c') == true){
                    responseMap.put('IsUpdateEvent',true);
                }
            }           
        }        
    }

    // check specific object is ready to publish 
    public static boolean readyToPublish(string eventId, string objectName){
        Boolean isReadyToPublish            = false;
        List<Event__c> eventList            = new List<Event__c>();    
        List<Event_ticket__c> ticketList    = new List<Event_ticket__c>();    
        List<ContentVersion> ImageList      = new List<ContentVersion>();   
        
             
        if(objectName == 'Event__c'){ 
            eventList = [SELECT Id, Is_Publish__c, Publish_Date__c 
                            FROM Event__c 
                            WHERE Id =: eventId AND Is_Publish__c = true];
            if(!eventList.isEmpty()){
                isReadyToPublish = true;
            }
        }
        if(objectName == 'Event_ticket__c'){ 
            ticketList = [SELECT Id,Is_Publish__c,Publish_Date__c 
                            FROM Event_ticket__c
                            WHERE Event__c =: eventId AND Is_Publish__c = true];
            if(!ticketList.isEmpty()){
                isReadyToPublish = true;
            }
        }
         if(objectName == 'ContentVersion'){ 
            ImageList = [SELECT Id,Is_Publish__c, Publish_Date__c 
                        FROM ContentVersion 
                        WHERE FirstPublishLocationId =: eventId AND Is_Publish__c = true 
                        ORDER BY LastModifiedDate DESC 
                        LIMIT 1];
            if(!ImageList.isEmpty()){
                isReadyToPublish = true;
            }
        }
        return isReadyToPublish;        
    }

    public static Boolean updatePublishStatus(List<CommonWrapper> commonWrapList,string objectName){
        Boolean isUpdatePublishStatus = false;
        if(objectName == 'Event__c'){ 
            try {
                List<Event__c> eventList = new List<Event__c>();
                List<Event__c> eventLst = [SELECT Id, Currency__c,imageId__c,Deleted_Ticket__c,Deleted_Image__c,Is_Sync__c FROM Event__c WHERE Id =: commonWrapList[0].Id];
                Map<String,Boolean> eFieldMap = UtilityClass.getFieldMap('bitpod__Event__c');

                for (CommonWrapper wrapObj : commonWrapList) {
                    Event__c event = eventLst[0];
                    if(event.id == wrapObj.id){ 
                        if(eFieldMap.get('bitpod__publish_date__c'))
                            event.Publish_Date__c = System.now().addMinutes(1);
                        if(String.isBlank(event.Currency__c) && eFieldMap.get('bitpod__currency__c')){                          
                            event.Currency__c = UserInfo.getDefaultCurrency();
                        }
                        if(imageId != null && eFieldMap.get('bitpod__imageid__c')){                           
                            event.imageId__c = imageId;
                        }
                        if(eFieldMap.get('bitpod__is_sync__c'))
                            event.Is_Sync__c = true;
                        if(responseMap.get('IsDeleteChild') == 'true'){
                            if(String.isNotBlank(event.Deleted_Ticket__c) && eFieldMap.get('bitpod__deleted_ticket__c')){                               
                                event.Deleted_Ticket__c = '';
                            }
                            if(String.isNotBlank(event.Deleted_Image__c) && eFieldMap.get('bitpod__deleted_image__c')){                                
                                event.Deleted_Image__c = '';
                            }
                        }
                        eventList.add(event);
                    }
                }    
                if(!eventList.isEmpty() && Event__c.sObjectType.getDescribe().isUpdateable()){
                    update eventList;
                }
                isUpdatePublishStatus = true;
            } catch (Exception e) {
                System.debug('==UpdatePublishStatus Event Object==');              
            }
        }
        if(objectName == 'Event_ticket__c'){ 
            try {
                List<Event_ticket__c> ticketList = new List<Event_ticket__c>();
                Map<String,Boolean> tFieldMap   = UtilityClass.getFieldMap('bitpod__Event_ticket__c');

                for (CommonWrapper wrapObj : commonWrapList) {
                    Event_ticket__c ticket      = new Event_ticket__c();
                        ticket.id               = wrapObj.id;
                    if(tFieldMap.get('bitpod__is_sync__c'))
                        ticket.Is_Sync__c       = true;
                    if(tFieldMap.get('bitpod__publish_date__c'))
                        ticket.Publish_Date__c  = System.now().addMinutes(1);
                    ticketList.add(ticket);
                }
                if(!ticketList.isEmpty() && Event_ticket__c.sObjectType.getDescribe().isUpdateable()){
                    update ticketList; 
                }
                isUpdatePublishStatus = true;
            } catch (Exception e) {
                System.debug('==UpdatePublishStatus ticket Object==');
            }
        }
        if(objectName == 'ContentVersion'){ 
            try {
                Map<String,Boolean> cFieldMap = UtilityClass.getFieldMap('ContentVersion');
                ContentVersion image        = new ContentVersion();
                image.id                    = salesforceImageId;
                if(cFieldMap.get('bitpod__is_sync__c'))
                    image.Is_Sync__c        = true;
                if(cFieldMap.get('bitpod__bitpod_id__c'))
                    image.Bitpod_Id__c      = imageId;
                if(cFieldMap.get('bitpod__publish_date__c'))
                    image.Publish_Date__c   = System.now().addMinutes(1);
                if(ContentVersion.sObjectType.getDescribe().isUpdateable()){
                    update image;
                }
                isUpdatePublishStatus = true;
            } catch (Exception e) {
                System.debug('==UpdatePublishStatus image Object==');
            }
        }
        return isUpdatePublishStatus;
    }
   
    public static void updateGeolocationToBitpod(string eventId){
        Event__c event;
        string address = '';
        string geolocationRecord;
        List<Event__c> eventList = [SELECT Id, Venue_name__c, City__c, State__c, Zip_Code__c, Street__c,
                                        Country__c
                                        FROM Event__c
                                        WHERE Id =: eventId];
        if(!eventList.isEmpty()){          
            event                           = eventList[0]; 
            if(String.isNotBlank(event.Venue_name__c))
                address = event.Venue_name__c+',';
            if(String.isNotBlank(event.Street__c))
                address += event.Street__c+',';
            if(String.isNotBlank(event.City__c))
                address += event.City__c+',';
            if(String.isNotBlank(event.State__c))
                address += event.State__c+',';
            if(String.isNotBlank(event.Country__c))
                address += event.Country__c+',';
            if(String.isNotBlank(event.Zip_Code__c))
                address += event.Zip_Code__c;
        }
        try {   
            if (address != '') {
                string resource                       = bitpodConfigObj.Event_Resource__c + '/updateGeoLocation';
                GeolocationWrapper wrapObj            = new GeolocationWrapper();  
                wrapObj.address                       = address;
                wrapObj.eventId                       = eventId;
                geolocationRecord                     = JSON.serialize(wrapObj,true); 
                makeCallout(bitpodConfigObj.Endpoint__c,resource,geolocationRecord, 'PUT',filter,contentType );      
            }                
        } catch (Exception e) {
            system.debug('==Geolocation callout Exception=');
        }

    }
 
    @AuraEnabled
    public static List<CommonWrapper> publishEventsToBitpod(string eventId){
        List<CommonWrapper> commonWrapList = new List<CommonWrapper>();
        HttpResponse eventresponse;
        String eventRecord; 
        Event__c event;
        // method = 'PUT';
        List<Event__c> eventList = [SELECT Id, Name,Is_Sync__c,
                                        Currency__c, Organizer__c, Event_Manager__c,
                                        ImageId__c, Title__c, Capture_Point__c, Start_Date__c, End_Date__c, 
                                        Timezone__c, Venue_name__c, City__c, State__c, Zip_Code__c, Street__c,
                                        Country__c, Description__c
                                        FROM Event__c
                                        WHERE Id =: eventId];
        if(!eventList.isEmpty()){ 
            event                           = eventList[0];   
            EventWrapper wrapObj            = new EventWrapper();           
            wrapObj.id = event.id;
            if(imageWrapList != null && !imageWrapList.isEmpty()){ 
                wrapObj.Images.add(imageWrapList[0].id);  
            }
            wrapObj.SalesforceEventId       = event.id;  
            if(String.isNotBlank(event.imageId__c)){
                wrapObj.Images.add(event.imageId__c);
            }
            wrapObj.Privacy                 = 'Public';
            wrapObj.CapturePoint            = 'Salesforce';
            wrapObj.HasTickets              = true;
            wrapObj.CurrencyCode            = event.Currency__c;
            //if event currency is blank then override it with users default currency
            if(String.isBlank(event.Currency__c)){
                wrapObj.CurrencyCode        = UserInfo.getDefaultCurrency();
            } 
   
            wrapObj.Code                    = event.Name;
            wrapObj.Title                   = event.Name;  
            wrapObj.Status                  = 'Open for registration';
            wrapObj.Organizer               = event.Organizer__c;
            wrapObj.EventManager            = event.Event_Manager__c;
            wrapObj.VenueName               = event.Venue_name__c;    
            if(String.isNotBlank(event.Timezone__c)) {
                String[] timezoneArr        = event.Timezone__c.split(' '); 
                String timezone             = timezoneArr[timezoneArr.size()-1];
                timezone                    = timezone.substring(1, timezone.length()-1);
                wrapObj.Timezone            = timezone;               
            }   
            if(event.Start_Date__c != null && event.End_Date__c != null){ 
                TimeZone tzKey              = UserInfo.getTimeZone();        
                Datetime originalStartDate  = getUTCDateTime(event.Start_Date__c);
                Datetime originalEndDate    = getUTCDateTime(event.End_Date__c);
                
                // to check timezone minutes
                String timezoneKey          = event.Timezone__c.split(' ')[0];
                Integer minuteDifference    = 0;
                if(timezoneKey.right(1) == ')')    
                    minuteDifference = Integer.valueof(timezoneKey.right(3).left(2)); 
                else 
                    minuteDifference = Integer.valueof(timezoneKey.right(2));
                
                // if selected timezone is org timezone
                if(wrapObj.Timezone == tzKey.getID()){
                    DateTime startdate      = event.Start_Date__c;
                    Decimal offsetVal       = DateTime.newInstance(startdate.date(), startdate.time()).getTime() - DateTime.newInstance(startdate.dateGmt(), startdate.timeGmt()).getTime();                 
                    Double dValue           = (offsetVal/3600000) * (-1);
                    wrapObj.StartDate       = getUTCDateTime(event.Start_Date__c.addHours(dValue.intValue()));
                    wrapObj.EndDate         = getUTCDateTime(event.End_Date__c.addHours(dValue.intValue()));  
                    minuteDifference        = minuteDifference * (-1);
                    if((dValue != 0 || dValue != 0.0) && minuteDifference != 0){
                        wrapObj.StartDate   = wrapObj.StartDate.addMinutes(minuteDifference);
                        wrapObj.EndDate     = wrapObj.EndDate.addMinutes(minuteDifference);
                    }
                }
                else{                  
                    Timezone tz             = Timezone.getTimeZone(wrapObj.Timezone);              
                    Decimal offset          = tz.getOffset(originalEndDate)/3600000;               
                    
                    wrapObj.StartDate       = originalStartDate.addHours(-offset.intValue());
                    wrapObj.EndDate         = originalEndDate.addHours(-offset.intValue());
                    
                    if(offset != 0 && minuteDifference != 0){
                        wrapObj.StartDate   = wrapObj.StartDate.addMinutes(-minuteDifference);
                        wrapObj.EndDate     = wrapObj.EndDate.addMinutes(-minuteDifference);
                    }
                }
             }
            
            wrapObj.VenueAddress.City           = event.City__c;  
            wrapObj.VenueAddress.State          = event.State__c;  
            wrapObj.VenueAddress.PostalCode     = event.Zip_Code__c;  
            wrapObj.VenueAddress.Country        = event.Country__c;  
            wrapObj.VenueAddress.AddressLine    = event.Street__c; 
          
            wrapObj.Description                 = getDescription(event.Description__c);
            eventRecord                         = JSON.serialize(wrapObj,true);
            eventRecord                         = eventRecord.replace('VenueAddress','_VenueAddress');
            eventRecord                         = eventRecord.replace('CurrencyCode','Currency');

            if(event.Is_Sync__c)
                method = 'PUT';
            else 
                method = 'POST';

            try {
                eventresponse = makeCallout(bitpodConfigObj.Endpoint__c,bitpodConfigObj.Event_Resource__c,eventRecord, method,filter,contentType );      
                commonWrapObj = (CommonWrapper)JSON.deserialize(eventresponse.getBody(), CommonWrapper.class);
                commonWrapList.add(commonWrapObj); 
            } catch (Exception e) {
                system.debug('==Event callout Exception=');
                return null;
            }
        } 
        return commonWrapList;          
    }   
    
    @AuraEnabled
    public static List<CommonWrapper> publishTicketsToBitpod(string eventid){
        List<TicketWrapper> ticketWrapListToCreate  = new List<TicketWrapper>();
        List<TicketWrapper> ticketWrapListToUpdate  = new List<TicketWrapper>();
        List<CommonWrapper> commonWrapList          = new List<CommonWrapper>();
        List<CommonWrapper> commonWrapList1         = new List<CommonWrapper>();
        List<CommonWrapper> commonWrapList2         = new List<CommonWrapper>();
        method = 'PUT';
        HttpResponse ticketresponse;
        string requestBody;
        List<Event_ticket__c> ticketList = [SELECT Id, Is_Sync__c, Name, Event__c, Type__c, 
                                                Price__c, Quantity__c, Start_Date__c, End_Date__c
                                                FROM Event_ticket__c
                                                WHERE Event__c =: eventid AND Is_Publish__c = true];
        for (Event_ticket__c ticket : ticketList) {
            TicketWrapper wrapObj       = new TicketWrapper();
            wrapObj.Id                  = ticket.id;
            wrapObj.SalesforceId        = ticket.id;
            wrapObj.Events              = ticket.Event__c;
            wrapObj.Code                = ticket.Name;
            wrapObj.Type                = ticket.Type__c;
            wrapObj.Amount              = ticket.Price__c == null?0:ticket.Price__c;
            wrapObj.TicketCount         = ticket.Quantity__c;
            if(ticket.Start_Date__c != null){
                wrapObj.StartDate       = getUTCDateTime(ticket.Start_Date__c);
            }
            if(ticket.End_Date__c != null){
                wrapObj.EndDate         = getUTCDateTime(ticket.End_Date__c);
            }
            wrapObj.Status              = 'Open for registration';
            if(ticket.Is_Sync__c){
                ticketWrapListToUpdate.add(wrapObj);
            }
            else{
                ticketWrapListToCreate.add(wrapObj);
            }
        } 
        // to update ticket in bitpod 
        if(ticketWrapListToUpdate.size() > 0){ 
            for (TicketWrapper wrapObj : ticketWrapListToUpdate) {
                try {
                    requestBody = JSON.serialize(wrapObj);
                    ticketresponse = makeCallout(bitpodConfigObj.Endpoint__c,bitpodConfigObj.EventTicket_Resource__c,requestBody, method,filter,contentType );      
                    commonWrapObj = (CommonWrapper)JSON.deserialize(ticketresponse.getBody(), CommonWrapper.class);
                    commonWrapList1.add(commonWrapObj); 
                } catch (Exception e) {
                    system.debug('==ticket callout Exception=update');
                }
            }
        }
        // to create ticket in bitpod
        if(ticketWrapListToCreate.size() > 0){ 
            try {
                requestBody = JSON.serialize(ticketWrapListToCreate);
                ticketresponse = makeCallout(bitpodConfigObj.Endpoint__c,bitpodConfigObj.EventTicket_Resource__c,requestBody, 'POST',filter,contentType );      
                commonWrapList2 = (List<CommonWrapper>)JSON.deserialize(ticketresponse.getBody(), List<CommonWrapper>.class);
                // commonWrapList.add(commonWrapObj); 
            } catch (Exception e) {
                system.debug('==ticket callout Exception=post');
            }
        }
        
        if(commonWrapList1.size() > 0)
            commonWrapList.addAll(commonWrapList1);
        if(commonWrapList2.size() > 0)                    
            commonWrapList.addAll(commonWrapList2);
        return commonWrapList;
    }


    @AuraEnabled
    public static List<CommonWrapper> publishImagesToBitpod(string eventId){
        HttpResponse imageresponse;       
        method          = 'POST';
        string filter   = '';
        List<CommonWrapper> commonWrapList = new List<CommonWrapper>();
        
        ContentVersion image    = [SELECT Id, FileType, VersionData,
                                        FileExtension, PathOnClient, ContentSize 
                                    FROM ContentVersion 
                                    WHERE FirstPublishLocationId =: eventId AND Is_Publish__c = true
                                    ORDER BY CreatedDate DESC 
                                    LIMIT 1] ;
        Blob file_body          = image.VersionData;
        string file_name        = image.pathonclient;
        salesforceImageId       = image.id;
        String boundary         = '----------------------------741e90d31eff';
        String header           = '--'+boundary+'\r\nContent-Disposition: form-data; name="file"; filename="'+file_name+'"\r\nContent-Type: image/jpeg'; // added '\r's removed ';' see Tim Smith's comment
        String footer           = '\r\n--'+boundary+'--';              
        String headerEncoded    = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        while(headerEncoded.endsWith('='))
        {
            header              += ' ';
            headerEncoded       = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        }
        String bodyEncoded      = EncodingUtil.base64Encode(file_body);
        String footerEncoded    = EncodingUtil.base64Encode(Blob.valueOf(footer));
        
        Blob bodyBlob           = null;
        String last4Bytes       = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
        if(last4Bytes.endsWith('=')){
            Blob decoded4Bytes = EncodingUtil.base64Decode(last4Bytes);
            HttpRequest tmp = new HttpRequest();
            tmp.setBodyAsBlob(decoded4Bytes);
            String last4BytesFooter = tmp.getBody()+footer;   
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded.substring(0,bodyEncoded.length()-4)+EncodingUtil.base64Encode(Blob.valueOf(last4BytesFooter)));
        }
        else{
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
        }

        String contentType = 'multipart/form-data; boundary='+boundary;        
        bitpodConfigObj = UtilityClass.getBitpodCredentials();
        try {
            AWSS3_GetService obj = new AWSS3_GetService();
            HttpResponse response = obj.getBucketswithBlob(bitpodConfigObj.Endpoint__c,bitpodConfigObj.Attachment_Resource__c, method, bodyBlob,filter,contentType );    

            commonWrapObj = (CommonWrapper)JSON.deserialize(response.getBody(), CommonWrapper.class);
            commonWrapList.add(commonWrapObj); 
            imageId = commonWrapObj.id;
        } catch (Exception e) {
            system.debug('==Attachment callout Exception=');
            commonWrapList = null;
        }
        return commonWrapList;
    }


    public static void deleteChilds(string eventId){
        bitpodConfigObj = UtilityClass.getBitpodCredentials();
        string requestBodyForPost = '';
        List<Event__c> eventList = [SELECT Id, Deleted_Ticket__c FROM Event__c WHERE Id =: eventId AND Deleted_Ticket__c != ''];
        List<Event__c> imageList = [SELECT ImageId__c, Deleted_Image__c FROM Event__c WHERE Id =: eventId AND Deleted_Image__c != ''];
        try {
            if(eventList.size() > 0 ) {
                List<Id> setIdList = new List<Id>();
                setIdList.addAll(eventList[0].Deleted_Ticket__c.split(',') );
                String Ids2 = String.join(setIdList, '","');
                String filter = '{"id": {"in":["'+Ids2+'"]}}';  
                HttpResponse deleteTicketResponse = makeCallout(bitpodConfigObj.Endpoint__c,bitpodConfigObj.EventTicket_Resource__c,requestBodyForPost, 'Delete',filter,contentType ); 
                responseMap.put('IsDeleteChild',true);    
            }
        } catch (Exception e) {
            system.debug('==deletechilds exception==');
        }       

        try {
            if(imageList.size() > 0 ) {  
                HttpResponse deleteImageResponse;  
                filter = '';         
                String resource = bitpodConfigObj.Event_Resource__c+'/'+eventId+'/BannerImage/rel/'+imageList[0].imageId__c;
                deleteImageResponse = makeCallout(bitpodConfigObj.Endpoint__c,resource,requestBodyForPost, 'Delete',filter,contentType);
                if(deleteImageResponse.getStatusCode() == 204){
                    responseMap.put('IsDeleteChild',true);
                }
            }
        }
        catch (Exception e) {
            system.debug('==deletechilds exception==');
        }      
    }

    @future(callout=true)
    public static void DeleteEventsToBitpod(String filter) {
        bitpodConfigObj         = UtilityClass.getBitpodCredentials();
        HttpResponse response   = makeCallout(bitpodConfigObj.Endpoint__c,bitpodConfigObj.Event_Resource__c,'', 'DELETE',filter,contentType ); 
    }

    public static HttpResponse makeCallout(String endpoint, String resource, string requestBodyForPost,String method,string filter,string contentType){
        AWSS3_GetService obj    = new AWSS3_GetService();
        HttpResponse response;
        try {
            response = obj.getBuckets(endpoint,resource, method, requestBodyForPost,filter,contentType );       
        } catch (Exception e) {
            system.debug('==makeCallout exception==');
        }

        return response;
    }

    public static DateTime getUTCDateTime(DateTime dt){
        Datetime GMTDate = Datetime.newInstanceGmt(
                                dt.year(),
                                dt.month(),
                                dt.day(),
                                dt.hour(),
                                dt.minute(),
                                dt.second());
        return GMTDate;
    }

    private static void setResponseMap(){
        responseMap.put('BitpodConfigStatus',false); 
        responseMap.put('ReadyToEventPublish',false); 
        responseMap.put('IsSuccessEvent',false);   
        responseMap.put('ReadyToTicketPublish',false); 
        responseMap.put('IsSuccessTicket',false); 
        responseMap.put('IsUpdateEvent',false); 
        responseMap.put('IsUpdateTicket',false);   

        responseMap.put('ReadyToImagePublish',false); 
        responseMap.put('IsSuccessImage',false);     
        responseMap.put('IsUpdateImage',false); 
        responseMap.put('IsDeleteChild',false); 
        responseMap.put('previewLink',null);
    }

    private static string getDescription(String description){
        String imageURL             = '';  
        String imgvalue             = '';
        String finalvalue           = '';
        if(String.isNotBlank(description)){ 
            Matcher imgMatcher      = Pattern.compile( '<img(.+?)>' ).matcher(description);           
            while (imgMatcher.find()) {                
                String imageTag     = imgMatcher.group();
                imageURL            = imageTag.substringBetween(' src="', '"' );
                String decodedURL   = imageURL.unescapeHtml4();
                PageReference page  = new PageReference( decodedURL );
                Blob b              = page.getContent();
                String contentvalue = EncodingUtil.base64Encode(b );
                String beforevalue  = '<p><img src=\"data:image/jpeg;base64,';
                String aftervalue   = 'data-filename=\"image4.jpg\" style=\"width: 689px;\"><br></p>';
                imgvalue            = beforevalue + contentvalue + '\"' + '' + aftervalue;
            }
            finalvalue              = description;
            String otherString      = description.replaceAll('(?i)<img[^>]*>', '');
            if(String.isNotBlank(imgvalue)){
                if(String.isNotBlank(otherString)){
                    finalvalue = imgvalue + otherString;
                }
                else{
                    finalvalue = imgvalue;
                }
            }
        }   
        return finalvalue;
    }

    public class CommonWrapper{       
        public string id;
        public string[] Images;
    }
    
    public class TicketWrapper{       
        public string id;
        public string Events;
        public string SalesforceId;
        public string Code;
        public string Type;
        public Decimal Amount;
        public Decimal TicketCount;
        public DateTime StartDate;
        public DateTime EndDate;
        public string Status;
    }

    public class EventWrapper{       
        public string id;
        public String SalesforceEventId;
        public String Privacy;
        public string Code;
        public string Title;
        public string CapturePoint;
        public boolean HasTickets;
        public string Status;
        public DateTime StartDate;
        public DateTime EndDate;
        public string Timezone;
        public string Organizer;
        public string EventManager;
        public string Description;
        public string CurrencyCode;

        public string VenueName;
        public string[] Images = new List<String>(); 
        
        public VenueAddressWrapper VenueAddress;

        public EventWrapper(){
            VenueAddress = new VenueAddressWrapper();
        }
    }

    public class VenueAddressWrapper{   
        string City;
        string State;
        string PostalCode;
        string Country;
        string AddressLine;
    } 

    public class GeolocationWrapper{
        public String eventId;
        public String address;
    }
}