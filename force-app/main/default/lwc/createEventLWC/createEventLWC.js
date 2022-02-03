import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { 
    ALL_FIELDS_REQUIRED,
    EVENT_START_END_DATE,
    VALID_TICKET_MSG,
    EVENT_TICKET_END_DT_MSG,
    EVENT_START_DATE,
    TICKET_START_DT_MSG,
    TICKET_END_DT_MSG
} from 'c/messageUtilityLwc';
import Event_OBJECT from '@salesforce/schema/Event__c';
import EventTicket_OBJECT from '@salesforce/schema/Event_ticket__c';
import NAME_FIELD from '@salesforce/schema/Event__c.Name';
import STARTDATE_FIELD from '@salesforce/schema/Event__c.Start_Date__c';
import ENDDATE_FIELD from '@salesforce/schema/Event__c.End_Date__c';
import TIMEZONE_FIELD from '@salesforce/schema/Event__c.Timezone__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Event__c.Description__c';
import VENUENAME_FIELD from '@salesforce/schema/Event__c.Venue_name__c';
import CITY_FIELD from '@salesforce/schema/Event__c.City__c';
import STATE_FIELD from '@salesforce/schema/Event__c.State__c';
import STREET_FIELD from '@salesforce/schema/Event__c.Street__c';
import POSTALCODE_FIELD from '@salesforce/schema/Event__c.Zip_Code__c';
import COUNTRY_FIELD from '@salesforce/schema/Event__c.Country__c';

import TICKETNAME_FIELD from '@salesforce/schema/Event_ticket__c.Name';
import TICKETTYPE_FIELD from '@salesforce/schema/Event_ticket__c.Type__c';
import TICKETSTARTDATE_FIELD from '@salesforce/schema/Event_ticket__c.Start_Date__c';
import TICKETENDDATE_FIELD from '@salesforce/schema/Event_ticket__c.End_Date__c';
import PRICE_FIELD from '@salesforce/schema/Event_ticket__c.Price__c';
import QUANTITY_FIELD from '@salesforce/schema/Event_ticket__c.Quantity__c';
import createEvent from '@salesforce/apex/CreateEventController.createEvent';
import getCurrentUserAndEventDate from '@salesforce/apex/CreateEventController.getCurrentUserAndEventDate';

import publish from '@salesforce/apex/BitpodPublish.publish';

/* eslint-disable no-console */
 /* eslint-disable no-alert */

const columns = [{
    label: 'Ticket name',
    fieldName: 'Name',
    type: 'text',
    sortable: true
},
{
    label: 'Type',
    fieldName: 'Type__c',
    type: 'Decimal',
    sortable: true
},
{
    label: 'Price',
    fieldName: 'Price__c',
    type: 'text',
    sortable: true
}
];

export default class CreateEventLWC extends NavigationMixin(LightningElement) {  
    @api recordId;
   
    @track data = [];
    @track columns = columns;
    @track deleteRows = [];

    @track isDisplayTicketHeader = false;

    eventObject = Event_OBJECT;
    eventticketObject = EventTicket_OBJECT;
    nameField = NAME_FIELD;
    startdateField = STARTDATE_FIELD;
    enddateField = ENDDATE_FIELD;
    timezoneField = TIMEZONE_FIELD;
    descriptionField = DESCRIPTION_FIELD;
    cityField = CITY_FIELD;
    venuenameField = VENUENAME_FIELD;
    stateField = STATE_FIELD;
    streetField = STREET_FIELD;
    postalcodeField = POSTALCODE_FIELD;
    countryField = COUNTRY_FIELD;
    
    ticketnameField = TICKETNAME_FIELD;
    ticketTypeField = TICKETTYPE_FIELD;
    ticketPriceField = PRICE_FIELD;
    ticketQuantityField = QUANTITY_FIELD;
    ticketStartDateField = TICKETSTARTDATE_FIELD;
    ticketEndDateField = TICKETENDDATE_FIELD;
    
    @track ticketNameValue = 'General admission';
    @track ticketTypeValue = 'Free';
    @track ticketPriceValue = 0;
    @track ticketQuantityValue = 100;   

    @track isTicket = true;
    @track isEventCreated = false;
    @track isEventPublished = false;
    @track isDataSeeded = true;
    @track previewLink;
    @track bitpodConfig;

    
    @track isDisabledBasicInfo = true;
    @track isDisabledLocation = true;
    @track isDisabledTickets = true;
    @track isDisabledSave = true;
    @track isDisabledTickets = false;
    @track isValidationMessage = false;
    @track ValidationMessage = ALL_FIELDS_REQUIRED;
    @track selectedTab;
    @track isBitpodSetup = true;
    @track isPublishError = false;
    selectedRecords;
    

    @track isPrice = true;
    

