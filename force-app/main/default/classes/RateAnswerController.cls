/**
 * @description Controller class for getting and updating rating related information for an answer
 * 
 * @author vikrant.goswami
 * 
 * @date 10-05-2024 @see RateAnswerController_TEST
 */
public with sharing class RateAnswerController {

    /**
     * @description This method is used to get the voting record for a record and user
     * 
     * @param recordId The id of the record for which to get the voting record
     * @param userId The id of the user
     * 
     * @return The voting record wrapper
     */
    @AuraEnabled(cacheable=true)
    public static VoteRecordWrapper getVoteRecordForCurrentUser(String recordId, String userId) {
        VoteRecordWrapper voteRecordWrapper = new VoteRecordWrapper();
        try {
            Vote_Record__c voteRecord = [SELECT Id, Vote__c, User_Voted__c, Record_Id__c 
                                          FROM Vote_Record__c
                                          WHERE Record_Id__c = :recordId 
                                          AND User_Voted__c = :userId 
                                          ORDER BY CreatedDate DESC 
                                          LIMIT 1];
            if(voteRecord != null) {
                voteRecordWrapper.message = 'Success';
                voteRecordWrapper.selectedVote = voteRecord.Vote__c;
            } else {
                voteRecordWrapper.message = 'No vote record found';
            }
        } catch (QueryException exc) {
            voteRecordWrapper.message = 'Error: ' + exc.getMessage();
        }
        return voteRecordWrapper;
    }


    /**
     * @description This method is used to record a vote for a user on a record
     * 
     * @param recordId The id of the record for which to record the vote
     * @param userId The id of the user
     * @param objectApiName The API name of the object
     * @param voteSelected The vote selected (Upvote or Downvote)
     * @param alreadyVoted Indicates if the user has already voted on the record
     * 
     * @return The vote insertion wrapper
     */
    @AuraEnabled
    public static VoteInsertedWrapper recordVoteForUser(String recordId, String userId, String objectApiName, String voteSelected, Boolean alreadyVoted) {
        VoteInsertedWrapper voteInsertWrapper = new VoteInsertedWrapper();
        Savepoint sp = Database.setSavepoint();
        try {
            Answer__c answer = [SELECT Id, AnswerRating__c FROM Answer__c WHERE Id = :recordId];
            if (answer != null) {
                answer.AnswerRating__c = getCalculatedRating(answer.AnswerRating__c, voteSelected, alreadyVoted); 
                update answer;

                Vote_Record__c voteRecord = new Vote_Record__c(Object_API_Name__c = objectApiName, User_Voted__c = userId, Record_Id__c = recordId, Vote__c = voteSelected);
                insert voteRecord;

                voteInsertWrapper.message = 'Success';
            } else {
                voteInsertWrapper.message = 'Answer not found';
            }
        } catch (Exception exc) {
            Database.rollback(sp);
            voteInsertWrapper.insertionError = true;
            voteInsertWrapper.message = 'Error: ' + exc.getMessage();
        }
        return voteInsertWrapper;
    }

    private static Decimal getCalculatedRating(Decimal answerRating, String voteSelected, Boolean alreadyVoted) {
        if(voteSelected == 'Upvote') {
            answerRating = (alreadyVoted == true) ? answerRating + 2 : answerRating + 1;
        } else {
            answerRating = (alreadyVoted == true) ? answerRating - 2 : answerRating - 1;
        }
        return answerRating;
    }

    @TestVisible
    private class VoteRecordWrapper {
        @AuraEnabled 
        public String message {get;set;}

        @AuraEnabled 
        public String selectedVote {get;set;}
    }

    @TestVisible
    private class VoteInsertedWrapper {
        @AuraEnabled 
        public Boolean insertionError {get;set;}

        @AuraEnabled 
        public String message {get;set;}
    }        
}