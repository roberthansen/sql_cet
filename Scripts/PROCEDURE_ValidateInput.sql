USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[ValidateInput]    Script Date: 12/16/2019 2:11:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





--#################################################################################################
-- Name             :  ValidateInput
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure validates inputs for the job and saves to the InputValidation table.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
-- Change History   :  12/30/2016  Wayne Hauck added validation for EUL > years in avoided cost table
--                     
--#################################################################################################



CREATE PROCEDURE [dbo].[ValidateInput]
@JobID INT = -1,
@AVCVersion VARCHAR(255) = '2013',
@FirstYear INT = 2013


AS

SET NOCOUNT ON

-- Clear InputValidation table for Job
DELETE FROM InputValidation WHERE JobID=@JobID


--************** Start Validate Input  ***************


--************** Validate Null PA Input  ***************
insert into InputValidation 
select @JobID AS JobID, 'InputMeasure' AS [Table], 'Error' AS ErrorType, CET_ID, 'Null PA' as MessageType, '' as Detail 
from  [dbo].[InputMeasurevw] 
m where PA is null  
--************************************************************



----************** Validate Null Qtr Input  ***************
--insert into InputValidation 
--select @JobID AS JobID, 'InputMeasure' AS [Table], 'Error' AS ErrorType, CET_ID, 'Null Qtr' as MessageType, '' as Detail 
--from  [dbo].[InputMeasurevw] 
--m where Qtr is null 
----************************************************************



--************** Validate Implementation Before First Year of Implementation  ***************
insert into InputValidation 
select @JobID AS JobID, 'InputMeasure' AS [Table], 'Error' AS ErrorType, CET_ID, 'Claim Year Quarter before First Year of Implementation' as MessageType, '' as Detail 
from  [dbo].[InputMeasurevw] m 
where Convert(int,Left(m.Qtr,4)) < @FirstYear 
--************************************************************


--************** Validate Null Qty Input  ***************
insert into InputValidation 
select @JobID AS JobID, 'InputMeasure' AS [Table], 'Error' AS ErrorType, CET_ID, 'Null Quantity' as MessageType, '' as Detail 
from  [dbo].[InputMeasurevw] 
m where Qty is null 
--************************************************************



--************** Validate Null CET_ID Input  ***************
insert into InputValidation 
select @JobID AS JobID, 'InputMeasure' AS [Table], 'Error' AS ErrorType, CET_ID, 'Null CET_ID' as MessageType, '' as Detail 
from  [dbo].[InputMeasurevw] 
m where CET_ID is null 
--************************************************************



--************** Validate Null or zero UnitMeasureCost ***************
insert into InputValidation 
select @JobID AS JobID, 'InputMeasure' AS [Table], 'Warning Low' AS ErrorType, CET_ID AS ID, 'Null or zero UnitMeasureGrossCost with Rebates & Incentives and Elec Savings' as MessageType , 'UnitMeasureGrossCost=' + CASE WHEN e.UnitMeasureGrossCost is null THEN 'Null' ELSE Convert(varchar,IsNull(e.UnitMeasureGrossCost,0)) END as Detail
from  [dbo].[InputMeasurevw]  e
where ((IsNull(e.kWh1,0) > 0 AND PA <> 'SCG') OR IsNull(e.Thm1,0) > 0) and IsNull(e.UnitMeasureGrossCost,0) = 0 and (IsNUll(e.[IncentiveToOthers],0)+IsNUll(e.[EndUserRebate],0)+IsNUll(e.[DILaborCost],0)+IsNUll(e.[DIMaterialCost],0)) >0
--************************************************************



--************** Validate Duplicate Claim ID  ***************
insert into InputValidation 
select @JobID AS JobID, 'InputMeasure' AS [Table], 'Error' AS ErrorType, CET_ID, 'Duplicate CET_ID. CET_ID must be unique' as MessageType, '' as Detail
from  [dbo].[InputMeasurevw] 
 where CET_ID in
 (
	SELECT CET_ID FROM [dbo].[InputMeasurevw] GROUP BY CET_ID HAVING ( COUNT(CET_ID) > 1 )
 )
--************************************************************



