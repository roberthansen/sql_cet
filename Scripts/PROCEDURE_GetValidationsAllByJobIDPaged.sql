USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetValidationsAllByJobIDPaged]    Script Date: 2019-12-16 1:52:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetValidationsAllByJobIDPaged]
         @JobID INT
		 ,@StartRow INT = 0
		 ,@NumRows INT = 250
AS
BEGIN

SELECT  *
FROM     
(
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY c.ID ASC) AS Row
	  ,c.JobID
      ,c.[PA]
      ,c.[PrgID]
      ,c.[CET_ID]
      ,k.TS [ElecTargetSector]
      ,k.EU [ElecEndUseShape]
      ,k.CZ [ClimateZone]
      ,k.GS [GasSector]
      ,k.GP [GasSavingsProfile]
      ,k.Qtr [ClaimYearQuarter]
      ,v.[MessageType]
      ,m.[Message]
  FROM [SavedValidation] v
  LEFT JOIN CETTypeMessage m ON v.MessageType = m.ID
  LEFT JOIN SavedCE c ON v.CET_ID = c.CET_ID AND v.JobID = c.JobID
  LEFT JOIN SavedInput k ON v.CET_ID = k.CET_ID AND v.JobID = k.JobID
  WHERE  v.JobID = @JobID
  ) tmp
WHERE JobID = @JobID AND (Row >= @StartRow AND Row <= @StartRow + @NumRows)
GROUP BY Row, JobID, PA, PrgID, CET_ID,[ElecTargetSector],[ElecEndUseShape],[ClimateZone],[GasSector],[GasSavingsProfile],[ClaimYearQuarter],[MessageType],[Message]

 
END











GO


