USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetValidationsByJobID]    Script Date: 2019-12-16 1:54:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO










CREATE PROCEDURE [dbo].[GetValidationsByJobID]
         @JobID INT
AS
BEGIN

SELECT 
      v.[MessageType] MessageType
      ,m.[Message]
	  , COUNT(*) AS [MessageCount]
  FROM [SavedValidation] v
  LEFT JOIN CETTypeMessage m ON v.MessageType = m.ID
  WHERE  v.JobID = @JobID
  GROUP BY  v.[MessageType], m.Message
  ORDER BY COUNT(*) DESC
END










GO


