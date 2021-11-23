-- The below query will create and schedule a job

EXEC msdb.dbo.sp_add_job  
   @job_name = N'DailyDataTransferJob',   
   @enabled = 1,   
   @description = N'Data transfer everyday' ; 
   
 EXEC msdb.dbo.sp_add_jobstep  
    @job_name = N'DailyDataTransferJob',   
    @step_name = N'Transfer Data',   
    @subsystem = N'TSQL',   
    @command = 'EXEC dbo.sp_ContactDataTransfer';

 EXEC msdb.dbo.sp_add_schedule  
    @schedule_name = N'Everyday schedule',   
    @freq_type = 4, 
    @freq_interval = 1,
    @active_start_time = '230000' ;   

 EXEC msdb.dbo.sp_attach_schedule  
   @job_name = N'DailyDataTransferJob',  
   @schedule_name = N'Everyday schedule' ;

 EXEC msdb.dbo.sp_add_jobserver  
   @job_name = N'DailyDataTransferJob',  
   @server_name = @@servername ;