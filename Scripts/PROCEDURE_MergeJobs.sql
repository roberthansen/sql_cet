USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[MergeJobs]    Script Date: 12/16/2019 1:59:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[MergeJobs]
         @MainJobID INT,
         @TheDepartedJobID INT

AS

BEGIN
	DELETE FROM dbo.[SavedCE] WHERE JobID = @MainJobID AND CET_ID IN (SELECT j2.CET_ID FROM dbo.[SavedCE] j2 WHERE j2.JobID = @TheDepartedJobID)
	UPDATE SavedCE SET JobID = @MainJobID WHERE JobID = @TheDepartedJobID

	DELETE FROM dbo.[SavedCost] WHERE JobID = @MainJobID AND CET_ID IN (SELECT j2.CET_ID FROM dbo.[SavedCost] j2 WHERE j2.JobID = @TheDepartedJobID)
	UPDATE [SavedCost] SET JobID = @MainJobID WHERE JobID = @TheDepartedJobID

	DELETE FROM dbo.[SavedEmissions] WHERE JobID = @MainJobID AND CET_ID IN (SELECT j2.CET_ID FROM dbo.[SavedEmissions] j2 WHERE j2.JobID = @TheDepartedJobID)
	UPDATE [SavedEmissions] SET JobID = @MainJobID WHERE JobID = @TheDepartedJobID

	DELETE FROM dbo.[SavedSavings] WHERE JobID = @MainJobID AND CET_ID IN (SELECT j2.CET_ID FROM dbo.[SavedSavings] j2 WHERE j2.JobID = @TheDepartedJobID)
	UPDATE [SavedSavings] SET JobID = @MainJobID WHERE JobID = @TheDepartedJobID

	DELETE FROM dbo.[SavedValidation] WHERE JobID = @MainJobID AND CET_ID IN (SELECT j2.CET_ID FROM dbo.[SavedValidation] j2 WHERE j2.JobID = @TheDepartedJobID)
	UPDATE [SavedValidation] SET JobID = @MainJobID WHERE JobID = @TheDepartedJobID

	DELETE FROM dbo.[SavedInput] WHERE JobID = @MainJobID AND CET_ID IN (SELECT j2.CET_ID FROM dbo.[SavedInput] j2 WHERE j2.JobID = @TheDepartedJobID)
	UPDATE [SavedInput] SET JobID = @MainJobID WHERE JobID = @TheDepartedJobID

	DELETE FROM dbo.[CETJobs] WHERE ID = @TheDepartedJobID


END






GO


