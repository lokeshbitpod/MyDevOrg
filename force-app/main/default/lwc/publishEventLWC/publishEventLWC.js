import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getEvent from '@salesforce/apex/CreateEventController.getEvent';
import publish from '@salesforce/apex/BitpodPublish.publish';
/* eslint-disable no-console */
 /* eslint-disable no-alert */
export default class PublishEventLWC extends NavigationMixin(LightningElement){ 
    @track previewLink = null;
    @track isSync = false;
    @track openmodel = false;
    @track isPublished = false;
    @track isError = false;
    @track isBitpodSetup = true;

    async connectedCallback() {
        this.path = window.location.pathname;
        this.recordId = this.path.split('/')[4];
        this.isEventPublished = true;
        getEvent({recordId: this.recordId})
        .then(result => {               
            var apexResponse=JSON.parse(result);
            console.log('==success='+apexResponse.status);
            if(apexResponse.previewlink !== null){
                this.previewLink = apexResponse.previewlink;
            }
            if(apexResponse.isSync !== null){
                this.isSync = apexResponse.isSync;
            }
        })         
    }

    previewEvent(){
        console.log('==previewEvent=='+this.previewLink);
        if(this.previewLink != null)
            window.open(this.previewLink,'_blank');
        else
            console.log('preview link is not available');
    }

    publishEvent(){
        this.openmodel = true;
    }

    clickPublishButton(){
        console.log('==clickPublishButton==');
        publish({eventId: this.recordId, objectName: 'Event__c'})
            .then(result => {
                var apexResponse=JSON.parse(result);
                console.log('=publishevent=result=='+result);  
                           
                if((apexResponse.ReadyToEventPublish === true && apexResponse.IsSuccessEvent === true) || (apexResponse.ReadyToTicketPublish === true && apexResponse.IsSuccessTicket === true) || (apexResponse.ReadyToImagePublish === true && apexResponse.IsSuccessImage === true) || apexResponse.IsDeleteChild === true){ 
                    this.isPublished = true;
                    this.isError =false;
                    this.openmodel = false;
                    this.isBitpodSetup = true;
                }
                else if(apexResponse.BitpodConfigStatus === true && apexResponse.ReadyToEventPublish === false && apexResponse.ReadyToTicketPublish === false && apexResponse.ReadyToTicketPublish === false && apexResponse.IsDeleteChild === false){ 
                    this.isPublished = true;
                    this.isError =false;
                    this.openmodel = false;
                    this.isBitpodSetup = true;
                }
                else if(apexResponse.BitpodConfigStatus === false){
                    this.isBitpodSetup = false;
                    this.isPublished = false;
                    this.isError =false;
                    this.openmodel = false;
                }
                else{
                    this.isError =true;
                    this.openmodel = false;
                    this.isPublished = false;
                    this.isBitpodSetup = true;
                }
        })
    }

    CancelPublish(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": this.recordId,
                "objectApiName": "Event__c",
                "actionName": "view"
            },
        }); 
    }
}