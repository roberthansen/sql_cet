USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetValidationCount]    Script Date: 12/16/2019 1:50:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[GetValidationCount]
         @JobID INT,
		 @Count INT OUTPUT
AS

BEGIN

	SELECT @Count = COUNT(*) FROM [InputValidation]
	--SELECT @Count = Count(*)  FROM SavedValidation   WHERE JobID = @JobID
END



GO


