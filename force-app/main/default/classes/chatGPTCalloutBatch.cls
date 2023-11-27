global class chatGPTCalloutBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	
    private static String CHAT_GPT_KEY = System.label.ChatGPTKey; //Custom Label
    private static final String ENDPOINT ='https://api.openai.com/v1/chat/completions';
    global final String query = 'Select Id, BirthdayMessage__c, FirstName, LastName, email, Notes__c from Contact WHERE BirthDate = TODAY';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contact> conList) {
            Contact testCon = conList[0];
        	String BdayString;
            String seachQueryEscaped = 'Write a birthday wish with emojis for my friend '+ testCon.FirstName + ' who '+ testCon.Notes__c;
            Http http = new Http();
            String reqBody = '{"model": "gpt-4", "messages": [{"role": "user", "content": "'
                +seachQueryEscaped+
                '"}], "temperature": 0.5}';
            System.debug('Query '+seachQueryEscaped+' '+reqBody);
            HttpRequest request = new HttpRequest();
            request.setEndpoint(ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer '+String.escapeSingleQuotes(CHAT_GPT_KEY).trim());
            //Setting timeout to 30 seconds to get whole response from Chat GPT Open API
            request.setTimeout(80000);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            // Set the body as a JSON object
            request.setBody(reqBody);
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if(response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getBody());
                
            }
        	String birthdayMessage;
        	JSONParser parser = JSON.createParser(response.getBody());
            while(parser.nextToken()!=null){
                if((parser.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser.getText() == 'content'){
                    parser.nextToken();
                    birthdayMessage = parser.getText();
                    testCon.BirthdayMessage__c = parser.getText();
                }
            }
        
        	update testCon;
        }
        
    global void finish(Database.BatchableContext BC) {
       Database.executeBatch(new chatGPTImageCalloutBatch(),1);
    }
    
    
}