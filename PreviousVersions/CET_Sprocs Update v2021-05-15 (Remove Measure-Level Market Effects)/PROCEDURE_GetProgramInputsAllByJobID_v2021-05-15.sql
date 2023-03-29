USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetProgramInputsAllByJobID]    Script Date: 12/16/2019 1:44:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[GetProgramInputsAllByJobID]
         @JobID INT
AS
BEGIN

SELECT 
       [PA]
      ,[PrgID]
      ,[ProgramName]
      ,[Year] [ClaimYearQuarter]
      ,[AdminCostsOverheadAndGA]
      ,[AdminCostsOther]
      ,[MarketingOutreach]
      ,[DIActivity]
      ,[DIInstallation]
      ,[DIHardwareAndMaterials]
      ,[DIRebateAndInspection]
      ,[EMV]
      ,[UserInputIncentive]
      ,[CostsRecoveredFromOtherSources]
      ,[OnBillFinancing]
  FROM [dbo].[SavedProgramCost]
  WHERE JobID = @JobID
  
  END























GO


