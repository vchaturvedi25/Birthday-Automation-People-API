global class getGoogleContactsScheduler implements Schedulable{
	 global void execute(SchedulableContext sc){
      getGoogleContacts.getContacts();   
   }
}