    getFieldChange(){
        var inputEventName = this.template.querySelector('[data-id="EventName"]');
        var inputStartDate = this.template.querySelector('[data-id="StartDate"]');
        var inputEndDate = this.template.querySelector('[data-id="EndDate"]');
        var inputTimeZone = this.template.querySelector('[data-id="TimeZone"]');
        var inputVenueName = this.template.querySelector('[data-id="VenueName"]');

        var inputTicketName = this.template.querySelector('[data-id="TicketName"]');
        var inputType = this.template.querySelector('[data-id="Type"]');
        var inputTicketStartDate = this.template.querySelector('[data-id="TicketStartDate"]');
        var inputTicketEndDate = this.template.querySelector('[data-id="TicketEndDate"]');
           
        if(inputType != null && inputType.value === 'Free'){ 
            this.template.querySelector('[data-id="Price"]').value = 0.0;
            this.isPrice = true;
        }
        else if(inputType === null) 
            this.isPrice = true;      
        else 
           this.isPrice = false;
        
        // check for Basic info
        if(inputEventName !== null && inputEventName.value !== "" && inputStartDate.value !== null && (inputEndDate.value !== null) && inputTimeZone.value !== "" ) { 
            this.isDisabledBasicInfo = false;
            this.isValidationMessage = false;
        }
        else
            this.isDisabledBasicInfo = true;  
        if(inputStartDate.value !== null && inputEndDate.value !== null && inputStartDate.value > inputEndDate.value) { 
            this.ValidationMessage = EVENT_START_END_DATE;
            this.isDisabledBasicInfo = true;
            this.isValidationMessage = true;
        }
        else
            this.isValidationMessage = false;

        // check for Location
        if(inputVenueName != null && inputVenueName.value !== "")
            this.isDisabledLocation = false;  
        else
            this.isDisabledLocation = true;  
            
        //check for Tickets  
        if(inputTicketName == null )
            this.isDisabledTickets = false;
        else if(inputTicketName !== null && inputTicketName.value !== "" && inputType.value !== '' && inputTicketStartDate.value !== null && inputTicketEndDate.value !== null ) { 
            this.isDisabledTickets = false;
            console.log('==inputTicketEndDate='+inputTicketEndDate.value );
        }
        else
            this.isDisabledTickets = true;  
      
        // check ticket start date should not be greater than end date    
        if(inputTicketName !== null && inputTicketStartDate.value !== null && inputTicketEndDate.value !== null && inputTicketStartDate.value > inputTicketEndDate.value) { 
            this.ticketValidationMessage = TICKET_START_DT_MSG;
            this.isDisabledTickets = true;
            this.isTicketValidationMessage = true;
        }
        else if(inputTicketName !== null && inputTicketStartDate.value !== null && inputTicketEndDate.value !== null && inputEndDate.value < inputTicketEndDate.value) { 
            this.ticketValidationMessage = TICKET_END_DT_MSG;
            this.isDisabledTickets = true;
            this.isTicketValidationMessage = true;
        }
        else
            this.isTicketValidationMessage = false;     
    }

    tabselect(evt) {
        var tabNumber = (this.template.querySelector('lightning-tabset').activeTabValue).split('-')[1];        
        var tabValue  ;
        var inputStartDate = this.template.querySelector('[data-id="StartDate"]');
        var inputEndDate = this.template.querySelector('[data-id="EndDate"]');
        var inputVenueName = this.template.querySelector('[data-id="VenueName"]');  
        
        if(inputVenueName === null || inputVenueName.value === "" || inputVenueName.value === null)
            this.isDisabledLocation = true;       
        try {
            if(this.isDisabledBasicInfo === true && evt.target.label === 'Location') {  
                this.verifyPastDates();   
                tabValue = Number(tabNumber) - 1;
                this.template.querySelector('lightning-tabset').activeTabValue = 'tab-'+tabValue;
                if(inputStartDate.value !== null && inputEndDate.value !== null && inputStartDate.value > inputEndDate.value)
                    this.ValidationMessage = EVENT_START_END_DATE;
                else
                    this.ValidationMessage = ALL_FIELDS_REQUIRED;
                this.isValidationMessage = true;
                
            }
            if(this.isDisabledBasicInfo === true && evt.target.label === 'Tickets') { 
                tabValue = Number(tabNumber) - 2;
                this.template.querySelector('lightning-tabset').activeTabValue = 'tab-'+tabValue;
                if(inputStartDate.value !== null && inputEndDate.value !== null && inputStartDate.value > inputEndDate.value)
                    this.ValidationMessage = EVENT_START_END_DATE;
                else
                    this.ValidationMessage = ALL_FIELDS_REQUIRED;
                this.isValidationMessage = true;                
            }
            if(this.isDisabledBasicInfo === false && this.isDisabledLocation === true && evt.target.label === 'Tickets') { 
                tabValue = Number(tabNumber) - 1;
                this.template.querySelector('lightning-tabset').activeTabValue = 'tab-'+tabValue;
                if(inputStartDate.value !== null && inputEndDate.value !== null && inputStartDate.value > inputEndDate.value)
                    this.ValidationMessage = EVENT_START_END_DATE;
                else
                    this.ValidationMessage = ALL_FIELDS_REQUIRED;
                this.isValidationMessage = true;                
            }
         
            this.selectedTab =  evt.target.label;
        } catch (error) {
            console.log('==error=='+error);
        }
    }