----************** Validate No Matching Electric Avoided Cost  ***************
--insert into InputValidation 
--select @JobID AS JobID, 'Measure' AS [Table],'Warning High' AS ErrorType, CET_ID, 'No Match with Electric Avoided Cost table' AS MessageType, 'TS='+e.TS +',EU='+ e.EU + ',CZ='+e.CZ AS Detail 
--from InputMeasurevw e 
--where e.kWh1 <> 0 AND PA <> 'SCG' AND PA <> 'SDGE' --SDGE E3 has complex rule for TS, ignore validating SDGE
--and e.CET_ID NOT IN
--(
-- select e.CET_ID
-- from InputMeasurevw e
-- left join AvoidedCostElecvw av on e.PA = av.PA and  e.TS = av.TS and e.EU = av.EU and e.CZ = av.CZ
-- and av.Qac = 1
-- where av.CET_ID is not null
--)

--************** Validate No Matching Electric Avoided Cost  ***************
insert into InputValidation 
select @JobID AS JobID, 'Measure' AS [Table],'Warning High' AS ErrorType, CET_ID, 'No Match with Electric Avoided Cost table' AS MessageType, 'TS='+e.TS +',EU='+ e.EU + ',CZ='+e.CZ AS Detail 
from InputMeasurevw e 
where e.kWh1 <> 0 AND PA <> 'SCG' -- ignore validating SCG (gas)
and e.CET_ID NOT IN
(
 select e.CET_ID
 from InputMeasurevw e
 left join AvoidedCostComboElec av on e.PA = av.PA and  e.TS = av.TS and e.EU = av.EU and e.CZ = av.CZ
 where e.PA <> 'SCG'
 AND av.[AVCVersion] = @AVCVersion
)

--************** Validate No Matching Gas Avoided Cost  ***************
insert into InputValidation 
select @JobID AS JobID, 'Measure' AS [Table],'Warning High' AS ErrorType, CET_ID, 'No Match with Gas Avoided Cost table' AS MessageType, 'Gas Sector='+e.GS +',Gas Profile='+ e.GP AS Detail 
from InputMeasurevw e 
where e.Thm1 <> 0 AND PA <> 'SCE' 
 and e.PA + e.GS + e.GP not in
 (
	select m.PA + m.GS + m.GP from
	AvoidedCostGasvw m
)


--************** Validate Negative participant cost  ***************
insert into InputValidation 
select  @JobID AS JobID, 'Input' AS [Table], 'Warning Low' AS ErrorType, CET_ID AS ID, 'Negative Net Participant Cost' as MessageType , 'Gross Measure Cost = ' + Convert(varchar,e.UnitMeasureGrossCost) + ', Incentives = ' + Convert(varchar,(e.EndUserRebate + e.DILaborCost + e.DIMaterialCost + e.IncentiveToOthers)) as Detail 
from  dbo.InputMeasurevw e
where e.UnitMeasureGrossCost < (e.EndUserRebate + e.DILaborCost + e.DIMaterialCost + e.IncentiveToOthers)
--************************************************************


--************** Validate RUL >= EUL  ***************
insert into InputValidation 
select @JobID AS JobID, 'Measure' AS [Table], 'Warning High' AS ErrorType, CET_ID AS ID, 'RUL>=EUL will be converted to single baseline' as MessageType, 'RUL=' + Convert(varchar,IsNull(RUL,0)) + ',EUL=' + Convert(varchar,IsNull(EUL,0)) AS Detail 
from  MappingMeasurevw e 
where (IsNull(e.rul,0)>=IsNull(e.eul,0)) 
and IsNull(e.rul,0)+isNull(e.eul,0) > 0



--************** Validate Dual Baseline parameters when RUL = 0  ***************
insert into InputValidation 
select @JobID AS JobID, 'Measure' AS [Table],'Warning Low' AS ErrorType, CET_ID, 'RUL = 0 but 2nd baseline parameters <> 0' AS MessageType, 'RUL='+Convert(varchar,IsNull(e.RUL,0)) +', UESkW_ER='+Convert(varchar,IsNull(e.UESkW_ER,0)) +', UESkWh_ER='+ Convert(varchar,IsNull(e.UESkWh_ER,0)) + ', UESTherms='+Convert(varchar,IsNull(e.UESThm_ER,0))  + ', UnitMeasureGrossCost_ER='+Convert(varchar,IsNull(e.UnitMeasureGrossCost_ER,0)) AS Detail 
from MappingMeasurevw e 
where IsNull(e.RUL,0) = 0 AND (IsNull(e.UESkW_ER,0)>0 OR  IsNull(e.UESkWh_ER,0)> 0 OR IsNull(e.UESThm_ER,0) > 0 OR  IsNull(e.UnitMeasureGrossCost_ER,0)> 0)
--***********************************************************************************



