
-- EXEC [dbo].[spApp_GetYLOrdGridColumns_OPP] @ordID=3798915,@ordSource=N'2020'

CREATE PROC [dbo].[spApp_GetYLOrdGridColumns_OPP]
	@ordID INT
	,@ordSource NVARCHAR(50)=NULL
AS
SET NOCOUNT ON;

DECLARE @showPageState INT= 1+8+2;	--1表示公用、2表示2020订单、8表示遗留单（注意2020订单包含遗留单）

IF @ordSource=N'CAD'
BEGIN
	SET @showPageState=1+8+4;	--1表示公用、4表示CAD订单、8表示遗留单（注意CAD订单包含遗留单）
END

SELECT 
	cusG.cmFieldName
	,cusG.cmFieldDesc
	,LOWER(cusG.cmFieldType)AS cmFieldType
	,cusG.cmFieldWidth
	,cusG.cmOriginalField
	,cusG.cmFieldEdit
	,cusG.cmFieldVisible
	,LOWER(cusG.optType) AS optType
	,cusG.optStoredProcedure
	--,cusG.cmOrderSort
	,cusG.pageName
	--,cusP.pageSort
	,(CASE WHEN @ordSource=N'CAD' THEN cusP.PageStoredProcedure_CAD ELSE cusP.PageStoredProcedure END)AS PageStoredProcedure
	,(CASE WHEN cs.PageName IS NULL THEN 0 ELSE 1 END) AS showPageColor
FROM [dbo].[CUS_YLOrdPagesData_OPP] cusP
JOIN [dbo].[CUS_YLOrdGridColumnsData_OPP] cusG ON cusG.PageName=cusP.PageName
LEFT JOIN
(
	SELECT 
		lg.PageName
	FROM dbo.CUS_YLOrdOriginalBOMDataLog_OPP lg
	WHERE lg.ordId=@ordID 
	GROUP BY lg.ordID,lg.PageName
)cs ON cs.PageName=cusP.PageName
WHERE 1=1 
	AND @showPageState&cusP.showPageStates=cusP.showPageStates
	AND @showPageState&cusG.cmStates=cusG.cmStates
ORDER BY cusP.PageSort,cusG.cmOrderSort
