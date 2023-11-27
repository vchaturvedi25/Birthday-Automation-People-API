public class getGoogleContacts {
    
    @AuraEnabled
    @future(callout=true) public static void getContacts(){
        
        String groupID = System.label.PeopleAPIGroup;
        String requestUri = '';
        List<Contact> deleteCons = new List<Contact>();
        List<Contact> conList = [Select Id, PeopleId__c from Contact];
        Map<String,Contact> existingPeopleIdMap = new Map<String,Contact>();
        for(Contact con: conList){
            existingPeopleIdMap.put(con.PeopleId__c, con);
        }
        Http h = new http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:GooglePeopleAPI/contactGroups/'+groupID+'?maxMembers=900');
        System.debug('request is '+request);
        HttpResponse response =  h.send(request);
        System.debug('response is '+response);
        System.debug('response body is '+ response.getBody());
        Boolean breakParse=false;
        Set<String> peopleIdList = new Set<String>();
        
        JSONParser parser = JSON.createParser(response.getBody());
        while(parser.nextToken()!=null){
            if((parser.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser.getText() == 'memberResourceNames'){
                parser.nextToken();
                parser.nextToken();
                while(parser.getText()!=']'){
                    peopleIdList.add(parser.getText());
                    parser.nextToken();
                }
                breakParse=true;
                System.debug('array is '+ peopleIdList);
            }
            if(breakParse){
                break;
            }
        }
        
        for(String peopleId: existingPeopleIdMap.keySet()){    
            if(!peopleIdList.contains(peopleId)){
                deleteCons.add(existingPeopleIdMap.get(peopleId));          
            }
        }
        
        if(!peopleIdList.isEmpty())
        {
            for(String personId: peopleIdList){ 
            	requestUri = requestUri + '&resourceNames='+personId;
        	}
        
            System.debug('existing con map is '+ existingPeopleIdMap);
            System.debug('final people id list is '+ peopleIdList);
            
            Http h2 = new http();
            HttpRequest request2 = new HttpRequest();
            request2.setMethod('GET');
            request2.setEndpoint('callout:GooglePeopleAPI/people:batchGet?personFields=names,emailAddresses,birthdays,biographies'+requestUri);
            System.debug('request is '+request2);
            HttpResponse response2 =  h.send(request2);
            System.debug('response batch is '+response2);
            System.debug('response batch body is '+ response2.getBody());
            
            List<Contact> insertConList = new List<Contact>();
            Contact newCon = new Contact();
            String day='';
            String month='';
            
            JSONParser parser2 = JSON.createParser(response2.getBody());
            while(parser2.nextToken()!=null){
    
                if((parser2.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser2.getText() == 'resourceName'){
                    parser2.nextToken();
                    newCon = new Contact();
                    day='';
                    month='';
                    newCon.PeopleId__c = parser2.getText();
                    if(existingPeopleIdMap.containsKey(parser2.getText())){
                        newCon.Id = existingPeopleIdMap.get(parser2.getText()).Id;
                    }
                }
                if((parser2.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser2.getText() == 'value'){
                    parser2.nextToken();
                    if(parser2.getText().contains('@')&parser2.getText().contains('.com')){
                        newCon.Email = parser2.getText();
                    }
                    else{
                        newCon.Notes__c = parser2.getText();
                    }
                }
                if((parser2.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser2.getText() == 'day'){
                    parser2.nextToken();
                    day = parser2.getText();
                    newCon.Birthdate = Date.newInstance(2000, Integer.valueOf(month), Integer.valueOf(day));
                }
                if((parser2.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser2.getText() == 'month'){
                    parser2.nextToken();
                    month = parser2.getText();
                }
                if((parser2.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser2.getText() == 'givenName'){
                    parser2.nextToken();
                    newCon.FirstName = parser2.getText();
                }
                if((parser2.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser2.getText() == 'familyName'){
                    parser2.nextToken();
                    newCon.LastName = parser2.getText();
                }
                if((parser2.getCurrentToken() == JSONTOKEN.FIELD_NAME) && parser2.getText() == 'status'){
                    if(newCon.LastName == null){
                        newCon.LastName = 'LNU';
                    }
                    insertConList.add(newCon);
                }
            }
            
            System.debug('inserConlist is '+ insertConList);   
            Database.upsert(insertConList,false);
            Database.delete(deleteCons,false);
            
        }    
    }
    
}