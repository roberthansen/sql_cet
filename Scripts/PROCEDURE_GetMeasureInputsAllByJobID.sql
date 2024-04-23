USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetMeasureInputsAllByJobID]    Script Date: 2019-12-16 1:33:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetMeasureInputsAllByJobID]
         @JobID INT
AS
BEGIN

SELECT ROW_NUMBER() OVER (ORDER BY c.ID ASC) AS Row
	   ,c.[CET_ID]
      ,c.[IOU_AC_Territory]
      ,c.[PrgID]
	  ,k.ProgramName
      ,k.[MeasureName]
      ,k.[MeasureID]
      ,k.TS [ElecTargetSector]
      ,k.EU [ElecEndUseShape]
      ,k.CZ [ClimateZone]
      ,k.GS [GasSector]
      ,k.GP [GasSavingsProfile]
      ,k.Qtr [ClaimYearQuarter]
      ,k.[Qty]
      ,k.kW1 [UESkW]
      ,k.kWh1 [UESkWh]
      ,k.Thm1 [UESThm]
      ,k.kW2 [UESkW_ER]
      ,k.kWh2 [UESkWh_ER]
      ,k.Thm2 [UESThm_ER]
      ,k.[EUL]
      ,k.[RUL]
      ,k.[NTGRkW]
      ,k.[NTGRkWh]
      ,k.[NTGRThm]
      ,k.[NTGRCost]
      ,k.[IR]
      ,k.[IRkW]
      ,k.[IRkWh]
      ,k.[IRThm]
      ,k.[RRkW]
      ,k.[RRkWh]
      ,k.[RRThm]
      ,k.[UnitMeasureGrossCost]
      ,k.[UnitMeasureGrossCost_ER]
      ,k.[EndUserRebate]
      ,k.[IncentiveToOthers]
      ,k.DILaborCost
      ,k.[DIMaterialCost]
      ,CASE WHEN k.[MEBens]=0 THEN '' ELSE k.[MEBens] END MarketEffectBens
      ,CASE WHEN k.[MECost]=0 THEN '' ELSE k.[MECost] END MarketEffectCost
      ,k.[Sector]
      ,k.[EndUse]
      ,k.[BuildingType]
      ,k.[MeasureGroup]
      ,k.[SolutionCode]
      ,k.[Technology]
      ,k.[Channel]
      ,k.[IsCustom]
      ,k.[Location]
      ,k.[ProgramType]
      ,k.[UnitType]
      ,k.[Comments]
      ,k.[DataField]
  FROM [SavedCE] c
  LEFT JOIN SavedInput k ON c.CET_ID = k.CET_ID
  --LEFT JOIN SavedSavings s on c.CET_ID = s.CET_ID
  --LEFT JOIN SavedEmissions e on c.CET_ID = e.CET_ID
  --LEFT JOIN SavedCost m on c.CET_ID = m.CET_ID
  WHERE  c.JobID = @JobID AND k.JobID = @JobID
 
END























GO


