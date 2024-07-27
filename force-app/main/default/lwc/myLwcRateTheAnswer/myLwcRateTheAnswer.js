import { LightningElement, api, wire } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserVoteRecord from '@salesforce/apex/RateAnswerController.getVoteRecordForCurrentUser';
import insertVoteRecord from '@salesforce/apex/RateAnswerController.recordVoteForUser';

export default class MyLwcRateTheAnswer extends LightningElement {

    @api recordId;
    defaultVote;
    upvoted = false;
    downvoted = false;
    userId = USER_ID;
    loading = true;
    objectApiName = 'Answer__c';

    
    @wire(getUserVoteRecord, { recordId: '$recordId', userId: '$userId' })
    userVoteRecord({error, data}){
        if(data){
            if(data.message == 'Success'){
                this.defaultVote = data.selectedVote;
                if (this.defaultVote === 'Upvote') {
                    this.upvoted = true;
                }
                else {
                    this.downvoted = true;
                }
            }
        }
        else if(error){
            console.error(error);
        }
        this.loading = false;
    };



    get upvoteSelected() {
        return this.defaultVote == 'Upvote';
    }

    get downvoteSelected() {
        return this.defaultVote == 'Downvote';
    }

    handleUpvote() {
        if(this.upvoted){
            this.showToastMessage('','Already upvoted!', 'success');
        }
        else {
            this.loading = true;
            insertVoteRecord({ recordId : this.recordId, userId : this.userId, objectApiName : this.objectApiName, 
                voteSelected : 'Upvote', alreadyVoted : (this.upvoted || this.downvoted) })
            .then(response => {
                this.defaultVote = 'Upvote';
                this.upvoted = true;
                this.downvoted = false;
                this.updatePageView();
            })
            .catch(error => {
                console.error(error);
            });
            
            this.loading = false;
        }
    }

    handleDownvote() {
        this.loading = true;
        if(this.downvoted){
            this.showToastMessage('','Already downvoted!', 'warning');
        }
        else {
            insertVoteRecord({ recordId : this.recordId, userId : this.userId, objectApiName : this.objectApiName, 
                voteSelected : 'Downvote', alreadyVoted : (this.upvoted || this.downvoted) })
            .then(response => {
                this.defaultVote = 'Downvote';
                this.downvoted = true;
                this.upvoted = false;
                this.updatePageView();
                
            })
            .catch(error => {
                console.error(error);
            });
        }
        this.loading = false;
    }

    async updatePageView() {
        await notifyRecordUpdateAvailable([{recordId: this.recordId}]);
    }

    showToastMessage(title = '', message='', variant='') {
        const event = new ShowToastEvent({
            label : 'Hi',
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}