--************** Validate EUL > Available Years in Avoided Cost Table  ***************
insert into dbo.InputValidation 
select @JobID AS JobID, 'Measure' AS [Table],'Warning High' AS ErrorType, CET_ID, 'EUL > years in avoided cost table' AS MessageType, 'Avoided cost version=' + Convert(varchar,2013) + ' (' + Convert(varchar,v.[LastYear]-v.BaseYear-(@FirstYear - v.BaseYear)+1) + ' years), EUL=' + Convert(varchar,e.eul)  AS Detail
from dbo.[InputMeasurevw] e,
dbo.CETAvoidedCostVersions v
where [Version] = Convert(varchar,@AVCVersion)
and v.[LastYear]-v.BaseYear-(@FirstYear - v.BaseYear)+1 < e.eul
--***********************************************************************************
----************** Validate EUL > 20  ***************
--insert into InputValidation 
--select @JobID AS JobID, 'Measure' AS [Table],'Warning High' AS ErrorType, CET_ID, 'EUL should not be greater than 20.' AS MessageType, 'EUL='+Convert(varchar,IsNull(e.EUL,0))  AS Detail 
--from MappingMeasurevw e 
--where IsNull(e.EUL,0) > 20 
----***********************************************************************************




--************** Validate RUL > EUL/2.75  ***************
insert into InputValidation 
select @JobID AS JobID, 'Measure' AS [Table], 'Warning High' AS ErrorType, CET_ID AS ID, 'RUL > EUL/3. RUL should not be > one third of EUL' as MessageType, 'RUL=' + Convert(varchar,IsNull(RUL,0)) + ',EUL=' + Convert(varchar,IsNull(EUL,0)) AS Detail 
from  MappingMeasurevw e 
where (IsNull(e.rul,0)>IsNull(e.eul,0)/2.75) 




--************** Validate RUL > 0 and UES_ERs are Null  ***************
insert into InputValidation 
select @JobID AS JobID, 'Measure' AS [Table],'Warning High' AS ErrorType, CET_ID, 'RUL > 0 but UES_ERs are zero or Null' AS MessageType, '' AS Detail
from InputMeasure e 
where IsNull(e.RUL,0) > 0 and (e.UESkW_ER  Is Null OR e.UESkWh_ER Is Null)
--***********************************************************************************



--************** Check for blank ClaimYearQuarter values in ProgramCost table  ***************
INSERT INTO InputValidation 
SELECT @JobID AS JobID, 'Program' AS [Table], 'Error' AS ErrorType, PrgID, 'Blank ClaimYearQuarter' AS MessageType, '' AS Detail 
FROM  [dbo].[InputProgramvw] 
WHERE [Year] = '' OR [Year] IS NULL 
--************************************************************



--************** Check for Q in ClaimYearQuarter values in InputMeasure table  ***************
INSERT INTO InputValidation 
SELECT @JobID AS JobID, 'Measure' AS [Table], 'Warning High' AS ErrorType, PrgID, 'No Quarter (Q) in ClaimYearQuarter. Must contain a Q in format YYYYQn where YYYY is year and n is quarter (1-4). For example 2015Q4' AS MessageType, Qtr AS Detail 
FROM  [dbo].[InputMeasurevw] 
WHERE Qtr NOT LIKE '%Q%'
--************************************************************



--************** Validate Validate No Matching Program ID  ***************
INSERT INTO InputValidation
SELECT @JobID AS JobID, 'Program' AS [Table], 'Warning High' AS ErrorType, PrgID AS CET_ID, 'Program ID in measure table with no matching ProgramID in the Program table. No program costs will be included.' AS MessageType, '' AS Detail  
FROM [InputMeasurevw]  m WHERE 
m.[PrgID] NOT IN
(
	SELECT p.PrgID 
	FROM [InputProgramvw] p
	GROUP BY p.PrgID
)
--************************************************************




-- END Validate Input






















GO


