-- EXEC [dbo].[spApp_GetYLOrdPagesTotalData_OPP] @ordID=1235

CREATE PROC [dbo].[spApp_GetYLOrdPagesTotalData_OPP]
	@ordID INT
AS
SET NOCOUNT ON;

;WITH T AS
(
SELECT TOP 10
	@ordID AS ordID
	,N'整单汇总' AS PageName
	,PlateCategory
FROM [dbo].[CUS_YLOrdPlateCategory_OPP]
ORDER BY SortOrder
UNION ALL
SELECT @ordID AS ordID
	,N'整单汇总' AS PageName
	,N'汇总' AS PlateCategory
)
SELECT 
	t.PageName
	,t.PlateCategory
	,CAST(cs.TotalPrice AS FLOAT) AS TotalPrice
FROM T t
LEFT JOIN [dbo].[CUS_YLOrdPagesTotalData_OPP] cs ON t.ordID=cs.OrdID 
	AND t.PageName=cs.PageName
	AND t.PlateCategory=cs.PlateCategory
UNION ALL
SELECT 
	cs.PageName
	,cs.PlateCategory
	,CAST(cs.TotalPrice AS FLOAT) AS TotalPrice
FROM [dbo].[CUS_YLOrdPagesTotalData_OPP] cs
WHERE cs.OrdID=@ordID
	AND NOT EXISTS (SELECT 1 FROM T tt WHERE tt.PageName=cs.PageName)