    handleClick(event) {
        var isValidTickets = true;   
        var isValidTicketMap;   
        var tabValue  ; 
        var tabNumber = (this.template.querySelector('lightning-tabset').activeTabValue).split('-')[1];          
        
        this.isTicketValidationMessage = false;
        this.isValidationMessage = false;      

        let eventObj = { 'sobjectType': 'Event__c' };
        this.clickedButtonLabel = event.target.label;

        //Below are Event__c object basic info fields
        eventObj.Name = this.template.querySelector('[data-id="EventName"]').value;
        eventObj.bitpod__Start_Date__c = this.template.querySelector('[data-id="StartDate"]').value;
        eventObj.bitpod__End_Date__c = this.template.querySelector('[data-id="EndDate"]').value;
        eventObj.bitpod__Timezone__c = this.template.querySelector('[data-id="TimeZone"]').value;
        eventObj.bitpod__Description__c = this.template.querySelector('[data-id="Description"]').value;
        eventObj.bitpod__Status__c = 'Not Ready';
        eventObj.bitpod__Organizer__c = this.organizername;
        eventObj.bitpod__Event_Manager__c = this.eventorganizer;

         //Below are Event__c object address fields
        eventObj.bitpod__Venue_name__c = this.template.querySelector('[data-id="VenueName"]').value;
        eventObj.bitpod__Street__c = this.template.querySelector('[data-id="Street"]').value;
        eventObj.bitpod__City__c = this.template.querySelector('[data-id="City"]').value;
        eventObj.bitpod__State__c = this.template.querySelector('[data-id="State"]').value;
        eventObj.bitpod__Country__c = this.template.querySelector('[data-id="Country"]').value;
        eventObj.bitpod__Zip_Code__c = this.template.querySelector('[data-id="PostalCode"]').value;
       
        eventObj.bitpod__Capture_Point__c = 'Salesforce';
                
      
        isValidTicketMap = this.data.map((ticket, index) => {
            console.log('==index=='+index);           
            if(eventObj.bitpod__End_Date__c  < ticket.bitpod__End_Date__c)
                isValidTickets = false;

            return isValidTickets;           
        });
        console.log('==isValidTicketMap=='+isValidTicketMap);
        if(isValidTickets){ 
             //call to apex method to create event
           createEvent({eventRecord: eventObj, ticketRecords:this.data})
           .then(result => {
               var apexResponse=JSON.parse(result);
               var isSuccess=apexResponse.isSuccess;
               console.log('==isSuccess='+isSuccess);
               if(isSuccess===true){
                   this.isEventCreated = true;
                   this.isTicket = false;
                   this.recordId = apexResponse.eventRecordId;               
               }
           
            })
            .catch(error => {
                console.log('response catch==error=='+JSON.stringify(error));
                console.log(error);
                this.error = error;
            });
           
        }
        else{   
            console.log('=not=isValidTickets==');           
            this.ValidationMessage = VALID_TICKET_MSG;
            this.isValidationMessage = true;  
            tabValue = Number(tabNumber) ;
            this.template.querySelector('lightning-tabset').activeTabValue = 'tab-'+tabValue;          
        }
    }
  

    addTicket(event){     
        var tabValue  ; 
        var tabNumber = (this.template.querySelector('lightning-tabset').activeTabValue).split('-')[1];     
        var eventEndDate = this.template.querySelector('[data-id="EndDate"]').value;
        console.log('==data=='+this.data); 
        
        this.clickedButtonLabel = event.target.label;
        
        let addrow = {};
        addrow.Name = this.template.querySelector('[data-id="TicketName"]').value;
        addrow.bitpod__Price__c = this.template.querySelector('[data-id="Price"]').value;
        addrow.bitpod__Type__c = this.template.querySelector('[data-id="Type"]').value;
        addrow.bitpod__Quantity__c = this.template.querySelector('[data-id="Quantity"]').value;  
        addrow.bitpod__Start_Date__c = this.template.querySelector('[data-id="TicketStartDate"]').value;     
        addrow.bitpod__End_Date__c = this.template.querySelector('[data-id="TicketEndDate"]').value;      
        addrow.bitpod__Start_Date__c = addrow.bitpod__Start_Date__c.split('T')[0];
        addrow.bitpod__End_Date__c = addrow.bitpod__End_Date__c.split('T')[0];
       
        if(eventEndDate  < this.template.querySelector('[data-id="TicketEndDate"]').value){             
            this.ValidationMessage = EVENT_TICKET_END_DT_MSG;
            this.isValidationMessage = true;  
            tabValue = Number(tabNumber) ;
            this.template.querySelector('lightning-tabset').activeTabValue = 'tab-'+tabValue;  
        }
        else{
            this.isDisplayTicketHeader = true;
            addrow.index = addrow.length - 1;
            this.data.push(addrow);
            this.isDisabledSave = false;
        }
    }

