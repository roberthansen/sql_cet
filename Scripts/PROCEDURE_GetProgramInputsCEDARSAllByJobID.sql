USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetProgramInputsCEDARSAllByJobID]    Script Date: 2019-12-16 1:45:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetProgramInputsCEDARSAllByJobID]
         @JobID INT
AS
BEGIN

DECLARE @SourceType varchar(255)

SET @SourceType = (SELECT SourceType FROM dbo.CETJobs WHERE ID = @JobID ) 
PRINT 'Source Type = ' + @SourceType

IF @SourceType = 'CEDARS' OR @SourceType = 'CEDARSDatabase'
BEGIN  

SELECT 
       [PrgID]
      ,[PrgYear]
	    ,[ClaimYearQuarter]
      ,[AdminCostsOverheadAndGA]
      ,[AdminCostsOther]
      ,[MarketingOutreach]
      ,[DIActivity]
      ,[DIInstallation]
      ,[DIHardwareAndMaterials]
      ,[DIRebateAndInspection]
      ,[EMV]
      ,[UserInputIncentive]
      ,[OnBillFinancing]
      ,[CostsRecoveredFromOtherSources]
      ,[PA]
  FROM [dbo].[SavedProgramCostCEDARS]
  WHERE JobID = @JobID
  
  END

IF @SourceType NOT IN ('CEDARS','CEDARSDatabase')
BEGIN
PRINT 'SELECTING FROM CEDARS'

SELECT 
       [PrgID]
      ,[ProgramName]
      ,SUBSTRING([Year],1,4) [PrgYear]
	    ,[Year] ClaimYearQuarter
      ,[AdminCostsOverheadAndGA]
      ,[AdminCostsOther]
      ,[MarketingOutreach]
      ,[DIActivity]
      ,[DIInstallation]
      ,[DIHardwareAndMaterials]
      ,[DIRebateAndInspection]
      ,[EMV]
      ,[UserInputIncentive]
      ,[OnBillFinancing]
      ,[CostsRecoveredFromOtherSources]
  	  ,[PA]
  FROM [dbo].[SavedProgramCost]
  WHERE JobID = @JobID

END

END



GO


