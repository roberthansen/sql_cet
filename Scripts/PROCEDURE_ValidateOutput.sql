/*
################################################################################
Name             :  ValidateOutput
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure validates outputs for the job and
				 :  saves to the InputValidation table.
Usage            :  n/a
Called by        :  n/a
Copyright        :  Developed by Pinnacle Consulting Group (aka Intech Energy,
				 :  Inc.) for California Public Utilities Commission (CPUC), All
				 :  Rights Reserved
Change History   :  2016-06-30  Wayne Hauck added comment header
				 :  2024-04-23  Robert Hansen renamed the "PA" field to
				 :  			"IOU_AC_Territory"
################################################################################
*/
USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[ValidateOutput]    Script Date: 2019-12-16 2:12:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateOutput]
@JobID INT = -1
AS

SET NOCOUNT ON

-- Clear InputValidation table for Job
DELETE FROM InputValidation WHERE [Table] = 'Output' and JobID=@JobID


--************** Start Validate Input  ***************


----************** Validate Negative participant cost  ***************
--insert into InputValidation 
--select  @JobID AS JobID, 'Output' AS [Table], 'Warning Low' AS ErrorType, CET_ID AS ID, 'Negative Net Participant Cost' as MessageType , 'NPC= ' + Convert(varchar,e.[NetParticipantCostPV]) as Detail 
--from  dbo.OutputCost e
--where e.[NetParticipantCostPV] < 0
----************************************************************



--************** Validate Savings <> 0 and No Elec Cost Effectiveness  ***************
insert into InputValidation 
select  @JobID AS JobID, 'Output' AS [Table], 'Warning High' AS ErrorType, s.CET_ID AS ID, 'Electric savings but no electric benefits' as MessageType , '' as Detail
from  [dbo].OutputSavings s
LEFT JOIN [dbo].OutputCE ce on s.CET_ID = ce.CET_ID
where s.IOU_AC_Territory <>'SCG' AND (IsNull(s.GrosskWh,0) <> 0   and IsNull(ce.ElecBen,0) = 0)
--***********************************************************************************



--************** Validate Savings <> 0 and No Gas Cost Effectiveness  ***************
insert into InputValidation 
select  @JobID AS JobID, 'Output' AS [Table], 'Warning High' AS ErrorType, s.CET_ID AS ID, 'Gas savings but no gas benefits' as MessageType , '' as Detail
from  [dbo].OutputSavings s
LEFT JOIN [dbo].OutputCE ce on s.CET_ID = ce.CET_ID
where s.IOU_AC_Territory <>'SCE' AND (IsNull(s.GrossThm,0) <> 0   and IsNull(ce.GasBen,0) = 0)



--************** Validate Elec Savings <> 0 and No Electric Emissions  ***************
insert into InputValidation 
select  @JobID AS JobID, 'Output' AS [Table], 'Warning High' AS ErrorType, s.CET_ID AS ID, 'Elec savings but no electric emissions' as MessageType , '' as Detail
from  [dbo].OutputSavings s
LEFT JOIN [dbo].OutputEmissions e on s.CET_ID = e.CET_ID
where e.IOU_AC_Territory <> 'SCG' AND (IsNull(s.GrosskWh,0) <> 0   and IsNull(e.GrossElecCO2,0) = 0)
--***********************************************************************************


--************** Validate Gas Savings <> 0 and No Emissions  ***************
INSERT INTO InputValidation 
SELECT  @JobID AS JobID, 'Output' AS [Table], 'Warning High' AS ErrorType, s.CET_ID AS ID, 'Gas savings but no gas emissions' AS MessageType , '' AS Detail
FROM  [dbo].OutputSavings s
LEFT JOIN [dbo].OutputEmissions e ON s.CET_ID = e.CET_ID
WHERE e.IOU_AC_Territory <> 'SCE' AND (ISNULL(s.GrossThm,0) <> 0   AND ISNULL(e.GrossGasCO2,0) = 0)
--***********************************************************************************



--************** Validate Claim TRC > Std Dev  ***************
INSERT INTO InputValidation 
SELECT  @JobID AS JobID, 'Output' AS [Table], 'Warning Low' AS ErrorType, ce.CET_ID AS ID, 'Claim TRC greater than three standard deviations' AS MessageType , 'Claim TRC=' + CONVERT(VARCHAR,CASE WHEN ISNULL(ce.TRCCost,0)>0 THEN (ISNULL(ce.ElecBen,0) + ISNULL(ce.GasBen,0))/ISNULL(ce.TRCCost,0) ELSE 0 END) AS Detail
FROM  [dbo].OutputCE ce
WHERE CASE WHEN ISNULL(ce.TRCCost,0)>0 THEN (ISNULL(ce.ElecBen,0) + ISNULL(ce.GasBen,0))/ISNULL(ce.TRCCost,0) ELSE 0 END > 
(
	SELECT 3 * STDEV(TRCRatio) + AVG(TRCRatio) FROM [dbo].OutputCE
)



--************** Validate Claim TRC < .10  ***************
INSERT INTO InputValidation 
SELECT  @JobID AS JobID, 'Output' AS [Table], 'Warning Low' AS ErrorType, ce.CET_ID AS ID, 'Very small TRC (< 0.1)' AS MessageType , 'Claim TRC=' + CONVERT(VARCHAR,CASE WHEN ISNULL(ce.TRCCost,0)>0 THEN (ISNULL(ce.ElecBen,0) + ISNULL(ce.GasBen,0))/ISNULL(ce.TRCCost,0) ELSE 0 END) AS Detail
FROM  [dbo].OutputCE ce
WHERE CASE WHEN ISNULL(ce.TRCCost,0)>0 THEN (ISNULL(ce.ElecBen,0) + ISNULL(ce.GasBen,0))/ISNULL(ce.TRCCost,0) ELSE 0 END < 0.1
--***********************************************************************************

-- END Validate Input






















GO


