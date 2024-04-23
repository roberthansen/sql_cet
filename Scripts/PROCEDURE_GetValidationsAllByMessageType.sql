USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetValidationsAllByMessageType]    Script Date: 2019-12-16 1:53:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GetValidationsAllByMessageType]
		@JobID INT
        ,@MessageType VARCHAR(255)
AS
BEGIN

SELECT DISTINCT 
	   v.CET_ID
	   ,v.[Table]
	   ,v.ErrorType
	   ,v.MessageType
	   ,v.Detail
  FROM [SavedValidation] v
  WHERE  v.JobID = @JobID AND v.MessageType = @MessageType
  GROUP BY v.CET_ID,v.[Table],v.ErrorType,v.Detail,v.[MessageType]
 
END












GO


