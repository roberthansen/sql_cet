USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetValidationsAllByJobID]    Script Date: 12/16/2019 1:51:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO










CREATE PROCEDURE [dbo].[GetValidationsAllByJobID]
         @JobID INT
AS
BEGIN

SELECT DISTINCT 
	   k.[PA]
	  ,k.[PrgID]
      ,k.[CET_ID]
      ,k.TS [ElecTargetSector]
      ,k.EU [ElecEndUseShape]
      ,k.CZ [ClimateZone]
      ,k.GS [GasSector]
      ,k.GP [GasSavingsProfile]
      ,k.Qtr [ClaimYearQuarter]
      ,v.[MessageType] MessageType
  FROM [SavedValidation] v
  LEFT JOIN SavedInput k ON v.CET_ID = k.CET_ID
  WHERE  v.JobID = @JobID  AND k.JobID = @JobID

 
END


















GO


