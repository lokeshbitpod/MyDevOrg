import { LightningElement,track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEventCount from '@salesforce/apex/CreateEventController.getEventCount';
import getBitpodCredentials from '@salesforce/apex/CreateEventController.getBitpodCredentials';
import {
    BITPOD_VERIF_SUCCESS_MSG,
    BITPOD_VERIF_FAILURE_MSG
} from 'c/messageUtilityLwc';
/* eslint-disable no-console */
 /* eslint-disable no-alert */
export default class SetupEventLWC extends LightningElement {
    @track message;
    @track configid;
    @track accesskey;
    @track secretkey;
    @track apiurl;
    @track isApproved = false;
    @track isDisabled = true;
    _SUCCESS_MSG = BITPOD_VERIF_SUCCESS_MSG;
    _FAILURE_MSG = BITPOD_VERIF_FAILURE_MSG;


    @wire(getBitpodCredentials)
    wiredUser({error,data}) 
    {
        var apexResponse;
        if (data) {
            apexResponse=JSON.parse(data);
            this.accesskey = '*****************';
            this.secretkey = '*****************';
            this.apiurl = apexResponse.apiurl;
            this.configid = apexResponse.configid;
        } else if (error) {
            console.log('==user error='+error);
            this.error = error;

        }
    }


    getFieldChange(event){
        var inputAPIURL = this.template.querySelector('[data-id="apiurl"]');
        var inputAccessKey = this.template.querySelector('[data-id="accesskey"]');
        var inputSecretKey = this.template.querySelector('[data-id="secretkey"]');
        if(inputAPIURL.value !== "" && inputAccessKey.value !== "" && inputSecretKey.value !== "" && event.target.value !== this.apiurl) 
            this.isDisabled = false;
        else
            this.isDisabled = true;        
    }

    saveEventSetup(){
        var inputAPIURL = this.template.querySelector('[data-id="apiurl"]');
        var inputAccessKey = this.template.querySelector('[data-id="accesskey"]');
        var inputSecretKey = this.template.querySelector('[data-id="secretkey"]');

        if (inputAPIURL.value === "") {
            inputAPIURL.setCustomValidity("Please Enter API URL");
        }
        else {
            inputAPIURL.setCustomValidity(""); 
        }
        if (inputAccessKey.value === "") {
            inputAccessKey.setCustomValidity("Please Enter Access Key");
        }
        else {
            inputAccessKey.setCustomValidity(""); 
        }
        if (inputSecretKey.value === "") {
            inputSecretKey.setCustomValidity("Please Enter Secret Key");
        }else {
            inputSecretKey.setCustomValidity(""); 
        }
       
        inputAPIURL.reportValidity();
        inputAccessKey.reportValidity();
        inputSecretKey.reportValidity();
       
        if(inputAPIURL.value !== "" && inputAccessKey.value !== "" && inputSecretKey.value !== ""){ 
            getEventCount({apiurl: inputAPIURL.value,accesskey: inputAccessKey.value,secretkey: inputSecretKey.value})
                .then(result => {
                    var isSuccess=JSON.parse(result);
                    console.log('==isSuccess='+isSuccess + " " + this._SUCCESS_MSG + " " + BITPOD_VERIF_SUCCESS_MSG);
                    if(isSuccess===true){
                        this.isApproved = true;
                        this.isDisabled = true;
                        const evt = new ShowToastEvent({
                            title: 'Success',
                            message: this._SUCCESS_MSG + "",
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                    }
                    else{ 
                        this.isApproved = false;
                        const evt = new ShowToastEvent({
                            title: 'Error',
                            message: this._FAILURE_MSG,
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                    }              
            })
            .catch(error => {
                console.log(error);
                this.isApproved = false;
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: this._FAILURE_MSG,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            });
        }
    }
}