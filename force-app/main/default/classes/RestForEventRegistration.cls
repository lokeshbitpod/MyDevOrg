@RestResource(urlMapping='/EventRegistration/*')
global with sharing class RestForEventRegistration {      
  public class EventRegistrationWrapper {
      public String SalesforceEventId {get; set;}  
      public RegistrationWrapper Registration {get; set;}
      public List<AttendeeWrapper> Attendee {get;set;}
  } 
  
  public class RegistrationWrapper{
      public String EventId {get;set;}
      public String CompanyName {get; set;}
      public String Email {get; set;} 
      public String Status {get; set;}     
      public String FirstName{get; set;} 
      public String LastName{get; set;}
      public String Title{get; set;} 
      public String TotalAmount{get; set;}
      public String Salutation{get; set;} 
      public String Phone{get; set;} 
      public Integer TicketQuantity{get;set;}
      
      public String [] SessionId {get; set;}
      public String [] TicketId {get; set;}
      public AddressWrapper Address {get; set;}
  }
  
 public class AddressWrapper{
      public String Country{get; set;}
      public String AddressLine{get; set;}
      public String City{get; set;}
      public String PostalCode{get; set;}
      public String State{get; set;}
  }

  public class AttendeeWrapper{
      public String FirstName {get;set;}
      public String LastName {get; set;}
      public String Email {get; set;} 
      public String CompanyName {get; set;}
      public String Status {get; set;}   
      public String Salutation{get; set;}   
      public String Phone{get; set;}    
      public Id TicketId{get; set;}

      public AddressWrapper Address {get; set;}
  }
   
  @HttpPost
    global static String doPost() {     
        try {
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();    
            jsonBody = jsonBody.replace('_CurrentAddress','Address');
            JSONParser parser = JSON.createParser(jsonBody);
         
            EventRegistrationWrapper eventRegWrap = (EventRegistrationWrapper)System.JSON.deserialize(jsonBody, EventRegistrationWrapper.class);
          
                    
            Map<String,Boolean> eFieldMap   = UtilityClass.getFieldMap('bitpod__Event_registration__c');

            Event_registration__c event_reg = new Event_registration__c();
            if(eFieldMap.get('bitpod__event__c') && eventRegWrap.Registration.EventId != null)
                event_reg.Event__c = eventRegWrap.Registration.EventId;

            if(eFieldMap.get('bitpod__company__c') && eventRegWrap.Registration.CompanyName != null)
                event_reg.Company__c = eventRegWrap.Registration.CompanyName;

            if(eFieldMap.get('bitpod__first_name__c') && eventRegWrap.Registration.FirstName != null)
                event_reg.First_Name__c = eventRegWrap.Registration.FirstName;

            if(eFieldMap.get('bitpod__last_name__c') && eventRegWrap.Registration.LastName != null)    
                event_reg.Last_Name__c = eventRegWrap.Registration.LastName ;

            if(eFieldMap.get('bitpod__email__c') && eventRegWrap.Registration.Email != null)    
                event_reg.Email__c = eventRegWrap.Registration.Email;

            if(eFieldMap.get('bitpod__status__c') && eventRegWrap.Registration.Status != null)        
                event_reg.Status__c = eventRegWrap.Registration.Status;

            if(eFieldMap.get('bitpod__phone__c') && eventRegWrap.Registration.Phone != null)        
                event_reg.Phone__c = eventRegWrap.Registration.Phone;    

            if(eFieldMap.get('bitpod__salutation__c') && eventRegWrap.Registration.Salutation != null)                 
                event_reg.Salutation__c = eventRegWrap.Registration.Salutation;  

            if(eFieldMap.get('bitpod__title_input__c') && eventRegWrap.Registration.Title != null)                 
                event_reg.Title_Input__c = eventRegWrap.Registration.Title ;
            
            if(eFieldMap.get('bitpod__ticket_quantity__c') && eventRegWrap.Registration.TicketQuantity != null)    
                event_reg.Ticket_Quantity__c = eventRegWrap.Registration.TicketQuantity ;

            List<Registration_Ticket__c> regTicketList = new List<Registration_Ticket__c>();
            List<Attendee__c> attendeeList = new List<Attendee__c>();
            List<Attendee_Ticket__c> attendeeTicketList = new List<Attendee_Ticket__c>();
            
                
            if(eFieldMap.get('bitpod__amount__c') && eventRegWrap.Registration.TotalAmount != null)
                    event_reg.Amount__c = decimal.valueOf(eventRegWrap.Registration.TotalAmount) ;
            if(eventRegWrap.Registration.Address != null){
                if(eFieldMap.get('bitpod__country__c') && eventRegWrap.Registration.Address.Country != null)
                    event_reg.Country__c = eventRegWrap.Registration.Address.Country;
                if(eFieldMap.get('bitpod__address__c') && eventRegWrap.Registration.Address.AddressLine != null)    
                    event_reg.Address__c = eventRegWrap.Registration.Address.AddressLine; 
                if(eFieldMap.get('bitpod__city__c') && eventRegWrap.Registration.Address.City != null) 
                    event_reg.City__c = eventRegWrap.Registration.Address.City; 
                if(eFieldMap.get('bitpod__state__c') && eventRegWrap.Registration.Address.State != null) 
                    event_reg.State__c = eventRegWrap.Registration.Address.State; 
                if(eFieldMap.get('bitpod__postal_code__c') && eventRegWrap.Registration.Address.PostalCode != null) 
                    event_reg.Postal_Code__c = eventRegWrap.Registration.Address.PostalCode; 
            }    
          
            if(Event_registration__c.sObjectType.getDescribe().isCreateable())
                insert event_reg;
                
            if(eventRegWrap.Registration.TicketId != null){ 
                if(eventRegWrap.Registration.TicketId.size() > 0){
                    Map<String,Boolean> rFieldMap   = UtilityClass.getFieldMap('bitpod__Registration_Ticket__c');
                    for(integer i = 0; i < eventRegWrap.Registration.TicketId.size(); i++){                   
                        Registration_Ticket__c reg_ticket = new Registration_Ticket__c();
                        reg_ticket.Event_Registration__c = event_reg.Id; 
                        reg_ticket.Event_Ticket__c = eventRegWrap.Registration.TicketId[i];                  
                        regTicketList.add(reg_ticket);
                    }
                    if(regTicketList.size() > 0 && Registration_Ticket__c.sObjectType.getDescribe().isCreateable())
                        insert regTicketList;
                }
            }

            if(eventRegWrap.Attendee != null){ 
                if(eventRegWrap.Attendee.size() > 0){
                    Map<String,Boolean> aFieldMap   = UtilityClass.getFieldMap('bitpod__Attendee__c');

                    for(AttendeeWrapper attendeeWrap : eventRegWrap.Attendee){                  
                            Attendee__c attendee = new Attendee__c();
                            if(aFieldMap.get('bitpod__registrationid__c') && event_reg.Id != null) 
                                attendee.RegistrationId__c = event_reg.Id; 
                            if(aFieldMap.get('bitpod__first_name__c') && attendeeWrap.FirstName != null) 
                                attendee.First_Name__c = attendeeWrap.FirstName;   
                            if(aFieldMap.get('bitpod__last_name__c') && attendeeWrap.LastName != null) 
                                attendee.Last_Name__c = attendeeWrap.LastName;   
                            if(aFieldMap.get('bitpod__email__c') && attendeeWrap.Email != null) 
                                attendee.Email__c = attendeeWrap.Email;   
                            if(aFieldMap.get('bitpod__phone__c') && attendeeWrap.Phone != null) 
                                attendee.Phone__c = attendeeWrap.Phone;   
                            if(aFieldMap.get('bitpod__salutation__c') && attendeeWrap.Salutation != null) 
                                attendee.Salutation__c = attendeeWrap.Salutation;   
                            if(aFieldMap.get('bitpod__organization__c') && attendeeWrap.CompanyName != null) 
                                attendee.Organization__c = attendeeWrap.CompanyName;   
                            if(aFieldMap.get('bitpod__ticket_id__c') && attendeeWrap.TicketId != null) 
                                attendee.Ticket_Id__c = attendeeWrap.TicketId;   
                            if(attendeeWrap.Address != null){
                                if(aFieldMap.get('bitpod__country__c') && attendeeWrap.Address.Country != null) 
                                    attendee.Country__c = attendeeWrap.Address.Country;
                                if(aFieldMap.get('bitpod__address__c') && attendeeWrap.Address.AddressLine != null) 
                                    attendee.Address__c = attendeeWrap.Address.AddressLine; 
                                if(aFieldMap.get('bitpod__city__c') && attendeeWrap.Address.City != null) 
                                    attendee.City__c = attendeeWrap.Address.City; 
                                if(aFieldMap.get('bitpod__state__c') && attendeeWrap.Address.State != null) 
                                    attendee.State__c = attendeeWrap.Address.State; 
                                if(aFieldMap.get('bitpod__postal_code__c') && attendeeWrap.Address.PostalCode != null) 
                                    attendee.Postal_Code__c = attendeeWrap.Address.PostalCode; 
                            }    

                        attendeeList.add(attendee);
                    }
                    if(attendeeList.size() > 0 && Attendee__c.sObjectType.getDescribe().isCreateable())
                        insert attendeeList;
                    if(attendeeList.size() > 0 ){
                        Map<String,Boolean> atFieldMap   = UtilityClass.getFieldMap('bitpod__Attendee_Ticket__c');
                        for(Attendee__c aObj : attendeeList){              
                            Attendee_Ticket__c aTicket = new Attendee_Ticket__c();
                            aTicket.Attendee__c = aObj.id;
                            if(atFieldMap.get('bitpod__event_ticket__c') && aObj.Ticket_Id__c != null) 
                                aTicket.Event_ticket__c = aObj.Ticket_Id__c;
                            attendeeTicketList.add(aTicket);
                        }
                        if(attendeeTicketList.size() > 0 && Attendee_Ticket__c.sObjectType.getDescribe().isCreateable())
                            insert attendeeTicketList;
                    }    
                }
            }        
            return event_reg.id;
        } catch (Exception e) {
            system.debug('==rest registration exception=');
            return 'Registration request is not correct!';
        } 
   
   } // end of api
    
} //end of class