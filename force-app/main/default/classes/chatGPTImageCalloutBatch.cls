global class chatGPTImageCalloutBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	
    private static String CHAT_GPT_KEY = System.label.ChatGPTKey; //Custom Label
    private static final String ENDPOINT ='https://api.openai.com/v1/images/generations';
    global final String query = 'Select Id, BirthdayMessage__c, FirstName, LastName, email, Notes__c from Contact WHERE BirthDate = TODAY';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contact> conList) {
            Contact testCon = conList[0];
        	Http http = new Http();
            String reqBody = '{"prompt": "disney character with birthday cake", "n": 1 ,"size" : "512x512", "response_format": "b64_json"}';
            System.debug('Query '+reqBody);
            HttpRequest request = new HttpRequest();
            request.setEndpoint(ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer '+String.escapeSingleQuotes(CHAT_GPT_KEY).trim());
            //Setting timeout to 30 seconds to get whole response from Chat GPT Open API
            request.setTimeout(50000);
            request.setHeader('Content-Type', 'application/json');
            // Set the body as a JSON object
            request.setBody(reqBody);
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if(response.getStatusCode() == 200) {
                System.debug('image data is '+ response);
                JSONParser parser = JSON.createParser(response.getBody());
                while(parser.nextToken()!=null){
                    if((parser.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser.getText() == 'b64_json'){
                        parser.nextToken();
                        ContentVersion cversion = new ContentVersion();
                        cversion.Description = 'test_OpenAI_API Image';
                        cversion.PathOnClient = 'testDocument'+Math.random()*10+'.jpg';
                        cversion.title = 'test image';
                        cversion.VersionData = parser.getBlobValue();
                        insert cversion;
                        
                        ContentDocumentLink cdLink = new ContentDocumentLink();
                        cdLink.ContentDocumentId = [Select Id, ContentDocumentId from ContentVersion where Id=: cversion.Id].ContentDocumentId;
                        cdLink.LinkedEntityId = testCon.Id;
                        cdLink.ShareType = 'V';
                        insert cdLink;
                        
                    }
                }
            }
        
        }
        
    global void finish(Database.BatchableContext BC) {
       Database.executeBatch(new sendBdayEmailBatch(),500);
    }
    
    
}