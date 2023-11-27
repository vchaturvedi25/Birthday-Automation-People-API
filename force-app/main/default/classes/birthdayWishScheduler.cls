global class birthdayWishScheduler implements Schedulable{
	global void execute(SchedulableContext sc) {
      chatGPTCalloutBatch b = new chatGPTCalloutBatch(); 
      Database.executeBatch(b,1);
   }
}