    previewEvent(){       
        window.open(this.previewLink,'_blank');
    }

    publishEvent(event){
        console.log('==publishEvent=='+event);        
        publish({eventId: this.recordId, objectName: 'Event__c'})
            .then(result => {
                var apexResponse=JSON.parse(result);               
                if(apexResponse.IsSuccessEvent === true || apexResponse.IsSuccessTicket === true || apexResponse.IsSuccessImage === true || apexResponse.IsDeleteChild === true){ 
                    this.isEventCreated = false;
                    this.isEventPublished = true;  
                    this.isBitpodSetup = true;
                    this.previewLink = apexResponse.previewLink;   
                }
                else if(apexResponse.BitpodConfigStatus === false){
                    this.isBitpodSetup = false;
                    this.isEventCreated = false;
                    this.isEventPublished = false;  
                }
                else{
                    this.isBitpodSetup = true;
                    this.isEventCreated = false;
                    this.isEventPublished = false;  
                    this.isPublishError = true;
                }
        })
       
    }

    closeEvent(event){
        console.log('==closeEvent=='+event);
         this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    "recordId": this.recordId,
                    "objectApiName": "Event__c",
                    "actionName": "view"
                },
            }); 
    }

    gotoNextTab(){
        var tabNumber = (this.template.querySelector('lightning-tabset').activeTabValue).split('-')[1];
        var tabValue = Number(tabNumber) + 1;  
        
        this.verifyPastDates();   
      
        this.template.querySelector('lightning-tabset').activeTabValue = 'tab-'+tabValue;
    }

    gotoPrevTab(){
        var tabNumber = (this.template.querySelector('lightning-tabset').activeTabValue).split('-')[1];
        var tabValue = Number(tabNumber) - 1;
        
        this.template.querySelector('lightning-tabset').activeTabValue = 'tab-'+tabValue;
    }

    verifyPastDates(evt){
        var tabValue  ; 
        var tabNumber = (this.template.querySelector('lightning-tabset').activeTabValue).split('-')[1];     
        var startDate = this.template.querySelector('[data-id="StartDate"]').value;
        var currentDateTime = new Date().toISOString();
        
        if(currentDateTime > startDate){             
            this.ValidationMessage = EVENT_START_DATE;
            this.isValidationMessage = true;  
            tabValue = Number(tabNumber) - 1;
            this.template.querySelector('lightning-tabset').activeTabValue = 'tab-'+tabValue;  
            this.selectedTab =  evt.target.label;  
        }
    }

    deleteTicket(event){
        this.data.splice(event.target.name,1); 
        if(this.data.length === 0 ){ 
            this.isDisabledSave = true;
            this.isDisplayTicketHeader = false;
        }
    }

    @track user;
    @track error;
    @track eventstartdate;
    @track eventenddate;
    @track ticketstartdate;
    @track ticketenddate;
  
    
    @track timezone;
    @track organizername;
    @track eventorganizer;
    @track currencycode;

    @wire(getCurrentUserAndEventDate)
    wiredUser({error,data}) 
    {
        var apexResponse;
        if (data) {
            console.log('==user data='+data);
            apexResponse=JSON.parse(data);
            
            this.user = data;            
            this.timezone = apexResponse.timezone;
            this.eventstartdate = apexResponse.startDate;
            this.eventenddate = apexResponse.endDate;
            this.ticketstartdate = apexResponse.ticketStartDate;
            this.ticketenddate = apexResponse.ticketEndDate;
            this.bitpodConfig = apexResponse.bitpodConfigObj;
            this.organizername = apexResponse.currentuser.Name;
            this.eventorganizer = apexResponse.currentuser.Email;
            this.currencycode = apexResponse.currencyCode;
            
            if(this.bitpodConfig.Access_Key__c != null && this.bitpodConfig.Secret_Key__c != null && this.bitpodConfig.Endpoint__c != null ) 
                this.isDataSeeded = true;
            else 
                this.isDataSeeded = false;
            
        } else if (error) {
            console.log('==user error='+error);
            this.error = error;
        }
    }
}