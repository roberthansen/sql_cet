USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetJobProcessTime]    Script Date: 12/16/2019 1:30:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetJobProcessTime]
         @JobID INT

AS

BEGIN

  DECLARE @retrunValue AS NVARCHAR(15) 
    SET  @retrunValue = '' 
    SET  @retrunValue = CONVERT(NVARCHAR(15), DATEDIFF(SECOND, (SELECT TOP 1 modifiedDate FROM [CETDataLoadStatusHistory] WHERE jobid = @JobID ORDER BY modifiedDate ASC), 
                          (SELECT TOP 1 modifiedDate FROM [CETDataLoadStatusHistory] WHERE jobid = @JobID ORDER BY modifiedDate DESC))) 

     SELECT @retrunValue AS ProcessTime
END


GO


