/*
#################################################################################################
Name             :  InputMeasurevw
Date             :  06/30/2016
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This view 1) sets the core variables for cost effectiveness calculations, 2) handles nulls, 3) calculates quarters based on first year of implementation, and 4) calculates calculated fields.
Usage            :  n/a
Called by        :  n/a
Copyright �      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History   :  06/30/2016  Wayne Hauck added comment header
                 :  05/25/2021  Robert Hansen added fields for fuel
				    substitution and refrigerants, and removed
					MEBens and MECost fields
				 :  2021-06-16  Robert Hansen commented out new fields for fuel
				    substitution for implementation at a later date
				 :  2022-09-22  Robert Hansen added water energy fields:
				 :    + Gal1
				 :    + Gal2
				 :    + kWhWater1
				 :    + kWhWater2
				 :    + kWhTotalWater1
				 :    + kWhTotalWater2
#################################################################################################
*/

IF OBJECT_ID('dbo.InputMeasureNonResourcevw','V') IS NOT NULL
    DROP VIEW dbo.InputMeasureNonResourcevw
GO

CREATE VIEW [dbo].[InputMeasureNonResourcevw]
AS
	SELECT JobID 
		,m.PrgID CET_ID
	    ,m.PA
		,m.PrgID 
		,''ProgramName
		,'' MeasureName
		,'' MeasureID
		,'' TS
		,'' EU
		--,'' EUAL
		,'' CZ
		,'' GS
		,'' GP
		--,'' GPAL
		,'' ElecRateSchedule
		,'' GasRateSchedule
		,'' CombType
		,Min(m.ClaimYearQuarter) Qtr
		,4 Qm
		,1 Qy
		,0 Qty
		,0 kW1 
		,0 kWh1
		,0 Thm1
		,0 kW2
		,0 kWh2
		,0 Thm2
		--,0 kW1_AL
		--,0 kWh1_AL
		--,0 Thm1_AL
		--,0 kW2_AL
		--,0 kWh2_AL
		--,0 Thm2_AL
		,0 Gal1
		,0 Gal2
		,0 kWhWater1
		,0 kWhWater2
		,0 kWhTotalWater1
		,0 kWhTotalWater2
		,0 NTGRkW
		,0 NTGRkWh
		,0 NTGRThm
		,0 NTGRCost
		,1 IR 
		,1 IRkW
		,1 IRkWh
		,1 IRThm
		,1 RR
		,1 RRkWh
		,1 RRkW
		,1 RRThm
		,0 IncentiveToOthers
		,0 EndUserRebate
		,0 DILaborCost
		,0 DIMaterialCost
		,0 UnitMeasureGrossCost
		,0 UnitMeasureGrossCost_ER
		,0 UnitGasInfraBens
		,0 UnitRefrigCosts
		,0 UnitRefrigBens
		,0 UnitMiscCosts
		,'' MiscCostsDesc
		,0 UnitMiscBens
		,'' MiscBensDesc
		,0 eulq
 		,0 eulq1
		,0 eulq2
 		,0 eul1
		,0 eul2
		,0 rulq
		,0 EUL
		,0 RUL
		,'' ACElecKey
		,'' ACGasKey
		,0 MeasIncrCost
		,0 MeasInflation
		,'' [Sector]
		,'' [EndUse]
		,'' [BuildingType]
		,'' [MeasureGroup]
		,'' [SolutionCode]
		,'' [Technology]
		,'' [Channel]
		,'' [IsCustom]
		,'' [Location]
		,'' [ProgramType]
		,'' [UnitType]
		,'' Comments
		,'' DataField
	  FROM MappingProgramvw m 
	  WHERE m.PrgID NOT IN (SELECT PrgID FROM dbo.MappingMeasurevw)
	  Group By m.JobID,m.PA,m.PrgID






GO


