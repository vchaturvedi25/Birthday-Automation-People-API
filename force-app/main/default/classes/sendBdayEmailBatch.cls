global class sendBdayEmailBatch implements Database.Batchable<sObject>{
    
    global final String query = 'Select Id, BirthdayMessage__c, FirstName, LastName, email from Contact WHERE BirthDate = TODAY';
    
     global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contact> conList) {
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Contact testCon: conList){
            List<String> toAddresses = new List<String>();
            toAddresses.add(testCon.Email);
            System.debug('toaddress is '+ toaddresses);
            Messaging.SingleEmailMessage mymail = new Messaging.SingleEmailMessage();
            mymail.setToAddresses(toAddresses);
            mymail.setSubject('Happy Birthday '+testCon.FirstName);
            mymail.setHtmlBody(testCon.BirthdayMessage__c+ '<br> - Vishal');
            mymail.setSenderDisplayName('Vishal Chaturvedi');
            List<Messaging.EmailFileAttachment> emailFileAttList = getContentVers(testCon.Id, testCon.FirstName);
             if(emailFileAttList.size() > 0) {
                 mymail.setFileAttachments(emailFileAttList);   
            }
            emailList.add(mymail);
        }
        
        Messaging.SendEmailResult [] resList = Messaging.sendEmail(emailList);
        
    }
    
     global void finish(Database.BatchableContext BC) {
       
    }
    
    public static List<Messaging.EmailFileAttachment> getContentVers(Id objId, String FirstName) {  
        List<Messaging.EmailFileAttachment> emailAttachList = new List<Messaging.EmailFileAttachment>();
        List<ContentDocumentLink> CDLs = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: objId];
        List <Id> CDIdList = new List <Id> ();
        for (ContentDocumentLink nextCDL : CDLs) {
            CDIdList.add(nextCDL.ContentDocumentId); 
        }
        List<ContentDocument> entries = [SELECT Id, Title, FileType FROM ContentDocument WHERE ContentDocument.Id IN :CDIdList];
        if(entries.size() > 0) {
            List<ContentVersion> cvList = [SELECT Id, title, VersionData, FileExtension, ContentDocumentId 
                                           FROM ContentVersion 
                                           WHERE ContentDocumentId IN:entries 
                                           And isLatest = true];
            for(ContentVersion cvObj : cvList) {
                emailAttachList.add(setEmailFileAtt(cvObj, FirstName));            
            }
            return emailAttachList;
        }
        return emailAttachList;
    }
    
    public static Messaging.EmailFileAttachment setEmailFileAtt(ContentVersion cvObj, String FirstName) {
        Messaging.EmailFileAttachment emlAtt = new Messaging.EmailFileAttachment();
        Blob fileData = cvObj.VersionData;
        emlAtt.setFilename('HappyBirthday'+FirstName+'.' + cvObj.FileExtension);
        emlAtt.setBody(fileData);
        return emlAtt;
    }
}
