/**
 * @description Test class for RateAnswerController
 * 
 * @author vikrant.goswami
 * 
 * @date 11-05-2024 @see RateAnswerController
 */
@isTest
private class RateAnswerController_TEST {

    @testSetup
    static void testDataSetup() {
        //Create a new Question
        Question__c testQuestion = new Question__c(Name='Test Question', Description__c='Test Description for Test Question', Status__c='Open');
        insert testQuestion;
        // Create a test answer
        Answer__c testAnswer = new Answer__c(Name = 'Test Answer', Question__c=testQuestion.Id, Description__c='Test Description For Test Answer');
        insert testAnswer;

        // Create a test vote record for the test answer
        Vote_Record__c testVoteRecord = new Vote_Record__c(
            Object_API_Name__c='Anseer__c',
            Record_Id__c = testAnswer.Id,
            User_Voted__c = UserInfo.getUserId(),
            Vote__c = 'Upvote'
        );
        insert testVoteRecord;
        
    }

    static User createQaProfileUser() {
        Profile qaProfile = [SELECT Id, Name FROM Profile WHERE Name = 'QA Forum Users' ];
        User u = new User(FirstName='Test', LastName='Name', ProfileId=qaProfile.Id, Username='testuser@qa.test.com', 
                          Email='testuser@testmail.com', Alias='tname', TimeZoneSidKey='Asia/Kolkata', 
                          LocaleSidKey='en_IN', EmailEncodingKey='UTF-8',  
                          LanguageLocaleKey='en_US');
        insert u;
        return u;
    }

    @isTest
    static void testGetVoteRecordForCurrentUser() {

        Answer__c testAnswer = [SELECT Id, AnswerRating__c FROM Answer__c WHERE Name = 'Test Answer'];

        // Test method invocation
        Test.startTest();
        RateAnswerController.VoteRecordWrapper result = RateAnswerController.getVoteRecordForCurrentUser(testAnswer.Id, UserInfo.getUserId());
        Test.stopTest();

        // Assertion
        Assert.areEqual('Success', result.message, 'Not able to get the vote record');
        Assert.areEqual('Upvote', result.selectedVote);
    }

    @isTest
    static void testRecordVoteForUser() {

        Answer__c testAnswer = [SELECT Id, AnswerRating__c FROM Answer__c WHERE Name = 'Test Answer'];
        
        // Test method invocation
        Test.startTest();
        RateAnswerController.VoteInsertedWrapper result = RateAnswerController.recordVoteForUser(testAnswer.Id, UserInfo.getUserId(), 'Answer__c', 'Upvote', false);
        Test.stopTest();

        // Assertion
        Assert.areEqual('Success', result.message, 'Unable to record vote for user.');
        Assert.areEqual(false, result.insertionError);
    }
}