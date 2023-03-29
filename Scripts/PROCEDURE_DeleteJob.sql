USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[DeleteJob]    Script Date: 12/16/2019 1:22:25 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[DeleteJob]
         @JobID INT
AS

BEGIN

	DELETE FROM [CETJobs] WHERE ID = @JobID
	DELETE FROM [SavedCE] WHERE JobID = @JobID
	DELETE FROM [SavedCost] WHERE JobID = @JobID
	DELETE FROM [SavedEmissions] WHERE JobID = @JobID
	DELETE FROM [SavedSavings] WHERE JobID = @JobID
	DELETE FROM [SavedValidation] WHERE JobID = @JobID
	DELETE FROM [SavedInput] WHERE JobID = @JobID

END








GO


