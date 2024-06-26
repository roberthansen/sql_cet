/*
################################################################################
Name             :  InputMeasurevw
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This view 1) sets the core variables for cost effectiveness
				 :  calculations, 2) handles nulls, 3) calculates quarters based
				 :  on first year of implementation, and 4) calculates
				 :  calculated fields.
Usage            :  n/a
Called by        :  n/a
Copyright        :  Developed by Pinnacle Consulting Group (aka Intech Energy,
				 :  Inc.) for California Public Utilities Commission (CPUC), All
				 :  Rights Reserved
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2021-05-25  Robert Hansen added fields for fuel substitution
                 :              and refrigerants, and removed MEBens and MECost
                 :              fields
                 :  2021-06-16  Robert Hansen commented out new fields for fuel
                 :              substitution for implementation at a later date
                 :  2022-09-22  Robert Hansen added water energy fields:
                 :                + Gal1
                 :                + Gal2
                 :                + kWhWater1
                 :                + kWhWater2
                 :                + kWhTotalWater1
                 :                + kWhTotalWater2
                 :  2023-02-07  Robert Hansen added a WaterUse field for
                 :              tracking water-energy nexus measures and removed
                 :              extra water-energy fields not used in CET
                 :              calculations:
                 :                + UnitGalWater1stBaseline aka UWSGal, Gal1
                 :                + UnitGalWater2ndBaseline aka UWSGal_ER, Gal2
                 :                + UnitkWhTotalWater1stBaseline aka
                 :                  UESkWh_TotalWater, kWhTotalWater1
                 :                + UnitkWhTotalWater2ndBaseline aka
                 :                  UESkWh_TotalWater_ER, kWhTotalWater2
				 :  2024-04-23  Robert Hansen renamed "PA" field to
				 :       		"IOU_AC_Territory"
				 :  2024-06-23  Robert Hansen reverted "IOU_AC_Territory" to
				 :				"PA"
################################################################################
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
		,0 kWhWater1
		,0 kWhWater2
		,'' WaterUse
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
	  FROM MappingProgramvw AS m 
	  WHERE m.PrgID NOT IN (SELECT PrgID FROM dbo.MappingMeasurevw)
	  GROUP BY m.JobID, m.PA, m.PrgID

GO