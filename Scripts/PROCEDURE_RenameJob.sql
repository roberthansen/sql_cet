USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[RenameJob]    Script Date: 2019-12-16 1:59:39 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[RenameJob]
         @JobID INT,
		 @NewName VARCHAR(255)
AS

BEGIN

	UPDATE [CETJobs] SET JobDescription = @NewName WHERE ID = @JobID

END








GO


