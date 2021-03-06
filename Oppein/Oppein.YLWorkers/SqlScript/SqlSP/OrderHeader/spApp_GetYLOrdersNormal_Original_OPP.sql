CREATE PROC [dbo].[spApp_GetYLOrdersNormal_Original_OPP]
	@ordID INT
	,@pageName NVARCHAR(10)
	,@Factory NVARCHAR(50)
AS
SET NOCOUNT ON;

--DECLARE @ordID INT = 3914472

SELECT 
	org.itmID
	,org.itmIDInstance
	,org.olnID
	,org.olnIDInstance
	,org.itmIDParent
	,org.itmIDParentInstance
	,itm.itmItemNumber
	,CAST(org.oriReqQty AS FLOAT) AS oriReqQty
	,itm.PrimaryUOMCode
	,itm.itmDescription
	,ISNULL(org.itmDescription,itm.itmDescription) AS oItmDescription
	,itmf.itmfCode
	,ISNULL(org.itmfCode,itmf.itmfCode) AS oItmfCode
	,oriMat.TopSurCode AS topSurCode
	,ISNULL(org.topSurCode,oriMat.TopSurCode) AS oTopSurCode
	,oriMat.corCode
	,ISNULL(org.corCode,oriMat.corCode) AS oCorCode
	,CAST(oDim.dimCX AS FLOAT) AS dimCX
	,CAST(ISNULL(org.dimCX,oDim.dimCX) AS FLOAT) AS oDimCX
	,CAST(oDim.dimCY AS FLOAT) AS dimCY
	,CAST(ISNULL(org.dimCY,oDim.dimCY) AS FLOAT) AS oDimCY
	,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
	,CAST(ISNULL(org.dimCZ,oDim.dimCZ) AS FLOAT) AS oDimCZ
	,CAST(oDim.dimFX AS FLOAT) AS dimFX
	,CAST(ISNULL(org.dimFX,oDim.dimFX) AS FLOAT) AS oDimFX
	,CAST(oDim.dimFY AS FLOAT) AS dimFY
	,CAST(ISNULL(org.dimFY,oDim.dimFY) AS FLOAT) AS oDimFY
	,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
	,CAST(ISNULL(org.dimFZ,oDim.dimFZ) AS FLOAT) AS oDimFZ
	,ISNULL(cEdge.edgeCode,N'0000') AS edgeCode
	,COALESCE(org.edgeCode,cEdge.edgeCode,N'0000')AS oEdgeCode
	,org.actions
	,org.pageName
FROM dbo.CUS_mOrdItemOriginalData_OPP org(NOLOCK)
JOIN dbo.Items itm(NOLOCK) ON itm.itmID = org.itmID
JOIN dbo.ItemItemFamilies itmf (NOLOCK) ON itmf.itmID = itm.itmID
JOIN dbo.CUS_mOrdPagesData_OPP pages ON pages.PageName = org.pageName
OUTER APPLY
(
	SELECT 
		MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimX AS DECIMAL(18,2)) END) AS dimFX
		,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimY AS DECIMAL(18,2)) END) AS dimFY
		,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimZ AS DECIMAL(18,2)) END) AS dimFZ
		,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimX AS DECIMAL(18,2)) END) AS dimCX
		,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimY AS DECIMAL(18,2)) END) AS dimCY
		,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimZ AS DECIMAL(18,2)) END) AS dimCZ
	FROM dbo.ItemDimensions dim (NOLOCK)
	WHERE dim.itmID=itm.itmID AND dim.dimID IN(1,3)
)oDim
OUTER APPLY
(  
	Select 
		MAX(Case when orie.orieEdgeNo=4 then IsNull(iatbv.itmavValue,0) end) as Edge1  
		,MAX(Case when orie.orieEdgeNo=2 then IsNull(iatbv.itmavValue,0) end) as Edge2  
		,MAX(Case when orie.orieEdgeNo=3 then IsNull(iatbv.itmavValue,0) end) as Edge3  
		,MAX(Case when orie.orieEdgeNo=1 then IsNull(iatbv.itmavValue,0) end) as Edge4  
	From dbo.OrderItemEdges orie (NOLOCK)  
		JOIN dbo.SurfaceSourceItems ssi (NOLOCK) ON orie.surCode=ssi.surCode  
		JOIN dbo.ItemAttributeValues iatbv (NOLOCK) ON ssi.itmID=iatbv.itmID  
		JOIN dbo.Attributes atb (NOLOCK) ON iatbv.atbID=atb.atbID  
		JOIN dbo.AttributeCategories atbc (NOLOCK) ON atb.atbcID=atbc.atbcID  
	WHERE  org.itmID=orie.itmID 
		AND org.itmIDInstance=orie.itmIDInstance
		AND org.olnID=orie.olnID 
		AND org.olnIDInstance=orie.olnIDInstance  
		AND orie.surCode<>N'No Edge Application'  
		AND atb.atbCode=N'Edge_Thickness_Code' 
		AND atbc.atbcCode=N'Item Info'
) iatb
LEFT JOIN [dbo].[CUS_mOrdItemEdgeCode_OPP] cEdge ON cEdge.edge1=iatb.Edge1
	AND cEdge.edge2=iatb.Edge2
	AND cEdge.edge3=iatb.Edge3
	AND cEdge.edge4=iatb.Edge4
LEFT JOIN dbo.OrderItemMaterials oriMat (NOLOCK) ON oriMat.itmID = org.itmID
	AND oriMat.itmIDInstance = org.itmIDInstance
	AND oriMat.olnID = org.olnID
	AND oriMat.olnIDInstance = org.olnIDInstance
WHERE org.ordId=@ordID 
	AND org.actions > 0
	AND org.pageName NOT IN(N'普通五金')
ORDER BY pages.PageSort