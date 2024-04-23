USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetResultRowCount]    Script Date: 2019-12-16 1:49:52 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GetResultRowCount]
         @JobID INT,
		 @Count INT OUTPUT
AS

BEGIN

	SELECT @Count = COUNT(*)  FROM SavedCE   WHERE JobID = @JobID
END


GO


