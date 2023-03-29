USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetValidationSummaryByJobID]    Script Date: 12/16/2019 1:55:16 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[GetValidationSummaryByJobID]
         @JobID INT
AS
BEGIN

SELECT 
	 v.[Table]
	,v.ErrorType
	, COUNT(*) AS [MessageCount]
    ,v.[MessageType] MessageType
  FROM [SavedValidation] v
  WHERE  v.JobID = @JobID
  GROUP BY  v.[Table],v.ErrorType,v.[MessageType]
  ORDER BY v.ErrorType, COUNT(*) DESC
END













GO


