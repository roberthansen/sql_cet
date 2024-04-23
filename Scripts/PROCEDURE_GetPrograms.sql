USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetPrograms]    Script Date: 2019-12-16 1:46:45 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetPrograms]
         @JobID INT,
		 @PAString NVARCHAR(100) = NULL,
		 @GroupByClause NVARCHAR(50),	
		 @SearchString NVARCHAR(100) 
AS
BEGIN
IF @GroupByClause IS NULL OR @GroupByClause = 'Programs'
SELECT 0 AS ID,
      [IOU_AC_Territory]
      ,[PrgID]
      ,SUM([ElecBen]) ElecBen
      ,SUM([GasBen]) GasBen
      ,SUM([TRCCost]) TRCCost
      ,SUM([PACCost]) PACCost
      ,SUM([TRCCostNoAdmin]) TRCCostNoAdmin
      ,SUM([PACCostNoAdmin]) PACCostNoAdmin
      ,CASE WHEN SUM(ISNULL(TRCCost,0)) > 0 THEN (SUM(ElecBen) + SUM(GasBen))/SUM(TRCCost) ELSE 0 END AS TRCRatio
      ,CASE WHEN SUM(ISNULL(PACCost,0)) > 0 THEN (SUM(ElecBen) + SUM(GasBen))/SUM(PACCost) ELSE 0 END AS PACRatio
      ,CASE WHEN SUM(ISNULL(TRCCostNoAdmin,0)) > 0 THEN (SUM(ElecBen) + SUM(GasBen))/SUM(TRCCostNoAdmin) ELSE 0 END AS TRCRatioNoAdmin
      ,CASE WHEN SUM(ISNULL(PACCostNoAdmin,0)) > 0 THEN (SUM(ElecBen) + SUM(GasBen))/SUM(PACCostNoAdmin) ELSE 0 END AS PACRatioNoAdmin
  FROM [SavedCE]
  WHERE (@PAString IS NULL OR IOU_AC_Territory IN (SELECT val FROM dbo.SplitString(@PAString, ','))) AND PrgID LIKE '%' + @SearchString + '%' AND JobID = @JobID
  GROUP BY IOU_AC_Territory, PrgID 
  ORDER BY IOU_AC_Territory, PrgID
ELSE
SELECT JOBID, jobs.JobDescription + ' (Job ID: ' + CONVERT(NVARCHAR(50), JOBID) + ')' AS JobDescription,
      SUM([ElecBen]) ElecBen
      ,SUM([GasBen]) GasBen
      ,SUM([TRCCost]) TRCCost
      ,SUM([PACCost]) PACCost
      ,SUM([TRCCostNoAdmin]) TRCCostNoAdmin
      ,SUM([PACCostNoAdmin]) PACCostNoAdmin
      ,CASE WHEN SUM(ISNULL(TRCCost,0)) > 0 THEN (SUM(ElecBen) + SUM(GasBen))/SUM(TRCCost) ELSE 0 END AS TRCRatio
      ,CASE WHEN SUM(ISNULL(PACCost,0)) > 0 THEN (SUM(ElecBen) + SUM(GasBen))/SUM(PACCost) ELSE 0 END AS PACRatio
      ,CASE WHEN SUM(ISNULL(TRCCostNoAdmin,0)) > 0 THEN (SUM(ElecBen) + SUM(GasBen))/SUM(TRCCostNoAdmin) ELSE 0 END AS TRCRatioNoAdmin
      ,CASE WHEN SUM(ISNULL(PACCostNoAdmin,0)) > 0 THEN (SUM(ElecBen) + SUM(GasBen))/SUM(PACCostNoAdmin) ELSE 0 END AS PACRatioNoAdmin
  FROM [SavedCE] oce
JOIN [dbo].[CETJobs] jobs
ON oce.jobID = jobs.ID
WHERE (@PAString IS NULL OR IOU_AC_Territory IN (SELECT val FROM dbo.SplitString(@PAString, ','))) AND jobs.JobDescription LIKE '%' + @SearchString + '%'
GROUP BY JOBID, jobs.JobDescription

END

GO